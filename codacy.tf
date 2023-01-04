locals {
  # Helper object containing a few extra fields
  codacy_repo_settings = {
    for k, r in local.repos_with_defaults : k => {
      name                       = r.name
      codacy                     = try(r.codacy, null)
      disable_pull_request_gates = try(r.codacy.pull_request_quality_settings == null, false)
      disable_commit_gates       = try(r.codacy.commit_quality_settings == null, false)
    }
  }

  codacy_pull_request_quality_settings = {
    for k, r in local.codacy_repo_settings : format("%s-pull-requests", k) => {
      name = r.name
      issue_threshold = {
        threshold        = tonumber(try(r.codacy.pull_request_quality_settings.issue_threshold.threshold, r.disable_pull_request_gates ? null : 0))
        minimum_severity = try(r.codacy.pull_request_quality_settings.issue_threshold.minimum_severity, r.disable_pull_request_gates ? null : "Error")
      }
      security_issue_threshold         = 0 # Always block on any security issue
      duplication_threshold            = tonumber(try(r.codacy.pull_request_quality_settings.duplication_threshold, null))
      coverage_threshold_with_decimals = tonumber(try(r.codacy.pull_request_quality_settings.coverage_threshold_with_decimals, null))
      diff_coverage_threshold          = tonumber(try(r.codacy.pull_request_quality_settings.diff_coverage_threshold, null))
      complexity_threshold             = tonumber(try(r.codacy.pull_request_quality_settings.complexity_threshold, null))
      quality_type                     = "pull-requests" # Part of the Codacy v3 endpoint for pull request quality
    }
  }

  codacy_commit_quality_settings = {
    for k, r in local.codacy_repo_settings : format("%s-commits", k) => {
      name = r.name
      issue_threshold = {
        threshold        = tonumber(try(r.codacy.commit_quality_settings.issue_threshold.threshold, r.disable_commit_gates ? null : 0))
        minimum_severity = try(r.codacy.commit_quality_settings.issue_threshold.minimum_severity, r.disable_commit_gates ? null : "Error")
      }
      security_issue_threshold         = 0 # Always block on any security issue
      duplication_threshold            = tonumber(try(r.codacy.commit_quality_settings.duplication_threshold, null))
      coverage_threshold_with_decimals = tonumber(try(r.codacy.commit_quality_settings.coverage_threshold_with_decimals, null))
      diff_coverage_threshold          = tonumber(try(r.codacy.commit_quality_settings.diff_coverage_threshold, null))
      complexity_threshold             = tonumber(try(r.codacy.commit_quality_settings.complexity_threshold, null))
      quality_type                     = "commits" # Part of the Codacy v3 endpoint for commit quality
    }
  }
}

resource "null_resource" "enable_codacy" {
  for_each = { for key, val in local.repos_with_defaults : key => val }

  # Workaround as the destroy provisioner cant reference variables. create is fine, but uses triggers to be consistent.
  # Lifecycle ignore_chanes should then prevent changes to these triggers from destroying and recreating
  triggers = {
    name             = github_repository.racwa_repos[each.key].name
    owner            = var.github_organization
    codacy_api_token = var.codacy_api_token
  }

  provisioner "local-exec" {
    when        = create
    command     = ".'${path.module}\\scripts\\add-repo-to-codacy.ps1' -CODACY_API_TOKEN \"${nonsensitive(self.triggers.codacy_api_token)}\" -RepositoryOwner \"${self.triggers.owner}\" -RepositoryName \"${self.triggers.name}\" "
    interpreter = ["pwsh", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = ".'${path.module}\\scripts\\remove-repo-from-codacy.ps1' -CODACY_API_TOKEN \"${nonsensitive(self.triggers.codacy_api_token)}\" -RepositoryOwner \"${self.triggers.owner}\" -RepositoryName \"${self.triggers.name}\" "
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [github_branch_default.racwa]

  lifecycle {
    ignore_changes = all
  }
}

# Ensures the codacy project token is added. Adding a repo to codacy using the api will not create a project api token. This token
# is used in pipelines/workflows to upload code coverage. The script executed by this resource will create one if none exist
resource "null_resource" "codacy_project_token" {
  for_each   = local.codacy_repo_settings
  depends_on = [null_resource.enable_codacy]

  triggers = {
    name  = each.value.name
    owner = var.github_organization
  }

  provisioner "local-exec" {
    when        = create
    command     = ".'${path.module}\\scripts\\codacy-add-project-token.ps1' -CODACY_API_TOKEN \"${nonsensitive(var.codacy_api_token)}\" -RepositoryOwner \"${self.triggers.owner}\" -RepositoryName \"${self.triggers.name}\" "
    interpreter = ["pwsh", "-Command"]
  }
}

# Both codacy_pull_request_quality_settings and codacy_commit_quality_settings locals are used to create this resource
# For this to function both of those locals transform their key to avoid conflicts
resource "null_resource" "codacy_quality_settings" {
  for_each   = { for key, val in merge(local.codacy_pull_request_quality_settings, local.codacy_commit_quality_settings) : key => val }
  depends_on = [null_resource.enable_codacy]

  triggers = {
    name             = each.value.name
    owner            = var.github_organization
    codacy_api_token = var.codacy_api_token
    # Since we're using powershell we need to use $null instead of null
    # Null is used in the script to discard the associated field which disables its use in Codacy.
    "issue_threshold_threshold"        = coalesce(each.value.issue_threshold.threshold, "$null")
    "issue_threshold_minimum_severity" = coalesce(each.value.issue_threshold.minimum_severity, "$null")
    "security_issue_threshold"         = coalesce(each.value.security_issue_threshold, "$null")
    "duplication_threshold"            = coalesce(each.value.duplication_threshold, "$null")
    "coverage_threshold_with_decimals" = coalesce(each.value.coverage_threshold_with_decimals, "$null")
    "diff_coverage_threshold"          = coalesce(each.value.diff_coverage_threshold, "$null")
    "complexity_threshold"             = coalesce(each.value.complexity_threshold, "$null")
    "quality_type"                     = each.value.quality_type
  }

  provisioner "local-exec" {
    when = create
    command = join(" ", [
      ".'${path.module}\\scripts\\update-codacy-quality-settings.ps1'",
      "-CODACY_API_TOKEN \"${nonsensitive(self.triggers.codacy_api_token)}\"",
      "-RepositoryOwner \"${self.triggers.owner}\"",
      "-RepositoryName \"${self.triggers.name}\"",
      "-issueThresholdThreshold ${self.triggers.issue_threshold_threshold}",
      "-issueThresholdMinimumSeverity ${self.triggers.issue_threshold_minimum_severity}",
      "-securityIssueThreshold ${self.triggers.security_issue_threshold}",
      "-duplicationThreshold ${self.triggers.duplication_threshold}",
      "-coverageThresholdWithDecimals ${self.triggers.coverage_threshold_with_decimals}",
      "-diffCoverageThreshold ${self.triggers.diff_coverage_threshold}",
      "-complexityThreshold ${self.triggers.complexity_threshold}",
      "-QualityType ${self.triggers.quality_type}",
    ])
    interpreter = ["pwsh", "-Command"]
  }

  lifecycle {
    postcondition {
      condition     = contains(["Info", "Warning", "Error", "$null"], self.triggers.issue_threshold_minimum_severity)
      error_message = "Minimum severity must be Info, Warning, Error or null"
    }
    ignore_changes = [
      triggers.codacy_api_token
    ]
  }
}
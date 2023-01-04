locals {

  # I feel like there's a dynamic solution here, but it yields data structures I can't work with
  # repo_files = fileset(path.module, "repos/*.yaml")
  # github_repos = [for filepath in local.repo_files : yamldecode(file(filepath))]
  github_repos = merge(
    yamldecode(file("repos/Test.yaml"))
  )

  # Enforced status checks that must be adopted by branch protection rules
  repo_enforced_status_checks = [
    "Codacy Static Code Analysis"
  ]

  # The default branch protection require_status_checks value that includes the enforced status checks
  repo_default_require_status_checks = {
    strict   = true,
    contexts = local.repo_enforced_status_checks
  }

  # Process defaults for repos defined in yaml files
  yaml_repos_with_defaults = { for k, r in local.github_repos : k => {
    name                    = k
    description             = try(r.description, "")
    visibility              = try(r.visibility, "internal")
    has_issues              = try(r.has_issues, false)
    has_projects            = try(r.has_projects, false)
    has_wiki                = try(r.has_wiki, false)
    is_template             = try(r.is_template, false)
    allow_merge_commit      = try(r.allow_merge_commit, true)
    allow_squash_merge      = try(r.allow_squash_merge, true)
    allow_rebase_merge      = try(r.allow_rebase_merge, true)
    delete_branch_on_merge  = try(r.delete_branch_on_merge, true)
    has_downloads           = try(r.has_downloads, false)
    auto_init               = try(r.auto_init, true)
    archived                = try(r.archived, false)
    archive_on_destroy      = try(r.archive_on_destroy, true)
    vulnerability_alerts    = try(r.vulnerability_alerts, true)
    default_branch          = try(r.default_branch, "master")
    disable_default_write   = try(r.disable_default_write, false)
    create_app_registration = try(r.create_app_registration, false)
    enabled                 = try(r.enabled, true)
    template                = try(r.template, null)
    teams                   = try(r.teams, null)
    deploy_keys             = try(r.deploy_keys, [])
    topics                  = try(r.topics, [])
    gitignore_template      = try(r.gitignore_template, null)
    homepage_url            = try(r.homepage_url, null)
    permission              = try(r.permission, "push")
    #disable_codacy_check    = try(r.disable_codacy_check, false)
    enforce_codacy_check = try(r.enforce_codacy_check, true)
    codacy               = try(r.codacy, null) # See codacy.tf for more info



    include_branch_name_protection_action = try(r.include_branch_name_protection_action, false)

    #branch_protection = try([for policy_key, policy in concat(r.branch_protection, (contains(r.branch_protection.*.pattern, try(r.default_branch, "master")) ? [] : [{}])) : {

    branch_protection = try([for policy_key, policy in r.branch_protection : {
      pattern                = try(policy.pattern, try(r.default_branch, "master"))
      enforce_admins         = try(policy.enforce_admins, true)
      require_signed_commits = try(policy.require_signed_commits, false)
      require_pull_request_reviews = {
        dismiss_stale_reviews           = try(policy.require_pull_request_reviews.dismiss_stale_reviews, true)
        require_code_owner_reviews      = try(policy.require_pull_request_reviews.require_code_owner_reviews, true)
        required_approving_review_count = try(policy.require_pull_request_reviews.required_approving_review_count, 2)
      }
      allows_deletions                = try(policy.allows_deletions, false)
      allows_force_pushes             = try(policy.allows_force_pushes, false)
      require_conversation_resolution = try(policy.require_conversation_resolution, false)

      require_status_checks = try(
        {
          strict = policy.require_status_checks.strict
          # disable_codacy_check here may be undefined
          contexts = distinct(concat(policy.require_status_checks.contexts, (try(r.disable_codacy_check == true, false) ? [] : local.repo_enforced_status_checks)))
        },
        (try(r.disable_codacy_check == true, false) ? null : local.repo_enforced_status_checks)
      )
      }],
      [{
        pattern                = try(r.default_branch, "master")
        enforce_admins         = true
        require_signed_commits = false
        require_pull_request_reviews = {
          dismiss_stale_reviews           = true
          require_code_owner_reviews      = true
          required_approving_review_count = 2
        }
        allows_deletions                = false
        allows_force_pushes             = false
        require_conversation_resolution = false
        require_status_checks           = try(r.disable_codacy_check, false) ? null : local.repo_enforced_status_checks
    }])

    codeowner = try(r.codeowner, {
      create = false
      approvers = {} }
    ) }
    if try(r.enabled, true) != false
  }

  protection_policies = flatten([
    for repo_key, repo in local.repos_with_defaults :
    [
      for protection_key, protection in repo.branch_protection :
      {
        repo_key          = repo_key
        branch_protection = protection
      }
    ]
  ])

  # Process legacy repo definitions still defined in repos-config.tfvars file
  tfvars_repos_with_defaults = { for r in var.repos : r.name => r }

  # Combine legacy + yaml repos
  repos_with_defaults = merge(
    local.yaml_repos_with_defaults
  )

  teams_with_defaults = { for t in var.teams : t.name => t }

  # group repo approvals on the pattern
  repo_approvals = {
    for r in local.repos_with_defaults : r.name => {
      for a in r.codeowner.approvers : a.pattern => a...
    }
    if r.codeowner.create
  }

  repo_branch_name_protection_actions = toset([
    for r in local.repos_with_defaults : r.name
    if r.include_branch_name_protection_action
  ])

  repo_deploy_keys = flatten([
    for r in local.repos_with_defaults : [
      for deploy_key in r.deploy_keys : {
        title      = deploy_key.title
        repository = r.name
        key        = deploy_key.key
        read_only  = deploy_key.read_only
      }
    ]
  ])

  repo_teams_access = flatten([
    for r in local.repos_with_defaults : [
      for team_name, access in coalesce(r.teams, {}) : {
        repo_name = r.name
        team_name = team_name
        access    = access
      }
    ]
  ])

  teams_ad_groups = flatten([
    for t in local.teams_with_defaults : [
      for group in t.ad_groups : {
        team        = t.name
        group       = group.name
        description = group.description
      }
    ]
  ])

  all_ad_groups = tomap({ for g in distinct(concat([for t in local.teams_ad_groups : t.group], ["Github Admin"])) : g => g })
}

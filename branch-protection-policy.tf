resource "github_branch_protection" "default" {
  for_each = { for policy in local.protection_policies : "${policy.repo_key}.${try(policy.branch_protection.pattern, "main")}" => policy }

  repository_id = github_repository.racwa_repos[each.value.repo_key].id

  pattern                         = each.value.branch_protection.pattern
  require_signed_commits          = each.value.branch_protection.require_signed_commits
  enforce_admins                  = each.value.branch_protection.enforce_admins
  allows_deletions                = each.value.branch_protection.allows_deletions
  allows_force_pushes             = each.value.branch_protection.allows_force_pushes
  require_conversation_resolution = each.value.branch_protection.require_conversation_resolution

  required_pull_request_reviews {
    dismiss_stale_reviews           = each.value.branch_protection.require_pull_request_reviews.dismiss_stale_reviews
    require_code_owner_reviews      = each.value.branch_protection.require_pull_request_reviews.require_code_owner_reviews
    required_approving_review_count = each.value.branch_protection.require_pull_request_reviews.required_approving_review_count
  }

  dynamic "required_status_checks" {
    for_each = try(each.value.branch_protection.require_status_checks, null) != null ? [each.value.branch_protection.require_status_checks] : []

    content {
      strict   = try(required_status_checks.value["strict"], false)
      contexts = try(required_status_checks.value["contexts"], [])
    }
  }

  depends_on = [
    github_repository_file.codeowner
  ]
}

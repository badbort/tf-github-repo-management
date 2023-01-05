locals {
  template_repo = { for r in data.github_repository.templates : r.name => { owner = var.github_organization, repository = r.name } } #Parse owner from repo full name
}

resource "github_repository" "racwa_repos" {
  for_each = local.repos_with_defaults

  name                   = each.value.name
  description            = each.value.description
  homepage_url           = each.value.homepage_url
  visibility             = each.value.visibility
  has_issues             = each.value.has_issues
  has_projects           = each.value.has_projects
  has_wiki               = each.value.has_wiki
  is_template            = each.value.is_template
  allow_merge_commit     = each.value.allow_merge_commit
  allow_squash_merge     = each.value.allow_squash_merge
  allow_rebase_merge     = each.value.allow_rebase_merge
  allow_auto_merge       = each.value.allow_auto_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge
  has_downloads          = each.value.has_downloads
  auto_init              = each.value.auto_init
  gitignore_template     = each.value.gitignore_template
  archived               = each.value.archived
  archive_on_destroy     = each.value.archive_on_destroy
  topics                 = each.value.topics
  vulnerability_alerts   = each.value.vulnerability_alerts

  dynamic "template" {
    for_each = lookup(local.template_repo, coalesce(each.value.template, "xyz"), null)[*]
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }

  lifecycle {
    ignore_changes = [vulnerability_alerts, etag, branches]
  }
}

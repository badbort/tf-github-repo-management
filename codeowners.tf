resource "github_repository_file" "codeowner" {
  for_each = local.repo_approvals

  repository = each.key
  branch     = local.repos_with_defaults[each.key].default_branch
  file       = "CODEOWNERS"
  content = join("\n", concat(
    [for patternType, approvers in each.value :
      join("\n", concat(
        [for approverInfo in approvers : "# ${approverInfo.comment} - (${approverInfo.approver})"],
        [join("\t", concat(
          ["${patternType}"],
          [for approverInfo in approvers : "@${var.github_organization}/${github_team.teams[approverInfo.approver].slug}"]
        ))],
        ["CODEOWNERS\t@${var.github_organization}/${github_team.teams["Maintainers"].slug}"]
      ))
    ]
  ))

  commit_message      = "Default approvals"
  commit_author       = "Automated"
  commit_email        = "github@ractest.com.au"
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [
      content,
      commit_message,
      commit_author,
      commit_email
    ]
  }

  depends_on = [
    github_branch_default.racwa
  ]
}

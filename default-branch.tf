# This null_resources ensures the default branch exists before github_branch_default uses it. It creates the branch using the 
# GitHub API instead of using a github_branch resource. This is intended as the resource approach will delete the branch when
# default branch changes, which will delete all content.
# The script involved does the following:
# - If branch already exists, do nothing
# - If branch doesn't exist, create the new branch which points to the same commit on HEAD
resource "null_resource" "github_branch_create" {
  for_each = { for name, r in local.repos_with_defaults : r.name => r if r.auto_init && r.default_branch != "main"}

  triggers = {
    branch = each.value.default_branch
  }

  provisioner "local-exec" {
    when = create
    command     = ".'${path.module}\\scripts\\create-default-branch.ps1' -GITHUB_TOKEN \"${var.github_token}\" -BranchName \"${self.triggers.branch}\" -RepositoryOwner \"${var.github_organization}\" -RepositoryName \"${self.triggers.name}\" "
    environment = {
      GITHUB_TOKEN = var.github_token
     }
  }

  depends_on = [
    github_repository.racwa_repos[each.key].name
  ]
}

resource "github_branch_default" "racwa" {
  for_each = { for name, r in local.repos_with_defaults : r.name => r if r.auto_init }

  repository = github_repository.racwa_repos[each.key].name
  branch     = each.value.default_branch
  depends_on = [
    github_branch.racwa
  ]
}
resource "github_team_repository" "team_access" {
  for_each = {
    for team_access in local.repo_teams_access : "${team_access.repo_name}.${team_access.team_name}" => team_access
  }

  team_id    = github_team.teams[each.value.team_name].id
  repository = github_repository.racwa_repos[each.value.repo_name].name
  permission = each.value.access

  lifecycle {
    ignore_changes = [
      etag
    ]
  }
}

resource "github_team_repository" "admin_access" {
  for_each = local.repos_with_defaults

  team_id    = github_team.teams["Admin2"].id
  repository = github_repository.racwa_repos[each.key].name
  permission = "admin"

  lifecycle {
    ignore_changes = [
      etag
    ]
  }
}

resource "github_team_repository" "default_access" {
  for_each = local.repos_with_defaults

  team_id    = github_team.teams["Default Access2"].id
  repository = github_repository.racwa_repos[each.key].name
  permission = "push"

  lifecycle {
    ignore_changes = [
      etag
    ]
  }
}

resource "github_team_repository" "maintainers_access" {
  for_each = local.repos_with_defaults

  team_id    = github_team.teams["Maintainers2"].id
  repository = github_repository.racwa_repos[each.key].name
  permission = "push"

  lifecycle {
    ignore_changes = [
      etag
    ]
  }
}

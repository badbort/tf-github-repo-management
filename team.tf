locals {
  adminteam = {
    name                      = "Admin-TfTest"
    description               = "Admin Users"
    privacy                   = "closed"
    create_default_maintainer = false
  }
  maintainersteam = {
    name                      = "Maintainers-TfTest"
    description               = "Oversees creation of new repos and other maintenance tasks within GitHub."
    privacy                   = "closed"
    create_default_maintainer = false
  }
  defaultteam = {
    name                      = "Default Access-TfTest"
    description               = "All Users"
    privacy                   = "closed"
    create_default_maintainer = false
  }
}

resource "github_team" "teams" {
  for_each = merge(local.teams_with_defaults, { "Admin-TfTest" = local.adminteam }, { "Maintainers-TfTest" = local.maintainersteam }, { "Default Access-TfTest" = local.defaultteam })

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
  #parent_team                 = optional(string)
  create_default_maintainer = each.value.create_default_maintainer

  lifecycle {
    ignore_changes = [
      create_default_maintainer,
      etag,
      members_count
    ]
  }
}

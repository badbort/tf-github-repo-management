locals {
  adminteam = {
    name                      = "Admin2"
    description               = "Admin Users"
    privacy                   = "closed"
    create_default_maintainer = false
  }
  maintainersteam = {
    name                      = "Maintainers2"
    description               = "Oversees creation of new repos and other maintenance tasks within GitHub."
    privacy                   = "closed"
    create_default_maintainer = false
  }
  defaultteam = {
    name                      = "Default Access2"
    description               = "All Users"
    privacy                   = "closed"
    create_default_maintainer = false
  }
}

resource "github_team" "teams" {
  for_each = merge(local.teams_with_defaults, { "Admin2" = local.adminteam }, { "Maintainers2" = local.maintainersteam }, { "Default Access2" = local.defaultteam })

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

variable "github_token" {
  type = string
}

variable "github_organization" {
  type    = string
  default = "bortington"
}

variable "codacy_api_token" {
  type        = string
  sensitive   = true
  description = "Account API token for the Codacy API"
}


variable "repos" {
  default = []
  type = list(object({
    enabled                 = optional(bool, true)
    name                    = string
    description             = optional(string, "")
    homepage_url            = optional(string, "")
    visibility              = optional(string, "internal")
    has_issues              = optional(bool, false)
    has_projects            = optional(bool, false)
    has_wiki                = optional(bool, false)
    is_template             = optional(bool, false)
    allow_merge_commit      = optional(bool, true)
    allow_squash_merge      = optional(bool, true)
    allow_rebase_merge      = optional(bool, true)
    delete_branch_on_merge  = optional(bool, true)
    has_downloads           = optional(bool, false)
    auto_init               = optional(bool, true)
    gitignore_template      = optional(string)
    archived                = optional(bool, false)
    archive_on_destroy      = optional(bool, true)
    topics                  = list(string)
    template                = optional(string)
    vulnerability_alerts    = optional(bool, true)
    create_app_registration = optional(bool, false)

    default_branch = optional(string, "main")
    deploy_keys = optional(list(object({
      title     = string
      key       = string
      read_only = string
    })))
    disable_default_write = optional(bool, false)

    codeowner = object({
      create = bool
      approvers = list(object({
        priority = number
        approver = string
        pattern  = string
        comment  = string
      }))
    })

    branch_protection = list(object({
      pattern                         = optional(string, "main")
      enforce_admins                  = optional(bool, true)
      require_signed_commits          = optional(bool, false)
      allows_deletions                = optional(bool, false)
      allows_force_pushes             = optional(bool, false)
      require_status_checks           = optional(object({}))
      require_conversation_resolution = optional(bool, false)
      #push_restrictions                   = list(string)

      require_pull_request_reviews = object({
        dismiss_stale_reviews           = optional(bool, true)
        require_code_owner_reviews      = optional(bool, true)
        required_approving_review_count = optional(number, 2)
        #dismissal_restrictions            = list(string)
      })
    }))

    teams = map(string)
  }))

  validation {
    condition     = alltrue([for r in var.repos : lookup(r, "disable_default_write", false) == false || length(r.teams) > 0])
    error_message = "Repo contributors - requires the default write role or teams specified for write access."
  }

  validation {
    condition     = alltrue([for r in var.repos : alltrue([for a in r.codeowner.approvers : contains(concat(keys(r.teams), ["Admin"]), a.approver)])])
    error_message = "Repo codeowners - requires all codeowners to be specifically assigned access on the repo."
  }
}

variable "teams" {
  type = list(object({
    enabled                   = optional(bool, true)
    name                      = string
    description               = string
    privacy                   = optional(string, "closed")
    parent_team               = optional(string)
    create_default_maintainer = optional(bool, false)
    ad_groups = list(object({
      name        = string
      description = string
    }))
  }))
}

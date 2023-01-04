terraform {
  backend "azurerm" {
    container_name       = "tf-github-repo-management"
    key                  = "tf-github-repo-management.tfstate"
    resource_group_name  = "rg-common"
    storage_account_name = "badbortcommontfstatesta"
    subscription_id      = "bd8e250a-66a6-4038-acd8-0d6aced3e3c8" # Badbort personal
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.29.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.25.0"
    }
    github = {
      source  = "integrations/github",
      version = "4.26.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
  }
  required_version = "~> 1.3.0"
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "azuread" {}

provider "github" {
  token = var.github_token
  owner = var.github_organization
}

provider "time" {}

data "github_repository" "templates" {
  for_each = { for name, r in local.repos_with_defaults : r.name => r if r.template != null && r.template != "" }
  name     = each.value.template
}

data "azuread_client_config" "current" {}

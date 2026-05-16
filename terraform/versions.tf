terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    # All values supplied via -backend-config in CI to keep this file repo-agnostic.
    # See bootstrap.sh for the resource_group_name / storage_account_name / container_name.
    key = "divyakatha.tfstate"
  }
}

provider "azurerm" {
  # The CI service principal isn't allowed to register subscription-level resource
  # providers. We register the specific ones we need manually (see bootstrap.sh).
  resource_provider_registrations = "none"

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

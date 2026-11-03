terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "1.11.0"
    }
  }
  backend "azurerm" {}
}
provider "azurerm" {
  features {}
  use_oidc        = true
  subscription_id = var.subscription_id
}

provider "fabric" {
  # Configuration options
  #tenant_id =
  use_oidc                            = true
  use_workspace_private_link_endpoint = true
}
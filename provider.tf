terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name   = "resourceTerraform"
    storage_account_name  = "terrstorageacc"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }

  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

/* resource "azurerm_resource_group" "main" {
  name     = var.resourceGroup
  location = var.location
} */
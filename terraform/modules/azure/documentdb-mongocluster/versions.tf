terraform {
  required_version = ">= 1.2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

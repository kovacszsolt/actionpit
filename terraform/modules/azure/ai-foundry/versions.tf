terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Cognitive Account Projects (optional) require a recent provider; AIServices + project_management need 4.x.
      version = ">= 4.55.0"
    }
  }
}

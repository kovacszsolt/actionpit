# Azure User Assigned Managed Identity resource
# Managed identity that can be assigned to Azure resources (e.g., Container Apps)
# Used for authentication to other Azure services (e.g., Key Vault) without storing credentials
resource "azurerm_user_assigned_identity" "main" {
  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

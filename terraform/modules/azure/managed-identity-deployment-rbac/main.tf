# Grants a managed identity (principal_id) permission to:
# - push images to an existing Azure Container Registry (AcrPush)
# - deploy/update resources in a resource group (Contributor), e.g. Container Apps
#
# Pair with user-assigned-identity module + optional Entra federated credential for GitHub Actions OIDC.

data "azurerm_container_registry" "target" {
  name                = var.registry_name
  resource_group_name = var.registry_resource_group_name
}

resource "azurerm_role_assignment" "resource_group_contributor" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = data.azurerm_container_registry.target.id
  role_definition_name = "AcrPush"
  principal_id         = var.principal_id
}

data "azurerm_container_registry" "target" {
  name                = var.registry_name
  resource_group_name = var.registry_resource_group_name
}

resource "azurerm_role_assignment" "registry" {
  scope                = data.azurerm_container_registry.target.id
  role_definition_name = var.role_definition_name
  principal_id         = var.principal_id
}

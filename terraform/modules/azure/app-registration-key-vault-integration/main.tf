data "azurerm_client_config" "current" {}

resource "azuread_application" "this" {
  display_name = var.display_name
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "azuread_application_password" "this" {
  application_id = azuread_application.this.id
  display_name   = var.client_password_display_name
}

resource "azurerm_key_vault_access_policy" "this" {
  count = var.grant_mode == "access_policy" ? 1 : 0

  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.this.object_id

  secret_permissions = var.access_policy_secret_permissions
}

resource "azurerm_role_assignment" "this" {
  count = var.grant_mode == "rbac" ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = var.rbac_role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}

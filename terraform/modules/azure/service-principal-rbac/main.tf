data "azurerm_client_config" "current" {}

locals {
  rbac_scope = coalesce(
    var.scope,
    "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  )
  additional_scopes = [
    for rg in var.additional_resource_group_names :
    "/subscriptions/${var.subscription_id}/resourceGroups/${rg}"
    if rg != var.resource_group_name
  ]
  rbac_scopes = concat([local.rbac_scope], local.additional_scopes)
  additional_role_assignments = {
    for pair in setproduct(var.additional_role_definition_names, local.rbac_scopes) :
    "${pair[0]}|${pair[1]}" => {
      role  = pair[0]
      scope = pair[1]
    }
  }
}

resource "azuread_application" "this" {
  display_name = var.display_name
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "azuread_application_password" "this" {
  application_id = azuread_application.this.id
  display_name   = "terraform"
}

resource "azurerm_role_assignment" "this" {
  scope                = local.rbac_scope
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}

resource "azurerm_role_assignment" "additional" {
  for_each             = toset(local.additional_scopes)
  scope                = each.value
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}

resource "azurerm_role_assignment" "additional_roles" {
  for_each             = local.additional_role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_service_principal.this.object_id
}

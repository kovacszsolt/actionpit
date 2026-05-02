resource "azurerm_container_registry" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  public_network_access_enabled = var.public_network_access_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled

  # Network Rule Bypass Options
  network_rule_bypass_option = var.network_rule_bypass_option

  # Retention Policy (Premium SKU only)
  # azurerm v4 uses the attribute `retention_policy_in_days` (not a nested block).
  retention_policy_in_days = (
    var.sku == "Premium" && var.retention_policy != null && var.retention_policy.enabled
  ) ? var.retention_policy.days : null

  # Trust Policy (Premium SKU only)
  # azurerm v4 uses the attribute `trust_policy_enabled` (not a nested block).
  trust_policy_enabled = (
    var.sku == "Premium" && var.trust_policy != null
  ) ? var.trust_policy.enabled : null

  # Managed Identity (User Assigned)
  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }

  # Encryption
  # Note: If encryption block is provided, encryption is enabled
  # If not provided, encryption is disabled (default)
  dynamic "encryption" {
    for_each = var.encryption != null && var.encryption.key_vault_key_id != null ? [var.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  # Export Policy (Premium SKU only)
  # Only set if Premium SKU, otherwise Terraform will use default
  export_policy_enabled = var.sku == "Premium" ? var.export_policy_enabled : true

  # Quarantine Policy (Premium SKU only)
  # Only set if Premium SKU, otherwise Terraform will use default
  quarantine_policy_enabled = var.sku == "Premium" ? var.quarantine_policy_enabled : false

  # Note: soft_delete_policy and azuread_authentication_as_arm_policy are not yet supported
  # by the standard Terraform azurerm provider. These would need to be configured via
  # Azure CLI or AzAPI provider if required.

  tags = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_pull_principal_id != null ? 1 : 0

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.acr_pull_principal_id
}

resource "azurerm_role_assignment" "custom" {
  for_each = { for i, ra in var.role_assignments : i => ra }

  scope        = azurerm_container_registry.main.id
  principal_id = each.value.principal_id

  role_definition_name = each.value.role_definition_name
  role_definition_id   = each.value.role_definition_id
}

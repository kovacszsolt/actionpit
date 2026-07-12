data "azurerm_client_config" "current" {}

locals {
  resolved_tenant_id = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id

  # Admins: explicit object IDs + optionally the principal running Terraform (interactive user or CI service principal).
  admin_principal_object_ids = distinct(concat(
    var.user_object_ids,
    var.include_terraform_client_in_admin_policies ? [data.azurerm_client_config.current.object_id] : []
  ))

  admin_access_policies = [
    for object_id in local.admin_principal_object_ids : {
      tenant_id = local.resolved_tenant_id
      object_id = object_id
      certificate_permissions = [
        "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
        "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers",
        "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"
      ]
      key_permissions = [
        "Get", "List", "Update", "Create", "Import", "Delete", "Recover",
        "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate",
        "Encrypt", "Decrypt", "UnwrapKey", "WrapKey", "Verify", "Sign",
        "Purge", "Release"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
      ]
    }
  ]

  external_secrets_access_policy = var.external_secrets_object_id != "" ? [{
    tenant_id               = local.resolved_tenant_id
    object_id               = var.external_secrets_object_id
    certificate_permissions = []
    key_permissions         = []
    secret_permissions      = ["Get", "List", "Set", "Delete"]
  }] : []

  user_identity_access_policy = var.user_identity_object_id != "" ? [{
    tenant_id               = local.resolved_tenant_id
    object_id               = var.user_identity_object_id
    certificate_permissions = []
    key_permissions         = []
    secret_permissions      = ["Get"]
  }] : []

  access_policies = concat(
    local.admin_access_policies,
    local.external_secrets_access_policy,
    local.user_identity_access_policy
  )
}

# Azure Key Vault resource
# Secure storage for secrets, keys, and certificates
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = local.resolved_tenant_id

  sku_name = "standard"

  # Network ACLs - controls network access to the Key Vault
  # bypass: "None" means Azure services cannot bypass network rules
  # default_action: "Allow" allows all traffic by default (restrict with ip_rules/subnet_ids)
  network_acls {
    bypass                     = "None"
    default_action             = "Allow"
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = var.virtual_network_subnet_ids
  }

  # Access policies - only used if RBAC is not enabled
  # If enable_rbac_authorization = true, then access_policy blocks will conflict
  # Use RBAC roles (e.g., "Key Vault Secrets User") instead when RBAC is enabled
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? {} : { for idx, p in local.access_policies : tostring(idx) => p }
    content {
      tenant_id = access_policy.value.tenant_id
      object_id = access_policy.value.object_id

      certificate_permissions = access_policy.value.certificate_permissions
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
    }
  }

  # Enable Key Vault for Azure Virtual Machine deployments
  enabled_for_deployment = var.enabled_for_deployment
  # Enable Key Vault for Azure Disk Encryption
  enabled_for_disk_encryption = var.enabled_for_disk_encryption
  # Enable Key Vault for Azure Resource Manager template deployments
  enabled_for_template_deployment = var.enabled_for_template_deployment

  # Use RBAC for authorization instead of access policies
  # (renamed in azurerm provider; old name deprecated)
  rbac_authorization_enabled = var.enable_rbac_authorization

  # Soft delete: deleted items are retained for the specified number of days
  soft_delete_retention_days = var.soft_delete_retention_days
  # Purge protection: prevents permanent deletion even after soft delete retention period
  purge_protection_enabled = var.purge_protection_enabled

  # Public network access: allow/disallow public internet access
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags
}

resource "azurerm_key_vault_secret" "main" {
  for_each = var.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
}
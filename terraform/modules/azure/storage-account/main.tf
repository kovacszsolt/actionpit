resource "azurerm_storage_account" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  # Only applicable for StorageV2/BlobStorage
  access_tier = var.access_tier

  https_traffic_only_enabled      = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  public_network_access_enabled   = var.public_network_access_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public

  is_hns_enabled = var.is_hns_enabled

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

resource "azurerm_storage_share" "shares" {
  for_each = var.file_shares

  name               = each.key
  storage_account_id = azurerm_storage_account.main.id
  quota              = each.value.quota_gb
  enabled_protocol   = each.value.enabled_protocol
}

resource "azurerm_storage_container" "blobs" {
  for_each = var.blob_containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = each.value.container_access_type
}


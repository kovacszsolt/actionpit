# Random password when none is provided (stored in state and output)
resource "random_password" "pg_admin" {
  count = var.administrator_password == null ? 1 : 0

  length           = var.password_length
  special          = true
  override_special = var.password_override_special
}

locals {
  administrator_password = coalesce(var.administrator_password, try(random_password.pg_admin[0].result, null))
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  version  = var.postgres_version
  sku_name = var.sku_name

  storage_mb        = var.storage_mb
  storage_tier      = var.storage_tier
  auto_grow_enabled = var.auto_grow_enabled

  administrator_login    = var.administrator_login
  administrator_password = local.administrator_password

  authentication {
    password_auth_enabled         = var.password_auth_enabled
    active_directory_auth_enabled = var.active_directory_auth_enabled
    tenant_id                     = var.active_directory_auth_enabled ? var.tenant_id : null
  }

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  public_network_access_enabled = var.public_network_access_enabled

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  dynamic "high_availability" {
    for_each = var.high_availability != null ? [var.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  zone = var.zone

  tags = var.tags

  lifecycle {
    precondition {
      condition = (
        (var.delegated_subnet_id == null && var.private_dns_zone_id == null) ||
        (var.delegated_subnet_id != null && var.private_dns_zone_id != null)
      )
      error_message = "delegated_subnet_id and private_dns_zone_id must both be set for VNet integration, or both null."
    }
    precondition {
      condition     = (var.delegated_subnet_id == null) || !var.public_network_access_enabled
      error_message = "public_network_access_enabled must be false when using VNet integration (delegated subnet)."
    }
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "rules" {
  for_each = var.public_network_access_enabled ? var.firewall_rules : {}

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Allow extensions on the server (required before CREATE EXTENSION in a database)
resource "azurerm_postgresql_flexible_server_configuration" "azure_extensions" {
  count = length(var.allowed_extensions) > 0 ? 1 : 0

  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = join(",", var.allowed_extensions)
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  count = var.max_connections != null ? 1 : 0

  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = tostring(var.max_connections)
}

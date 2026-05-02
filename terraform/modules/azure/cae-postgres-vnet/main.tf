resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "cae" {
  name                 = var.cae_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.cae_subnet_address_prefixes

  delegation {
    name = "cae"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "postgresql" {
  name                 = var.postgresql_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.postgresql_subnet_address_prefixes

  delegation {
    name = "postgresql"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Optional: non-delegated subnet for jump / bastion VM (SSH tunnel to private PostgreSQL).
resource "azurerm_subnet" "jump" {
  count = length(var.jump_subnet_address_prefixes) > 0 ? 1 : 0

  name                 = var.jump_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.jump_subnet_address_prefixes

  lifecycle {
    precondition {
      condition     = var.jump_subnet_name != ""
      error_message = "jump_subnet_name must be set when jump_subnet_address_prefixes is non-empty."
    }
  }
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = var.private_dns_zone_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = var.tags
}

# Azure DocumentDB Mongo Clusters (Cosmos DB for MongoDB vCore) - matches Bicep Microsoft.DocumentDB/mongoClusters@2025-04-01-preview
data "azapi_client_config" "current" {}

resource "azapi_resource" "mongo_cluster" {
  type      = "Microsoft.DocumentDB/mongoClusters@2025-04-01-preview"
  name      = var.name
  location  = var.location
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = {
    properties = {
      administrator = {
        userName = var.administrator_login
        password = var.administrator_password
      }
      serverVersion = var.server_version
      compute = {
        tier = var.compute_tier
      }
      storage = {
        sizeGb = var.storage_size_gb
        type   = var.storage_type
      }
      sharding = {
        shardCount = var.shard_count
      }
      highAvailability = {
        targetMode = var.high_availability_mode
      }
      backup              = var.backup
      publicNetworkAccess = var.public_network_access
      dataApi = {
        mode = var.data_api_mode
      }
      authConfig = {
        allowedModes = var.auth_allowed_modes
      }
      createMode = var.create_mode
    }
  }

  lifecycle {
    ignore_changes = [
      body.properties.administrator.password
    ]
  }

  tags = var.tags
}

# Firewall rules (child of cluster)
resource "azapi_resource" "firewall_rule" {
  for_each = var.firewall_rules

  type      = "Microsoft.DocumentDB/mongoClusters/firewallRules@2025-04-01-preview"
  name      = each.key
  parent_id = azapi_resource.mongo_cluster.id

  body = {
    properties = {
      startIpAddress = each.value.start_ip_address
      endIpAddress   = each.value.end_ip_address
    }
  }
}

# Users (child of cluster) - additional MongoDB users for RBAC. Skip administrator_login as Azure creates it with the cluster.
resource "azapi_resource" "user" {
  for_each = toset([for u in var.users : u if u != var.administrator_login])

  type      = "Microsoft.DocumentDB/mongoClusters/users@2025-04-01-preview"
  name      = each.value
  parent_id = azapi_resource.mongo_cluster.id

  body = {
    properties = {}
  }
}

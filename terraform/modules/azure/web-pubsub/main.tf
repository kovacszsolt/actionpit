locals {
  # Free_F1 allows only 1; omitting capacity can make plans flaky across provider versions.
  capacity = coalesce(var.capacity, 1)
}

resource "azurerm_web_pubsub" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku      = var.sku
  capacity = local.capacity

  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled
  aad_auth_enabled              = var.aad_auth_enabled
  tls_client_cert_enabled       = var.tls_client_cert_enabled

  tags = var.tags

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.identity_type != "UserAssigned" ||
        length(var.identity_ids) > 0
      )
      error_message = "When identity_type is UserAssigned, set non-empty identity_ids."
    }
  }
}

resource "azurerm_web_pubsub_hub" "hub" {
  for_each      = toset(var.hubs)
  name          = each.key
  web_pubsub_id = azurerm_web_pubsub.main.id

  depends_on = [azurerm_web_pubsub.main]
}

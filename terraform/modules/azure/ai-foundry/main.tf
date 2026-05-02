locals {
  project_tags = var.project_tags != null ? var.project_tags : var.tags

  diagnostic_setting_name = coalesce(var.diagnostic_setting_name, "${var.name}-diagnostics")
}

resource "azurerm_cognitive_account" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  kind                       = "AIServices"
  sku_name                   = var.sku_name
  project_management_enabled = var.project_management_enabled
  custom_subdomain_name      = var.custom_subdomain_name

  identity {
    type = var.identity_type
    identity_ids = (
      var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned"
    ) ? var.identity_ids : null
  }

  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition = !var.create_project || (
        var.project_management_enabled &&
        var.custom_subdomain_name != null &&
        contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
      )
      error_message = "Foundry project requires project_management_enabled = true, custom_subdomain_name set, and a managed identity on the Cognitive account."
    }
    precondition {
      condition     = !var.create_project || var.project_name != null
      error_message = "project_name is required when create_project is true."
    }
  }
}

resource "azurerm_cognitive_account_project" "main" {
  count = var.create_project ? 1 : 0

  name                 = var.project_name
  cognitive_account_id = azurerm_cognitive_account.main.id
  location             = var.location

  display_name = var.project_display_name
  description  = var.project_description

  identity {
    type = var.project_identity_type
    identity_ids = (
      var.project_identity_type == "UserAssigned" || var.project_identity_type == "SystemAssigned, UserAssigned"
    ) ? var.project_identity_ids : null
  }

  tags = local.project_tags
}

# Microsoft.CognitiveServices/accounts — https://learn.microsoft.com/azure/azure-monitor/reference/supported-logs/microsoft-cognitiveservices-accounts-logs
resource "azurerm_monitor_diagnostic_setting" "cognitive" {
  count = var.diagnostic_log_analytics_workspace_id != null ? 1 : 0

  name                       = local.diagnostic_setting_name
  target_resource_id         = azurerm_cognitive_account.main.id
  log_analytics_workspace_id = var.diagnostic_log_analytics_workspace_id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "AzureOpenAIRequestUsage"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Trace"
  }

  dynamic "enabled_metric" {
    for_each = var.diagnostic_send_platform_metrics ? [1] : []
    content {
      category = "AllMetrics"
    }
  }
}

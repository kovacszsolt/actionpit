data "azurerm_log_analytics_workspace" "by_name" {
  count = var.log_analytics_workspace_id == null && var.log_analytics_workspace_name != null ? 1 : 0

  name                = var.log_analytics_workspace_name
  resource_group_name = coalesce(var.log_analytics_workspace_resource_group_name, var.resource_group_name)
}

locals {
  log_analytics_workspace_id = coalesce(
    var.log_analytics_workspace_id,
    try(data.azurerm_log_analytics_workspace.by_name[0].id, null)
  )
}

# Azure Container App Environment resource
# This is the hosting environment for Container Apps
# All Container Apps in this environment share the same networking and logging configuration
resource "azurerm_container_app_environment" "main" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  # azurerm >= 5.0 requires logs_destination when log_analytics_workspace_id is set
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = local.log_analytics_workspace_id

  lifecycle {
    precondition {
      condition     = local.log_analytics_workspace_id != null
      error_message = "Set log_analytics_workspace_id or log_analytics_workspace_name (and ensure the workspace exists)."
    }
  }

  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.user_assigned_identity_id]
    }
  }

  # VNet configuration - only set if infrastructure_subnet_id is provided
  # When set, the environment will be integrated with the specified subnet
  # This enables private networking and VNet integration features
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.infrastructure_subnet_id != null ? var.internal_load_balancer_enabled : null

  tags = var.tags
}

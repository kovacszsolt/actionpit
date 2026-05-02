# Azure Log Analytics Workspace resource
# Centralized logging and monitoring workspace
# Used by Container App Environments for application logs and metrics
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  # SKU: pricing tier (PerGB2018 is pay-as-you-go based on data ingested)
  sku = var.sku
  # Retention: how long to keep log data (30-730 days)
  retention_in_days = var.retention_in_days

  tags = var.tags
}

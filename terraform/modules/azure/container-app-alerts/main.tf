# CPU % high
resource "azurerm_monitor_metric_alert" "cpu" {
  count               = var.cpu_threshold != null ? 1 : 0
  name                = "${var.name_prefix}-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = var.scopes
  severity            = var.severity
  frequency           = var.evaluation_frequency
  window_size         = var.window_size
  description         = "Alert when CPU % is above ${var.cpu_threshold}"

  dynamic "action" {
    for_each = var.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  criteria {
    metric_namespace = "Microsoft.App/containerapps"
    metric_name      = "CpuPercentage"
    aggregation      = var.cpu_aggregation
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold
  }

  tags = var.tags
}

# Memory % high
resource "azurerm_monitor_metric_alert" "memory" {
  count               = var.memory_threshold != null ? 1 : 0
  name                = "${var.name_prefix}-memory-high"
  resource_group_name = var.resource_group_name
  scopes              = var.scopes
  severity            = var.severity
  frequency           = var.evaluation_frequency
  window_size         = var.window_size
  description         = "Alert when Memory % is above ${var.memory_threshold}"

  dynamic "action" {
    for_each = var.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  criteria {
    metric_namespace = "Microsoft.App/containerapps"
    metric_name      = "MemoryPercentage"
    aggregation      = var.memory_aggregation
    operator         = "GreaterThan"
    threshold        = var.memory_threshold
  }

  tags = var.tags
}

# Replica count greater than threshold
resource "azurerm_monitor_metric_alert" "replica_count" {
  count               = var.replica_count_threshold != null ? 1 : 0
  name                = "${var.name_prefix}-replicas-high"
  resource_group_name = var.resource_group_name
  scopes              = var.scopes
  severity            = var.severity
  frequency           = var.evaluation_frequency
  window_size         = var.window_size
  description         = "Alert when replica count is greater than ${var.replica_count_threshold}"

  dynamic "action" {
    for_each = var.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  criteria {
    metric_namespace = "Microsoft.App/containerapps"
    metric_name      = "Replicas"
    aggregation      = var.replica_aggregation
    operator         = "GreaterThan"
    threshold        = var.replica_count_threshold
  }

  tags = var.tags
}

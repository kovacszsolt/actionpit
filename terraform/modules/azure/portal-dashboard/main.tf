# For each container app: one row with CPU+Memory %, Requests (max), and Log table.
# MonitorChartPart + LogsDashboardPart (portal-native format).
locals {
  app_list = [for i, app in var.container_apps : {
    index       = i
    resource_id = app.resource_id
    # coalesce so app_name is never null (try() does not substitute null in Terraform)
    app_name = coalesce(
      try(app.display_name, null),
      try(element(split("/", app.resource_id), (length(split("/", app.resource_id)) - 1)), null),
      "container-app"
    )
  }]
  workspace_name = try(element(split("/", var.log_analytics_workspace_id), (length(split("/", var.log_analytics_workspace_id)) - 1)), "Logs")
}

locals {
  # Panel 0 per app: CPU + Memory %
  cpu_mem_parts = {
    for i, app in local.app_list : tostring(i * 3 + 0) => {
      position = { x = 0, y = i * 4, colSpan = 6, rowSpan = 4 }
      metadata = {
        inputs = [
          { name = "options", isOptional = true },
          { name = "sharedTimeRange", isOptional = true }
        ]
        type = "Extension/HubsExtension/PartType/MonitorChartPart"
        settings = {
          content = {
            options = {
              chart = {
                metrics = [
                  {
                    resourceMetadata = { id = app.resource_id }
                    name             = "CpuPercentage"
                    aggregationType  = 3
                    namespace        = "microsoft.app/containerapps"
                    metricVisualization = {
                      displayName         = "CPU Usage Percentage (Preview)"
                      resourceDisplayName = app.app_name
                    }
                  },
                  {
                    resourceMetadata = { id = app.resource_id }
                    name             = "MemoryPercentage"
                    aggregationType  = 3
                    namespace        = "microsoft.app/containerapps"
                    metricVisualization = {
                      displayName         = "Memory Percentage (Preview)"
                      resourceDisplayName = app.app_name
                    }
                  }
                ]
                title     = "${app.app_name} CPU and Memory (Max)"
                titleKind = 2
                visualization = {
                  chartType           = 2
                  legendVisualization = { isVisible = true, position = 2, hideHoverCard = false, hideLabelNames = true }
                  axisVisualization   = { x = { isVisible = true, axisType = 2 }, y = { isVisible = true, axisType = 1 } }
                  disablePinning      = true
                }
              }
            }
          }
        }
      }
    }
  }

  # Panel 1 per app: Requests (max)
  requests_parts = {
    for i, app in local.app_list : tostring(i * 3 + 1) => {
      position = { x = 6, y = i * 4, colSpan = 6, rowSpan = 4 }
      metadata = {
        inputs = [
          { name = "options", isOptional = true },
          { name = "sharedTimeRange", isOptional = true }
        ]
        type = "Extension/HubsExtension/PartType/MonitorChartPart"
        settings = {
          content = {
            options = {
              chart = {
                metrics = [
                  {
                    resourceMetadata = { id = app.resource_id }
                    name             = "Requests"
                    aggregationType  = 4
                    namespace        = "microsoft.app/containerapps"
                    metricVisualization = {
                      displayName         = "Requests"
                      resourceDisplayName = app.app_name
                    }
                  }
                ]
                title     = "${app.app_name} Max Requests"
                titleKind = 2
                visualization = {
                  chartType           = 2
                  legendVisualization = { isVisible = true, position = 2, hideHoverCard = false, hideLabelNames = true }
                  axisVisualization   = { x = { isVisible = true, axisType = 2 }, y = { isVisible = true, axisType = 1 } }
                  disablePinning      = true
                }
              }
            }
          }
        }
      }
    }
  }

  # Panel 2 per app: Log table (ContainerAppConsoleLogs_CL)
  logs_parts = {
    for i, app in local.app_list : tostring(i * 3 + 2) => {
      position = { x = 12, y = i * 4, colSpan = 10, rowSpan = 4 }
      metadata = {
        inputs = [
          { name = "resourceTypeMode", isOptional = true },
          { name = "ComponentId", isOptional = true },
          { name = "Scope", value = { resourceIds = [var.log_analytics_workspace_id] }, isOptional = true },
          { name = "PartId", value = "logs-${replace(app.app_name, "_", "-")}-${i}", isOptional = true },
          { name = "Version", value = "2.0", isOptional = true },
          { name = "TimeRange", value = "P1D", isOptional = true },
          { name = "DashboardId", isOptional = true },
          { name = "DraftRequestParameters", isOptional = true },
          { name = "Query", value = "ContainerAppConsoleLogs_CL\n| where ContainerAppName_s in (```${app.app_name}```)", isOptional = true },
          { name = "ControlType", value = "AnalyticsGrid", isOptional = true },
          { name = "SpecificChart", isOptional = true },
          { name = "PartTitle", value = "Analytics", isOptional = true },
          { name = "PartSubTitle", value = local.workspace_name, isOptional = true },
          { name = "Dimensions", isOptional = true },
          { name = "LegendOptions", isOptional = true },
          { name = "IsQueryContainTimeRange", value = false, isOptional = true }
        ]
        type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
        settings = {
          content = {
            GridColumnsWidth = { "Log_s" = "800px" }
            Query            = "ContainerAppConsoleLogs_CL\n| where ContainerAppName_s in (```${app.app_name}```)\n| project time_t, Log_s\n| order by time_t desc\n\n"
            PartTitle        = app.app_name
            PartSubTitle     = "Logs"
          }
        }
      }
    }
  }

  part_objects = merge(local.cpu_mem_parts, local.requests_parts, local.logs_parts)

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = local.part_objects
      }
    }
    metadata = {
      model = {
        timeRange = {
          value = {
            relative = { duration = var.default_time_range_hours, timeUnit = 1 }
          }
          type = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  })
}

resource "azurerm_portal_dashboard" "main" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  location             = var.location
  dashboard_properties = local.dashboard_properties
  tags = merge(var.tags, {
    "hidden-title" = var.display_name
  })
}

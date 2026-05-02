variable "name" {
  description = "Unique name for the dashboard resource (e.g. dhb-gde-dev-dpa-overview)."
  type        = string
}

variable "display_name" {
  description = "Display name shown in the Azure Portal (e.g. DPA Overview)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the dashboard will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the dashboard as ARM location name (e.g. westeurope)."
  type        = string
}

variable "container_apps" {
  description = "List of container apps; each row gets CPU+Memory, Requests, and Logs panels. display_name defaults to the last segment of resource_id."
  type = list(object({
    resource_id  = string
    display_name = optional(string)
  }))
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for the log tables (e.g. ws-gde-dpa-dev)."
  type        = string
}

variable "default_time_range_hours" {
  description = "Default dashboard time range in hours (e.g. 72 for past 3 days)."
  type        = number
  default     = 72
}

variable "tags" {
  description = "Tags to apply to the dashboard."
  type        = map(string)
  default     = {}
}

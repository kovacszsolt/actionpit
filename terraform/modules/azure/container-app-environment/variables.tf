variable "environment_name" {
  description = "Name of the Container App Environment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region as ARM location name (lowercase, no spaces), e.g. westeurope."
  type        = string
  default     = "westeurope"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID. If null, log_analytics_workspace_name is used with a data source."
  type        = string
  default     = null
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name (used when log_analytics_workspace_id is null)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_resource_group_name" {
  description = "Resource group of the Log Analytics workspace (defaults to resource_group_name)"
  type        = string
  default     = null
}

variable "user_assigned_identity_id" {
  description = "User Assigned Managed Identity ID to attach to the Container App Environment (optional)"
  type        = string
  default     = null
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for VNet integration (optional)"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Internal-only ingress (VNet). When false with a subnet, apps still use external ingress but environment is in the VNet for outbound/private traffic."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

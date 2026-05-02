variable "name" {
  description = "Cognitive Services account name (Azure AI Foundry uses kind AIServices). Globally unique among Cognitive Services accounts."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku_name" {
  description = "SKU for the Cognitive Services account (e.g. S0)."
  type        = string
  default     = "S0"
}

variable "custom_subdomain_name" {
  description = "Subdomain for Entra ID / standard Azure AI endpoints. Required if you create a Foundry project or use private endpoints."
  type        = string
  default     = null
}

variable "project_management_enabled" {
  description = "Enable Foundry project management on the account (kind AIServices). Cannot be turned off once enabled."
  type        = bool
  default     = true
}

variable "local_auth_enabled" {
  description = "Whether API keys (local auth) are enabled on the account."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the account is reachable from public networks."
  type        = bool
  default     = true
}

variable "identity_type" {
  description = "Managed identity type for the Cognitive account."
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "User-assigned identity resource IDs when identity_type is UserAssigned or SystemAssigned, UserAssigned."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_project" {
  description = "Create an azurerm_cognitive_account_project (Foundry project). Requires custom_subdomain_name, project_management_enabled, and managed identity on the account."
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Foundry project resource name (required when create_project is true)."
  type        = string
  default     = null
}

variable "project_display_name" {
  type    = string
  default = null
}

variable "project_description" {
  type    = string
  default = null
}

variable "project_tags" {
  description = "Tags for the Foundry project only; defaults to var.tags when null."
  type        = map(string)
  default     = null
}

variable "project_identity_type" {
  description = "Managed identity type for the Foundry project."
  type        = string
  default     = "SystemAssigned"
}

variable "project_identity_ids" {
  type    = list(string)
  default = []
}

variable "diagnostic_log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for Monitor diagnostic settings. If null, diagnostics are not configured."
  type        = string
  default     = null
}

variable "diagnostic_setting_name" {
  description = "Name of the azurerm_monitor_diagnostic_setting resource. Defaults to \"{cognitive account name}-diagnostics\"."
  type        = string
  default     = null
}

variable "diagnostic_send_platform_metrics" {
  description = "Send platform metrics (AllMetrics) to the same workspace alongside resource logs."
  type        = bool
  default     = true
}

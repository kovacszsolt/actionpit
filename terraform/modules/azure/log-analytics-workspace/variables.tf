variable "workspace_name" {
  description = "Name of the Log Analytics Workspace"
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

variable "sku" {
  description = "Workspace SKU type (PerGB2018, Free, PerNode, Premium, Standard, Standalone, CapacityReservation)"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days (30-730, or null for default retention)"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_in_days == null || (var.retention_in_days >= 30 && var.retention_in_days <= 730)
    error_message = "The retention_in_days value must be between 30-730, or null."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name of the Static Web App"
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

variable "sku_tier" {
  description = "SKU tier (Free or Standard)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be Free or Standard."
  }
}

variable "sku_size" {
  description = "SKU size (Free or Standard)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_size)
    error_message = "sku_size must be Free or Standard."
  }
}

variable "preview_environments_enabled" {
  description = "Enable staging/preview environments"
  type        = bool
  default     = true
}

variable "configuration_file_changes_enabled" {
  description = "Allow config file updates (e.g. staticwebapp.config.json)"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "basic_auth_password" {
  description = "Password for basic auth (optional). When set, basic auth is enabled."
  type        = string
  default     = null
  sensitive   = true
}

variable "basic_auth_environments" {
  description = "Environments where basic auth applies: AllEnvironments or StagingEnvironments"
  type        = string
  default     = "StagingEnvironments"
  validation {
    condition     = contains(["AllEnvironments", "StagingEnvironments"], var.basic_auth_environments)
    error_message = "basic_auth_environments must be AllEnvironments or StagingEnvironments."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

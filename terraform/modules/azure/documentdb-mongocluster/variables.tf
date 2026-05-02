variable "name" {
  description = "Name of the DocumentDB Mongo cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the cluster is created."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. westeurope)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the cluster."
  type        = map(string)
  default     = {}
}

# Administrator (required at create; password not returned by API)
variable "administrator_login" {
  description = "Mongo cluster administrator username."
  type        = string
}

variable "administrator_password" {
  description = "Mongo cluster administrator password (write-only; not returned by API). Must be 8–256 characters and contain at least 3 of: lowercase, uppercase, numeric, symbolic."
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.administrator_password) >= 8 &&
      length(var.administrator_password) <= 256 &&
      (
        (length(regexall("[a-z]", var.administrator_password)) > 0 ? 1 : 0) +
        (length(regexall("[A-Z]", var.administrator_password)) > 0 ? 1 : 0) +
        (length(regexall("[0-9]", var.administrator_password)) > 0 ? 1 : 0) +
        (length(regexall("[^a-zA-Z0-9]", var.administrator_password)) > 0 ? 1 : 0)
      ) >= 3
    )
    error_message = "Password must be 8–256 characters and contain at least 3 of: lowercase, uppercase, numeric, symbolic (Azure DocumentDB policy)."
  }
}

# Cluster configuration (matches Bicep properties)
variable "server_version" {
  description = "MongoDB server version (e.g. 7.0, 8.0)."
  type        = string
  default     = "7.0"
}

variable "compute_tier" {
  description = "Compute tier (e.g. M10, M25)."
  type        = string
  default     = "M25"
}

variable "storage_size_gb" {
  description = "Storage size in GB."
  type        = number
  default     = 32
}

variable "storage_type" {
  description = "Storage type (e.g. PremiumSSD)."
  type        = string
  default     = "PremiumSSD"
}

variable "shard_count" {
  description = "Number of shards."
  type        = number
  default     = 1
}

variable "high_availability_mode" {
  description = "High availability target mode (e.g. Disabled, SameZone, MultiZone)."
  type        = string
  default     = "Disabled"
}

variable "backup" {
  description = "Backup configuration object (e.g. {} for default)."
  type        = any
  default     = {}
}

variable "public_network_access" {
  description = "Public network access (Enabled or Disabled)."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be Enabled or Disabled."
  }
}

variable "data_api_mode" {
  description = "Data API mode (e.g. Disabled)."
  type        = string
  default     = "Disabled"
}

variable "auth_allowed_modes" {
  description = "Allowed auth modes (e.g. [NativeAuth])."
  type        = list(string)
  default     = ["NativeAuth"]
}

variable "create_mode" {
  description = "Create mode (Default or Restore)."
  type        = string
  default     = "Default"
}

# Firewall rules: map of rule name -> { start_ip_address, end_ip_address }
variable "firewall_rules" {
  description = "Map of firewall rule names to { start_ip_address, end_ip_address }. Use same IP for both for a single host."
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

# Users to create (Mongo cluster users, e.g. admin username for RBAC)
variable "users" {
  description = "List of MongoDB user names to create (e.g. [administrator_login] for the admin user)."
  type        = list(string)
  default     = []
}

variable "name" {
  description = "The name of the PostgreSQL Flexible Server. Must be globally unique."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the server."
  type        = string
}

variable "location" {
  description = "The Azure region where the server should be created."
  type        = string
}

variable "postgres_version" {
  description = "The version of PostgreSQL. Possible values: 11, 12, 13, 14, 15, 16."
  type        = string
  default     = "16"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.postgres_version)
    error_message = "postgres_version must be one of: 11, 12, 13, 14, 15, 16."
  }
}

variable "sku_name" {
  description = "The SKU name (e.g. B_Standard_B1ms, GP_Standard_D2s_v3)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Max storage allowed in MB. Possible values include 32768, 65536, 131072, 262144, 524288, 1048576, etc."
  type        = number
  default     = 32768
}

variable "storage_tier" {
  description = "Storage performance tier (e.g. P4, P6, P10, P30). Default depends on storage_mb."
  type        = string
  default     = null
}

variable "auto_grow_enabled" {
  description = "Whether storage auto-grow is enabled."
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = "The administrator login for the PostgreSQL server."
  type        = string
}

variable "administrator_password" {
  description = "The administrator password. If null, a random password is generated and stored in state (and output)."
  type        = string
  default     = null
  sensitive   = true
}

variable "password_auth_enabled" {
  description = "Whether password authentication is allowed."
  type        = bool
  default     = true
}

variable "active_directory_auth_enabled" {
  description = "Whether Azure Active Directory authentication is allowed."
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "Azure AD tenant ID; required when active_directory_auth_enabled is true."
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Backup retention in days (7 to 35)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Whether geo-redundant backup is enabled."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled. Must be false when using delegated_subnet_id + private_dns_zone_id (VNet integration)."
  type        = bool
  default     = true
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID (Microsoft.DBforPostgreSQL/flexibleServers). Set together with private_dns_zone_id for private-only access."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID (privatelink.postgres.database.azure.com) for VNet-integrated Flexible Server."
  type        = string
  default     = null
}

variable "high_availability" {
  description = "Optional high_availability block: { mode = \"SameZone\"|\"ZoneRedundant\", standby_availability_zone = optional }."
  type = object({
    mode                      = string
    standby_availability_zone = optional(string)
  })
  default = null
}

variable "maintenance_window" {
  description = "Optional maintenance_window block: { day_of_week = 0-6, start_hour = 0-23, start_minute = 0-59 }."
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}

variable "zone" {
  description = "Availability zone (e.g. 1, 2, 3)."
  type        = string
  default     = null
}

variable "allowed_extensions" {
  description = "List of extension names to allow on the server (azure.extensions). E.g. CITEXT, UUID-OSSP, PG_TRGM. After allowing, run CREATE EXTENSION in each database."
  type        = list(string)
  default     = []
}

variable "max_connections" {
  description = "If set, configures the server parameter max_connections (azurerm_postgresql_flexible_server_configuration). Must fit Azure limits for the chosen SKU."
  type        = number
  default     = null
}

variable "password_override_special" {
  description = "Override the special characters used in the password. Default is !#$%&*()-_=+[]{}<>:?"
  type        = string
  default     = "!#$%&*()-_=+[]{}<>:?"
}

variable "password_length" {
  description = "Length of the password. Default is 32."
  type        = number
  default     = 32
}

variable "tags" {
  description = "Tags to assign to the server."
  type        = map(string)
  default     = {}
}

variable "firewall_rules" {
  description = "Firewall rules: name => { start_ip_address, end_ip_address }. Use 0.0.0.0 for both to allow other Azure services in the region (typical for Container Apps -> Postgres over public endpoint)."
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

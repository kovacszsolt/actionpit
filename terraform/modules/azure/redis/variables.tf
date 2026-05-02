variable "name" {
  description = "The name of the Redis cache. Must be globally unique (3–63 characters, alphanumeric and hyphens only)."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Redis cache."
  type        = string
}

variable "location" {
  description = "The Azure region where the Redis cache should be created."
  type        = string
}

variable "capacity" {
  description = "The size of the Redis cache. For Basic/Standard (family C): 0–6. For Premium (family P): 1–5."
  type        = number

  validation {
    condition     = var.capacity >= 0 && var.capacity <= 6
    error_message = "capacity must be between 0 and 6 for Basic/Standard; for Premium use 1–5 and set family to P."
  }
}

variable "family" {
  description = "The SKU family: C (Basic/Standard) or P (Premium)."
  type        = string
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "family must be C or P."
  }
}

variable "sku_name" {
  description = "The SKU type: Basic, Standard, or Premium."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium."
  }
}

variable "enable_non_ssl_port" {
  description = "Enable the non-SSL port (6379). Not recommended for production."
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version: 1.0, 1.1, or 1.2."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be 1.0, 1.1, or 1.2."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "The ID of the subnet to deploy the Redis cache into (Premium SKU for VNet injection)."
  type        = string
  default     = null
}

variable "private_static_ip_address" {
  description = "Static IP address when using subnet_id. Must be in the subnet range."
  type        = string
  default     = null
}

variable "redis_configuration" {
  description = "Optional Redis configuration block: maxmemory_policy, maxmemory_reserved, maxmemory_delta, etc."
  type = object({
    maxmemory_policy                = optional(string)
    maxmemory_reserved              = optional(number)
    maxmemory_delta                 = optional(number)
    maxfragmentationmemory_reserved = optional(number)
    rdb_backup_enabled              = optional(bool)
    rdb_backup_frequency            = optional(number)
    rdb_backup_max_snapshot_count   = optional(number)
    rdb_storage_connection_string   = optional(string)
    aof_backup_enabled              = optional(bool)
    aof_storage_connection_string_0 = optional(string)
    aof_storage_connection_string_1 = optional(string)
  })
  default = null
}

variable "patch_schedule" {
  description = "Optional list of patch schedule blocks: day_of_week, start_hour_utc."
  type = list(object({
    day_of_week    = string
    start_hour_utc = optional(number)
  }))
  default = []
}

variable "replicas_per_primary" {
  description = "Number of replicas per primary (Premium SKU only)."
  type        = number
  default     = null
}

variable "tags" {
  description = "Tags to assign to the Redis cache."
  type        = map(string)
  default     = {}
}

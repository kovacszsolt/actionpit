variable "name" {
  description = "Service Bus namespace name (6–50 chars, alphanumeric and hyphens; globally unique)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{6,50}$", var.name))
    error_message = "Namespace name must be 6–50 characters: letters, digits, hyphens only."
  }
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "Namespace SKU: Basic, Standard, or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Messaging units for Premium (1, 2, 4, 8, 16). For Basic/Standard use 0 or null."
  type        = number
  default     = null
}

variable "premium_messaging_partitions" {
  description = "Premium only: partition count (0, 1, 2, 4). Immutable after create in many cases."
  type        = number
  default     = null
}

variable "local_auth_enabled" {
  description = "Allow SAS / connection string authentication."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the namespace."
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for client connections."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be 1.0, 1.1, or 1.2."
  }
}

variable "tags" {
  description = "Tags for the namespace."
  type        = map(string)
  default     = {}
}

variable "queues" {
  description = "Queues to create in the namespace (name => options)."
  type = map(object({
    max_delivery_count                   = optional(number)
    lock_duration                        = optional(string)
    dead_lettering_on_message_expiration = optional(bool)
    requires_session                     = optional(bool)
    requires_duplicate_detection         = optional(bool)
    partitioning_enabled                 = optional(bool)
    max_size_in_megabytes                = optional(number)
  }))
  default = {}
}

variable "topics" {
  description = "Topics to create; each may define subscriptions (name => topic options)."
  type = map(object({
    partitioning_enabled         = optional(bool)
    requires_duplicate_detection = optional(bool)
    max_size_in_megabytes        = optional(number)
    subscriptions = optional(map(object({
      max_delivery_count                   = optional(number)
      dead_lettering_on_message_expiration = optional(bool)
      batched_operations_enabled           = optional(bool)
    })), {})
  }))
  default = {}
}

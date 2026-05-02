variable "name" {
  description = "The name of the Storage Account. Must be globally unique (3-24 chars, lowercase letters and numbers only)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must match ^[a-z0-9]{3,24}$."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Storage Account."
  type        = string
}

variable "location" {
  description = "The Azure location where the Storage Account should be created."
  type        = string
}

variable "account_tier" {
  description = "The performance tier of the Storage Account. Possible values: Standard, Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be one of: Standard, Premium."
  }
}

variable "account_replication_type" {
  description = "The replication type of the Storage Account. Common values: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "The kind of the Storage Account. Typical value is StorageV2."
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "The access tier for BlobStorage/StorageV2 accounts. Possible values: Hot, Cool. Set to null to let Azure decide."
  type        = string
  default     = "Hot"

  validation {
    condition     = var.access_tier == null || contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be one of: Hot, Cool (or null)."
  }
}

variable "enable_https_traffic_only" {
  description = "Whether HTTPS traffic is required."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "The minimum supported TLS version. Typical values: TLS1_0, TLS1_1, TLS1_2."
  type        = string
  default     = "TLS1_2"
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled."
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Whether nested items (e.g., blobs) can be public."
  type        = bool
  default     = false
}

variable "is_hns_enabled" {
  description = "Whether hierarchical namespace is enabled (required for Data Lake Gen2)."
  type        = bool
  default     = false
}

variable "network_rules" {
  description = "Optional network rules block for the Storage Account."
  type = object({
    default_action             = string
    bypass                     = list(string)
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "file_shares" {
  description = "Azure File Shares to create in this storage account."
  type = map(object({
    quota_gb         = number
    enabled_protocol = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for share in values(var.file_shares) :
      contains(["SMB", "NFS"], share.enabled_protocol)
    ])
    error_message = "Each file share enabled_protocol must be SMB or NFS."
  }
}

variable "blob_containers" {
  description = "Blob containers to create (container name => settings)."
  type = map(object({
    container_access_type = optional(string, "private")
  }))
  default = {}

  validation {
    condition = alltrue([
      for c in values(var.blob_containers) :
      contains(["private", "blob", "container"], c.container_access_type)
    ])
    error_message = "Each blob container_access_type must be private, blob, or container."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}


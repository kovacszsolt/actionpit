variable "name" {
  description = "Name of this storage binding on the Container Apps Environment (referenced as storage_name from container app volumes)."
  type        = string
}

variable "container_app_environment_id" {
  description = "ID of the Container App Environment."
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage account name (Azure Files)."
  type        = string
}

variable "storage_account_access_key" {
  description = "Storage account access key for the file share."
  type        = string
  sensitive   = true
}

variable "file_share_name" {
  description = "Azure Files share name."
  type        = string
}

variable "access_mode" {
  description = "ReadOnly or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

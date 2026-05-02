variable "name" {
  description = "Web PubSub resource name (globally unique in Azure)."
  type        = string
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
  description = "SKU: Free_F1, Standard_S1, Premium_P1, Premium_P2."
  type        = string
  default     = "Free_F1"
}

variable "capacity" {
  description = "Unit count (SKU-dependent; Free_F1 allows 1). Omit to let Azure default."
  type        = number
  default     = null
  nullable    = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the service."
  type        = bool
  default     = true
}

variable "local_auth_enabled" {
  description = "Enable access key (connection string) authentication for service calls."
  type        = bool
  default     = true
}

variable "aad_auth_enabled" {
  description = "Enable Microsoft Entra ID authentication."
  type        = bool
  default     = true
}

variable "tls_client_cert_enabled" {
  description = "Request client certificate during TLS handshake."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}

variable "hubs" {
  description = "Hub names to create (no event handlers; suitable for server-only publish / client subscribe patterns)."
  type        = list(string)
  default     = []
}

variable "identity_type" {
  description = "Managed identity: null (none), SystemAssigned, or UserAssigned."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type must be null, SystemAssigned, or UserAssigned."
  }
}

variable "identity_ids" {
  description = "User-assigned identity resource IDs (required when identity_type is UserAssigned)."
  type        = list(string)
  default     = []
}

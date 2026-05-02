variable "name" {
  description = "The name of the Container Registry. Must be globally unique."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Container Registry."
  type        = string
}

variable "location" {
  description = "The Azure location where the Container Registry should be created."
  type        = string
}

variable "sku" {
  description = "The SKU name of the Container Registry. Possible values are Basic, Standard and Premium."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The sku must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry."
  type        = bool
  default     = true
}

variable "anonymous_pull_enabled" {
  description = "Whether allows anonymous (unauthenticated) pull access to this Container Registry."
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Whether to enable dedicated data endpoints for this Container Registry."
  type        = bool
  default     = false
}

variable "network_rule_bypass_option" {
  description = "Whether to allow trusted Azure services to access a network restricted Container Registry. Possible values are None and AzureServices."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["None", "AzureServices"], var.network_rule_bypass_option)
    error_message = "The network_rule_bypass_option must be one of: None, AzureServices."
  }
}

variable "user_assigned_identity_ids" {
  description = "Set of User Assigned Managed Identity resource IDs to attach to the Container Registry. When non-empty, ACR will use type = \"UserAssigned\"."
  type        = set(string)
  default     = []
}

variable "acr_pull_principal_id" {
  description = "Principal ID (object id) that should be granted AcrPull on this Container Registry (e.g., the Container App Environment's user-assigned identity principal_id). Deprecated: prefer role_assignments."
  type        = string
  default     = null
}

variable "role_assignments" {
  description = "List of IAM role assignments on the Container Registry. Each entry needs principal_id and either role_definition_name (e.g. AcrPull, AcrPush, AcrDelete) or role_definition_id."
  type = list(object({
    principal_id         = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for ra in var.role_assignments :
      (ra.role_definition_name != null) != (ra.role_definition_id != null)
    ])
    error_message = "Each role_assignment must have exactly one of role_definition_name or role_definition_id set."
  }
}

variable "retention_policy" {
  description = "A retention_policy block for the Container Registry."
  type = object({
    days    = number
    enabled = bool
  })
  default = null
}

variable "trust_policy" {
  description = "A trust_policy block for the Container Registry."
  type = object({
    enabled = bool
  })
  default = null
}

variable "encryption" {
  description = "An encryption block for the Container Registry. If provided, encryption is enabled."
  type = object({
    key_vault_key_id   = string
    identity_client_id = string
  })
  default = null
}

variable "export_policy_enabled" {
  description = "Whether export policy is enabled for the Container Registry."
  type        = bool
  default     = true
}

variable "quarantine_policy_enabled" {
  description = "Whether quarantine policy is enabled for the Container Registry."
  type        = bool
  default     = false
}

# Note: soft_delete_policy and azuread_authentication_as_arm_policy are not yet supported
# by the standard Terraform azurerm provider. These would need to be configured via
# Azure CLI or AzAPI provider if required.

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

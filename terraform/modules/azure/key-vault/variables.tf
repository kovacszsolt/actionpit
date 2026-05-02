variable "key_vault_name" {
  description = "Name of the Key Vault. Must be 3-24 characters, only alphanumeric and hyphens allowed."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters long and contain only alphanumeric characters and hyphens."
  }
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

variable "tenant_id" {
  description = "Azure AD tenant ID. If null or empty, the tenant of the Terraform identity is used."
  type        = string
  default     = null
  nullable    = true
}

variable "user_object_ids" {
  description = "Array of user object IDs for admin access policies"
  type        = list(string)
  default     = []
}

variable "include_terraform_client_in_admin_policies" {
  description = "If true, adds data.azurerm_client_config.current.object_id to admin access policies (your user when using az login, or the pipeline service principal)."
  type        = bool
  default     = true
}

variable "user_identity_object_id" {
  description = "User Assigned Managed Identity object ID"
  type        = string
  default     = ""
}

variable "external_secrets_object_id" {
  description = "Azure AD object ID of the service principal used by an external secrets manager (e.g. Doppler, HashiCorp Vault) to sync secrets into Key Vault. If empty, no access policy is created for this principal."
  type        = string
  default     = ""
}

variable "ip_rules" {
  description = "List of IP addresses or CIDR blocks allowed to access the Key Vault"
  type        = list(string)
  default     = []
}

variable "virtual_network_subnet_ids" {
  description = "List of virtual network subnet IDs allowed to access the Key Vault"
  type        = list(string)
  default     = []
}

variable "enabled_for_deployment" {
  description = "Allow Azure Virtual Machines to retrieve certificates stored as secrets"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets from the vault"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager to retrieve secrets from the vault"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for the Key Vault"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain deleted items (soft delete)"
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}
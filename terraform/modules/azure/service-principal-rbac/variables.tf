variable "display_name" {
  description = "Entra ID app registration display name (service principal name)."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (included in azure_credentials_json output for GitHub AZURE_CREDENTIALS)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the default RBAC scope (used when scope is not set)."
  type        = string
}

variable "additional_resource_group_names" {
  description = "Extra resource groups (same subscription) that receive the same role as `this` (e.g. rg-common for shared storage / Terraform state)."
  type        = list(string)
  default     = []
}

variable "scope" {
  description = "Optional full ARM scope for the role assignment. Defaults to the resource group scope."
  type        = string
  default     = null
}

variable "role_definition_name" {
  description = "Azure RBAC role to assign (e.g. Contributor)."
  type        = string
  default     = "Contributor"
}

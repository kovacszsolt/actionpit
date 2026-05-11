variable "principal_id" {
  description = "Object ID (principal_id) of the user-assigned managed identity to grant roles to."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (used to build the resource group scope)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that hosts Container Apps (Contributor scope)."
  type        = string
}

variable "registry_name" {
  description = "ACR name without .azurecr.io."
  type        = string
}

variable "registry_resource_group_name" {
  description = "Resource group that contains the container registry."
  type        = string
}

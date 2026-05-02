variable "registry_name" {
  description = "ACR name (without .azurecr.io)"
  type        = string
}

variable "registry_resource_group_name" {
  description = "Resource group containing the container registry"
  type        = string
}

variable "principal_id" {
  description = "Azure AD principal ID to grant on the registry (UAMI principal_id / object id)"
  type        = string
}

variable "role_definition_name" {
  description = "Built-in RBAC role on the registry (e.g. AcrPull, AcrPush)"
  type        = string
  default     = "AcrPull"
}

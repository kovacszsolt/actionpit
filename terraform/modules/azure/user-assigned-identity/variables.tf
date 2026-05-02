variable "identity_name" {
  description = "Name of the User Assigned Identity"
  type        = string
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

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Communication Service name (globally unique constraint applies in Azure)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "data_location" {
  description = "Data location (e.g. Europe, United States, United Kingdom)."
  type        = string
  default     = "Europe"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "email_service_domain_id" {
  description = "Optional Email Communication Service domain resource ID to associate with Communication Service."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the Email Communication Service resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where resources are created."
  type        = string
}

variable "data_location" {
  description = "ACS data location (e.g. Europe, United States, United Kingdom)."
  type        = string
  default     = "Europe"
}

variable "tags" {
  description = "Tags for all resources in this module."
  type        = map(string)
  default     = {}
}

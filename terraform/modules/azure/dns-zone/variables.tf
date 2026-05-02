variable "name" {
  description = "DNS zone name (e.g. example.com - without trailing dot)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the zone is created."
  type        = string
}

variable "tags" {
  description = "Tags for the DNS zone."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Relative name in the DNS zone (e.g. www for www.example.com)."
  type        = string
}

variable "zone_name" {
  description = "Azure DNS zone name (e.g. example.com)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the DNS zone."
  type        = string
}

variable "record" {
  description = "CNAME target hostname (e.g. myapp.azurestaticapps.net)."
  type        = string
}

variable "ttl" {
  description = "TTL in seconds."
  type        = number
  default     = 300
}

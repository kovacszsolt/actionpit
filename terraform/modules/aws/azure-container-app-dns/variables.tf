variable "zone_name" {
  description = "Route53 hosted zone name (e.g. example.com)."
  type        = string
}

variable "zone_id" {
  description = "Existing Route53 hosted zone ID."
  type        = string
}

variable "hostname" {
  description = "Fully qualified custom domain hostname (e.g. api.example.com)."
  type        = string

  validation {
    condition     = endswith(var.hostname, ".${var.zone_name}") && length(trimspace(var.hostname)) > length(var.zone_name) + 1
    error_message = "hostname must be a subdomain of zone_name (e.g. api.example.com with zone example.com)."
  }
}

variable "cname_target" {
  description = "Azure Container App ingress FQDN (*.azurecontainerapps.io)."
  type        = string
}

variable "asuid_verification_id" {
  description = "Azure Container App custom_domain_verification_id for asuid TXT validation."
  type        = string
}

variable "ttl" {
  description = "TTL in seconds for CNAME and TXT records."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags applied to Route53 resources when the zone is created by the child module."
  type        = map(string)
  default     = {}
}

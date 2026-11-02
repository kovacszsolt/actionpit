variable "zone_name" {
  description = "Route53 hosted zone name (e.g. example.com)."
  type        = string
}

variable "zone_id" {
  description = "Existing Route53 hosted zone ID."
  type        = string
}

variable "hostname" {
  description = "Fully qualified custom domain hostname (e.g. api.example.com, or example.com for the zone apex)."
  type        = string

  validation {
    condition = (
      var.hostname == var.zone_name
      || (endswith(var.hostname, ".${var.zone_name}") && length(trimspace(var.hostname)) > length(var.zone_name) + 1)
    )
    error_message = "hostname must be zone_name (apex) or a subdomain of it (e.g. api.example.com with zone example.com)."
  }
}

variable "a_target" {
  description = "IPv4 address the A record points to (e.g. Static Web App properties.stableInboundIP or a Container App Environment static IP)."
  type        = string

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$", var.a_target))
    error_message = "a_target must be a valid IPv4 address."
  }
}

variable "ttl" {
  description = "TTL in seconds for the A record."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags applied to Route53 resources when the zone is created by the child module."
  type        = map(string)
  default     = {}
}

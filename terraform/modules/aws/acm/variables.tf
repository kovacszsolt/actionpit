variable "domain_name" {
  description = "Primary fully qualified domain name for the ACM certificate."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional FQDNs included on the certificate (SANs)."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route53 hosted zone ID for managed DNS validation records."
  type        = string
  default     = null
  nullable    = true
}

variable "dns_validation_domains" {
  description = "Certificate domains for which Route53 validation records are created in zone_id. Defaults to [domain_name] so SANs in other zones can be validated manually."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "wait_for_validation" {
  description = "Wait until the certificate is issued for all domains (including manually validated SANs)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the ACM certificate."
  type        = map(string)
  default     = {}
}

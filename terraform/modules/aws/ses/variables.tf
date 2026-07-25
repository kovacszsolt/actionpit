variable "domain_name" {
  description = "Domain to verify as an SES email identity (e.g. example.com)."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DKIM, MAIL FROM, SPF, and DMARC records."
  type        = string
}

variable "mail_from_subdomain" {
  description = "Subdomain used as the custom MAIL FROM domain (under domain_name)."
  type        = string
  default     = "mail"
}

variable "dmarc_policy" {
  description = "DMARC policy for the _dmarc TXT record (none, quarantine, or reject)."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc_policy must be one of: none, quarantine, reject."
  }
}

variable "create_smtp_user" {
  description = "Create an IAM user with access keys for SES SMTP sending."
  type        = bool
  default     = true
}

variable "smtp_user_name" {
  description = "IAM user name for SMTP credentials. Defaults to ses-smtp-<domain with dots replaced by dashes>."
  type        = string
  default     = null
  nullable    = true
}

variable "configuration_set_name" {
  description = "SES configuration set name. Defaults to the domain with dots replaced by dashes."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied to SES and IAM resources that support tagging."
  type        = map(string)
  default     = {}
}

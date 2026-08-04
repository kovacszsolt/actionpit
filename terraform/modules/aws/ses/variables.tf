variable "domain_name" {
  description = "Domain to verify as an SES email identity (e.g. example.com)."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DKIM, MAIL FROM, SPF, DMARC, and optional inbound MX records."
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

variable "enable_inbound" {
  description = "Enable SES email receiving: apex MX, receipt rules, and S3 storage."
  type        = bool
  default     = false
}

variable "inbound_bucket_name" {
  description = "Globally unique S3 bucket name for received emails. Required when enable_inbound is true."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.inbound_bucket_name == null ||
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.inbound_bucket_name))
    )
    error_message = "inbound_bucket_name must be a valid S3 bucket name (3-63 chars, lowercase, numbers, dots, hyphens)."
  }
}

variable "inbound_bucket_force_destroy" {
  description = "Allow Terraform to delete the inbound bucket even when it contains received emails."
  type        = bool
  default     = true
}

variable "inbound_recipients" {
  description = "SES receipt rule recipients. Defaults to the domain (catch-all for that domain)."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "inbound_object_key_prefix" {
  description = "S3 object key prefix for stored inbound emails."
  type        = string
  default     = "inbound/"
}

variable "inbound_expiration_days" {
  description = "Expire inbound email objects after this many days. Set null to disable lifecycle expiration."
  type        = number
  default     = 90
  nullable    = true
}

variable "inbound_rule_set_name" {
  description = "SES receipt rule set name. Defaults to inbound-<domain with dots replaced by dashes>."
  type        = string
  default     = null
  nullable    = true
}

variable "inbound_rule_name" {
  description = "Name of the SES receipt rule that stores mail in S3."
  type        = string
  default     = "store-to-s3"
}

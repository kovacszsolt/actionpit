variable "zone_name" {
  description = "Route53 hosted zone name (e.g. example.com)."
  type        = string
}

variable "create_zone" {
  description = "Create a new hosted zone. When false, zone_id must be set."
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "Existing hosted zone ID when create_zone is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_zone || (var.zone_id != null && var.zone_id != "")
    error_message = "zone_id is required when create_zone is false."
  }
}

variable "comment" {
  description = "Comment for a newly created hosted zone."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Whether to destroy all records in the zone when deleting the hosted zone."
  type        = bool
  default     = false
}

variable "alias_records" {
  description = "A/AAAA alias records keyed by relative name (@ for zone apex)."
  type = map(object({
    type                   = optional(string, "A")
    dns_name               = string
    hosted_zone_id         = string
    evaluate_target_health = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.alias_records) :
      contains(["A", "AAAA"], record.type)
    ])
    error_message = "alias_records type must be A or AAAA."
  }
}

variable "cname_records" {
  description = "CNAME records keyed by relative name (@ for zone apex)."
  type = map(object({
    ttl    = optional(number, 300)
    record = string
  }))
  default = {}
}

variable "txt_records" {
  description = "TXT records keyed by relative name (@ for zone apex)."
  type = map(object({
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}
}

variable "mx_records" {
  description = "MX records keyed by relative name (@ for zone apex)."
  type = map(object({
    ttl = optional(number, 300)
    records = list(object({
      priority = number
      value    = string
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to a newly created hosted zone."
  type        = map(string)
  default     = {}
}

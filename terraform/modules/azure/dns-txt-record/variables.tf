variable "resource_group_name" {
  description = "Resource group containing the public Azure DNS zone."
  type        = string
}

variable "zone_name" {
  description = "Azure DNS zone name (e.g. mdwizard.online)."
  type        = string
}

variable "txt_records" {
  description = "TXT records keyed by label; each item has ttl and values list."
  type = map(object({
    ttl    = number
    values = list(string)
  }))
  default = {}
}

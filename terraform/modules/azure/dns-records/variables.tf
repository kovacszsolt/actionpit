variable "resource_group_name" {
  description = "Resource group containing the public Azure DNS zone."
  type        = string
}

variable "zone_name" {
  description = "Azure DNS zone name (e.g. example.com)."
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

variable "cname_records" {
  description = "CNAME records keyed by label; each item has ttl and target record."
  type = map(object({
    ttl    = number
    record = string
  }))
  default = {}
}

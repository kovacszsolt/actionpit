variable "static_web_app_id" {
  description = "Resource ID of the Azure Static Web App (azurerm_static_web_app.main.id)."
  type        = string
}

variable "domain_name" {
  description = "Apex hostname (e.g. mdwizard.online), same as the public DNS zone name."
  type        = string
}

variable "zone_name" {
  description = "Azure DNS zone name (must match domain_name for apex)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the Azure DNS zone."
  type        = string
}

variable "ttl" {
  description = "TTL for DNS records (seconds)."
  type        = number
  default     = 300
}

variable "apex_inbound_ipv4" {
  description = "Optional override for apex A record. If unset, stableInboundIP is read from the Static Web App via ARM (see data.azapi_resource.swa)."
  type        = string
  default     = null
}

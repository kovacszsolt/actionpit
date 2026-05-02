variable "static_web_app_id" {
  description = "Resource ID of the Azure Static Web App."
  type        = string
}

variable "domain_name" {
  description = "Full hostname to register (e.g. www.example.com)."
  type        = string
}

variable "validation_type" {
  description = "cname-delegation (subdomain + CNAME) or dns-txt-token (apex / TXT)."
  type        = string
  default     = "cname-delegation"

  validation {
    condition     = contains(["cname-delegation", "dns-txt-token"], var.validation_type)
    error_message = "validation_type must be cname-delegation or dns-txt-token."
  }
}

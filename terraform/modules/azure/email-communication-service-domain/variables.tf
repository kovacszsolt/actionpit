variable "email_service_id" {
  description = "Resource ID of the Azure Email Communication Service."
  type        = string
}

variable "domain_name" {
  description = "Custom domain for CustomerManaged setup (e.g. example.com)."
  type        = string
}

variable "tags" {
  description = "Tags for all resources in this module."
  type        = map(string)
  default     = {}
}

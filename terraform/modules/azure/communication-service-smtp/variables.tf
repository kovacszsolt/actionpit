variable "communication_service_id" {
  description = "Azure Communication Service resource ID (ACS, not Email Service)."
  type        = string
}

variable "entra_display_name" {
  description = "Entra app registration display name for SMTP AUTH."
  type        = string
}

variable "smtp_username" {
  description = "SMTP AUTH username (free-form or email-like)."
  type        = string
}

variable "smtp_username_resource_name" {
  description = "ARM name for the SmtpUsername resource (alphanumeric/hyphen)."
  type        = string
  default     = "smtp"
}

variable "role_definition_name" {
  description = "RBAC role on the Communication Service (ACS SMTP needs Read/Write + EmailServices/write)."
  type        = string
  default     = "Communication and Email Service Owner"
}

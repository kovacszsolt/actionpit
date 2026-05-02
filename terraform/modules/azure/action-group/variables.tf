variable "name" {
  description = "Name of the Action Group."
  type        = string
}

variable "short_name" {
  description = "Short name of the Action Group (max 12 characters, used in SMS/webhook payloads)."
  type        = string
  validation {
    condition     = length(var.short_name) <= 12
    error_message = "short_name must be at most 12 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region as ARM location name (e.g. westeurope)."
  type        = string
}

variable "email_receivers" {
  description = "List of email receivers. Each item: { name = \"...\", email_address = \"...\" }."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "azure_app_push_receivers" {
  description = "List of Azure App Push receivers (email of the user who receives push in Azure mobile app)."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "tags" {
  description = "Tags for the Action Group."
  type        = map(string)
  default     = {}
}

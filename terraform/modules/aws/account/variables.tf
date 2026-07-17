variable "name" {
  description = "Friendly name for the member account."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "email" {
  description = "Globally unique email address for the account root user."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.email))
    error_message = "email must be a valid email address."
  }
}

variable "parent_id" {
  description = "Parent organizational unit ID. Omit or null to place the account in the root OU."
  type        = string
  default     = null
}

variable "role_name" {
  description = "Name of the IAM role Terraform uses to access the new account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "iam_user_access_to_billing" {
  description = "Whether IAM users in the management account can access billing for the member account."
  type        = string
  default     = "ALLOW"

  validation {
    condition     = contains(["ALLOW", "DENY"], var.iam_user_access_to_billing)
    error_message = "iam_user_access_to_billing must be ALLOW or DENY."
  }
}

variable "tags" {
  description = "Tags applied to the member account."
  type        = map(string)
  default     = {}
}

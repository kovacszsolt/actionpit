variable "account_id" {
  description = "Target member AWS account ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "identity_center_username" {
  description = "Existing IAM Identity Center user name to assign to the account."
  type        = string

  validation {
    condition     = length(trimspace(var.identity_center_username)) > 0
    error_message = "identity_center_username must not be empty."
  }
}

variable "permission_set_name" {
  description = "IAM Identity Center permission set name (for example AdministratorAccess)."
  type        = string
  default     = "AdministratorAccess"
}

variable "principal_type" {
  description = "Identity Center principal type."
  type        = string
  default     = "USER"

  validation {
    condition     = contains(["USER", "GROUP"], var.principal_type)
    error_message = "principal_type must be USER or GROUP."
  }
}

variable "sso_instance_arn" {
  description = "IAM Identity Center instance ARN."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sso:::instance/", var.sso_instance_arn))
    error_message = "sso_instance_arn must be a valid IAM Identity Center instance ARN."
  }
}

variable "identity_store_id" {
  description = "IAM Identity Center identity store ID."
  type        = string

  validation {
    condition     = can(regex("^d-[0-9a-f]{10}$", var.identity_store_id))
    error_message = "identity_store_id must be a valid identity store ID."
  }
}

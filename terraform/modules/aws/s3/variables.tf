variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase letters, numbers, dots, and hyphens only."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning."
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Default server-side encryption algorithm. Use AES256 or aws:kms."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256 or aws:kms."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN when sse_algorithm is aws:kms."
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block all public access to the bucket."
  type        = bool
  default     = true
}

variable "object_ownership" {
  description = "Object ownership setting. BucketOwnerEnforced disables ACLs."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  }
}

variable "lifecycle_rules" {
  description = "Optional lifecycle rules keyed by rule id."
  type = map(object({
    enabled                                = optional(bool, true)
    prefix                                 = optional(string)
    expiration_days                        = optional(number)
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = {}
}

variable "cloudfront_distribution_arns" {
  description = "CloudFront distribution ARNs allowed to read objects via Origin Access Control."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}

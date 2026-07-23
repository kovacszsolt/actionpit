variable "bucket_name" {
  description = "Globally unique S3 bucket name for static assets."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase letters, numbers, dots, and hyphens only."
  }
}

variable "hostname" {
  description = "Primary public FQDN served by CloudFront (e.g. www.example.com)."
  type        = string
}

variable "additional_hostnames" {
  description = "Extra CloudFront aliases and ACM SANs (e.g. auth.example.com). DNS for these hostnames is managed outside this stack."
  type        = list(string)
  default     = []
}

variable "managed_hostnames" {
  description = "Extra CloudFront aliases and ACM SANs in the same Route53 zone; DNS alias + ACM validation records are created."
  type        = list(string)
  default     = []
}

variable "zone_name" {
  description = "Route53 hosted zone name (e.g. example.com)."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for ACM validation and alias records."
  type        = string
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete the S3 bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "site_mode" {
  description = "CloudFront routing: plain, static_directory (Astro/SSG), or react_spa (Vite/React deep links)."
  type        = string
  default     = "plain"

  validation {
    condition     = contains(["plain", "static_directory", "react_spa"], var.site_mode)
    error_message = "site_mode must be plain, static_directory, or react_spa."
  }
}

variable "spa_fallback" {
  description = "Return default_root_object with HTTP 200 for SPA client-side routes on 403/404."
  type        = bool
  default     = true
}

variable "static_site_index_rewrite" {
  description = "Rewrite extensionless URIs to index.html for Astro/static directory output on S3 REST origin."
  type        = bool
  default     = false
}

variable "default_root_object" {
  description = "Default root object served for the CloudFront distribution root path."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "github_deploy_iam_user_name" {
  description = "IAM user name for GitHub Actions deploy. Defaults to github-{bucket_name}-deploy."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}

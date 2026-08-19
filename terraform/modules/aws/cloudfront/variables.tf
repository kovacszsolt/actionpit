variable "name" {
  description = "Short name used for CloudFront OAC and origin identifiers."
  type        = string
}

variable "comment" {
  description = "Comment shown on the CloudFront distribution."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the distribution is enabled."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled on the distribution."
  type        = bool
  default     = true
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

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 origin bucket."
  type        = string
}

variable "default_root_object" {
  description = "Default root object served for the distribution root path."
  type        = string
  default     = "index.html"
}

variable "site_mode" {
  description = "Routing mode: plain (no rewrite), static_directory (Astro/SSG per-path index.html), react_spa (single index.html for client routes). When plain, spa_fallback and static_site_index_rewrite booleans still apply."
  type        = string
  default     = "plain"

  validation {
    condition     = contains(["plain", "static_directory", "react_spa"], var.site_mode)
    error_message = "site_mode must be plain, static_directory, or react_spa."
  }
}

variable "spa_fallback" {
  description = "Return default_root_object with HTTP 200 for SPA client-side routes on 403/404. Ignored when site_mode is react_spa (use viewer-request rewrite instead)."
  type        = bool
  default     = true
}

variable "static_site_index_rewrite" {
  description = "Rewrite extensionless URIs to per-directory index.html (Astro output). Used when site_mode is static_directory, or plain with this flag true."
  type        = bool
  default     = false
}

variable "aliases" {
  description = "Custom domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1. Required when aliases is non-empty."
  type        = string
  default     = null
}

variable "web_acl_id" {
  description = "Optional WAFv2 web ACL ARN (CLOUDFRONT scope). Required for CloudFront flat-rate pricing plans."
  type        = string
  default     = null
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy for the default cache behavior."
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "viewer_protocol_policy must be allow-all, https-only, or redirect-to-https."
  }
}

variable "cache_policy_id" {
  description = "Managed cache policy ID for the default cache behavior."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
}

variable "origin_request_policy_id" {
  description = "Optional managed origin request policy ID."
  type        = string
  default     = null
}

variable "compress" {
  description = "Whether CloudFront compresses objects for this cache behavior."
  type        = bool
  default     = true
}

variable "geo_restriction_type" {
  description = "Geo restriction type: none, whitelist, or blacklist."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the CloudFront distribution."
  type        = map(string)
  default     = {}
}

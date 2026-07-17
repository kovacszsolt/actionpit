variable "bucket_name" {
  description = "S3 bucket name to attach the CloudFront OAC read policy."
  type        = string
}

variable "cloudfront_distribution_arns" {
  description = "CloudFront distribution ARNs allowed to read objects via Origin Access Control."
  type        = list(string)

  validation {
    condition     = length(var.cloudfront_distribution_arns) > 0
    error_message = "cloudfront_distribution_arns must contain at least one distribution ARN."
  }
}

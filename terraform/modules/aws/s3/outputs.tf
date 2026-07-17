output "id" {
  description = "S3 bucket name (id)."
  value       = aws_s3_bucket.main.id
}

output "arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Regional bucket domain name for CloudFront or direct S3 origin."
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "region" {
  description = "AWS region where the bucket was created."
  value       = aws_s3_bucket.main.region
}

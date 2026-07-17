output "id" {
  description = "CloudFront distribution ID (E...)."
  value       = aws_cloudfront_distribution.main.id
}

output "arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.main.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name (*.cloudfront.net)."
  value       = aws_cloudfront_distribution.main.domain_name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID for alias records."
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "origin_access_control_id" {
  description = "Origin Access Control ID for the S3 origin."
  value       = aws_cloudfront_origin_access_control.s3.id
}

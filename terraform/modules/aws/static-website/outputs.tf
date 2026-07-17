output "hostname" {
  description = "Primary public hostname served by CloudFront."
  value       = var.hostname
}

output "additional_hostnames" {
  description = "Additional CloudFront aliases / ACM SANs."
  value       = var.additional_hostnames
}

output "domain_validation_options" {
  description = "ACM DNS validation records for all certificate domains (for manual SAN validation)."
  value       = module.acm.domain_validation_options
}

output "bucket_id" {
  description = "S3 bucket name (id)."
  value       = module.s3.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = module.s3.arn
}

output "certificate_arn" {
  description = "Validated ACM certificate ARN (us-east-1)."
  value       = module.acm.certificate_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cloudfront.id
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN."
  value       = module.cloudfront.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (*.cloudfront.net)."
  value       = module.cloudfront.domain_name
}

output "route53_alias_fqdn" {
  description = "FQDN of the Route53 alias record pointing to CloudFront."
  value       = module.dns.alias_record_fqdns[local.route53_record_name]
}

output "github_deploy_iam_user_name" {
  description = "IAM user name for GitHub Actions deploy."
  value       = aws_iam_user.github_deploy.name
}

output "github_deploy_iam_user_arn" {
  description = "IAM user ARN for GitHub Actions deploy."
  value       = aws_iam_user.github_deploy.arn
}

output "github_deploy_access_key_id" {
  description = "Access key ID for the GitHub Actions deploy IAM user."
  value       = aws_iam_access_key.github_deploy.id
}

output "github_deploy_secret_access_key" {
  description = "Secret access key for the GitHub Actions deploy IAM user. Copy to GitHub once; also stored in Terraform state."
  value       = aws_iam_access_key.github_deploy.secret
  sensitive   = true
}

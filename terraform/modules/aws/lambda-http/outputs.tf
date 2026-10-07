output "hostname" {
  description = "Primary public HTTPS hostname."
  value       = var.hostname
}

output "url" {
  description = "Public HTTPS URL for the Lambda HTTP endpoint."
  value       = "https://${var.hostname}"
}

output "function_name" {
  description = "Lambda function name."
  value       = local.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN (null when create_lambda is false)."
  value       = var.create_lambda ? module.lambda[0].lambda_function_arn : null
}

output "lambda_invoke_arn" {
  description = "Lambda invoke ARN (null when create_lambda is false)."
  value       = var.create_lambda ? module.lambda[0].lambda_function_invoke_arn : null
}

output "execution_role_arn" {
  description = "Lambda execution role ARN (null when create_lambda is false and no role was created here)."
  value       = var.create_lambda ? module.lambda[0].execution_role_arn : null
}

output "function_url" {
  description = "Direct Lambda function URL (IAM-protected; intended for CloudFront origin only)."
  value       = aws_lambda_function_url.main.function_url
}

output "function_url_domain" {
  description = "Hostname of the Lambda function URL origin."
  value       = local.function_url_domain
}

output "certificate_arn" {
  description = "Validated ACM certificate ARN (us-east-1)."
  value       = module.acm.certificate_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (*.cloudfront.net)."
  value       = aws_cloudfront_distribution.main.domain_name
}

output "route53_alias_fqdn" {
  description = "FQDN of the Route53 alias record for the primary hostname."
  value       = module.dns.alias_record_fqdns[local.route53_record_name]
}

output "managed_route53_alias_fqdns" {
  description = "FQDNs of Route53 alias records for managed_hostnames."
  value = {
    for name in values(local.managed_route53_record_names) :
    name => module.dns.alias_record_fqdns[name]
  }
}

output "domain_validation_options" {
  description = "ACM DNS validation records for all certificate domains."
  value       = module.acm.domain_validation_options
}

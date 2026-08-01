output "identity_arn" {
  description = "ARN of the SESv2 domain email identity."
  value       = aws_sesv2_email_identity.domain.arn
}

output "email_identity" {
  description = "Verified SES email identity (domain name)."
  value       = aws_sesv2_email_identity.domain.email_identity
}

output "configuration_set_name" {
  description = "Name of the SES configuration set."
  value       = aws_sesv2_configuration_set.main.configuration_set_name
}

output "mail_from_domain" {
  description = "Custom MAIL FROM domain."
  value       = local.mail_from_domain
}

output "smtp_endpoint" {
  description = "SES SMTP endpoint hostname for the current region."
  value       = local.smtp_endpoint
}

output "smtp_username" {
  description = "IAM access key ID used as the SMTP username. Null when create_smtp_user is false."
  value       = var.create_smtp_user ? aws_iam_access_key.smtp[0].id : null
  sensitive   = true
}

output "smtp_password" {
  description = "SES SMTP password derived from the IAM secret access key. Null when create_smtp_user is false."
  value       = var.create_smtp_user ? aws_iam_access_key.smtp[0].ses_smtp_password_v4 : null
  sensitive   = true
}

output "smtp_user_name" {
  description = "IAM user name created for SMTP sending. Null when create_smtp_user is false."
  value       = var.create_smtp_user ? aws_iam_user.smtp[0].name : null
}

output "inbound_bucket_id" {
  description = "S3 bucket ID for received emails. Null when enable_inbound is false."
  value       = var.enable_inbound ? aws_s3_bucket.inbound[0].id : null
}

output "inbound_bucket_arn" {
  description = "S3 bucket ARN for received emails. Null when enable_inbound is false."
  value       = var.enable_inbound ? aws_s3_bucket.inbound[0].arn : null
}

output "inbound_rule_set_name" {
  description = "Active SES receipt rule set name. Null when enable_inbound is false."
  value       = var.enable_inbound ? aws_ses_receipt_rule_set.inbound[0].rule_set_name : null
}

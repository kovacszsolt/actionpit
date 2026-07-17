output "account_id" {
  description = "AWS account ID of the member account."
  value       = aws_organizations_account.main.id
}

output "arn" {
  description = "ARN of the member account."
  value       = aws_organizations_account.main.arn
}

output "role_name" {
  description = "IAM role name for cross-account access from the management account."
  value       = aws_organizations_account.main.role_name
}

output "account_id" {
  description = "Assigned member AWS account ID."
  value       = var.account_id
}

output "identity_center_username" {
  description = "Assigned IAM Identity Center user name."
  value       = data.aws_identitystore_user.main.user_name
}

output "identity_center_user_id" {
  description = "Assigned IAM Identity Center user ID."
  value       = data.aws_identitystore_user.main.user_id
}

output "permission_set_arn" {
  description = "Permission set ARN assigned to the user for the account."
  value       = data.aws_ssoadmin_permission_set.main.arn
}

output "permission_set_name" {
  description = "Permission set name assigned to the user for the account."
  value       = var.permission_set_name
}

output "account_assignment_id" {
  description = "Terraform resource ID of the account assignment."
  value       = aws_ssoadmin_account_assignment.main.id
}

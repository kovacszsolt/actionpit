output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.main.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.main.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function (for API Gateway / Event Mappings permissions)."
  value       = aws_lambda_function.main.invoke_arn
}

output "execution_role_arn" {
  description = "ARN of the IAM role the function assumes (created by the module or provided via execution_role_arn)."
  value       = var.create_execution_role ? aws_iam_role.main[0].arn : var.execution_role_arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group used by the function."
  value       = local.log_group_name
}

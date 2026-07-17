output "certificate_arn" {
  description = "ACM certificate ARN (us-east-1). When wait_for_validation is true, this is the validated ARN."
  value       = var.wait_for_validation ? aws_acm_certificate_validation.main[0].certificate_arn : aws_acm_certificate.main.arn
}

output "domain_name" {
  description = "Primary certificate domain name."
  value       = aws_acm_certificate.main.domain_name
}

output "subject_alternative_names" {
  description = "Certificate subject alternative names."
  value       = aws_acm_certificate.main.subject_alternative_names
}

output "domain_validation_options" {
  description = "DNS validation records for all certificate domains (use for manual validation of unmanaged SANs)."
  value = [
    for dvo in aws_acm_certificate.main.domain_validation_options : {
      domain_name           = dvo.domain_name
      resource_record_name  = dvo.resource_record_name
      resource_record_type  = dvo.resource_record_type
      resource_record_value = dvo.resource_record_value
    }
  ]
}

locals {
  dns_validation_domains = coalesce(var.dns_validation_domains, [var.domain_name])

  validation_records = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if contains(local.dns_validation_domains, dvo.domain_name)
  }
}

resource "aws_acm_certificate" "main" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_route53_record" "validation" {
  for_each = local.validation_records

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  lifecycle {
    precondition {
      condition     = length(local.validation_records) == 0 || (var.zone_id != null && var.zone_id != "")
      error_message = "zone_id is required when dns_validation_domains is non-empty."
    }
  }
}

resource "aws_acm_certificate_validation" "main" {
  count = var.wait_for_validation ? 1 : 0

  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.main.arn

  # Omit validation_record_fqdns so Terraform waits for full issuance, including SANs validated outside this zone.
  depends_on = [aws_route53_record.validation]
}

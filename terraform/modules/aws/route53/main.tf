locals {
  zone_id = var.create_zone ? aws_route53_zone.main[0].zone_id : var.zone_id

  record_name = {
    for name, _ in merge(var.alias_records, var.cname_records, var.txt_records, var.mx_records) :
    name => name == "@" ? "" : name
  }
}

resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0

  name          = var.zone_name
  comment       = coalesce(var.comment, "Hosted zone for ${var.zone_name}")
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_route53_record" "alias" {
  for_each = var.alias_records

  zone_id = local.zone_id
  name    = local.record_name[each.key]
  type    = each.value.type

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.hosted_zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}

resource "aws_route53_record" "cname" {
  for_each = var.cname_records

  zone_id = local.zone_id
  name    = local.record_name[each.key]
  type    = "CNAME"
  ttl     = each.value.ttl
  records = [each.value.record]
}

resource "aws_route53_record" "txt" {
  for_each = var.txt_records

  zone_id = local.zone_id
  name    = local.record_name[each.key]
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.records
}

resource "aws_route53_record" "mx" {
  for_each = var.mx_records

  zone_id = local.zone_id
  name    = local.record_name[each.key]
  type    = "MX"
  ttl     = each.value.ttl
  records = [for r in each.value.records : "${r.priority} ${r.value}"]
}

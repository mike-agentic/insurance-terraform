resource "aws_route53_record" "cloudfront_alias" {
  provider = aws.shared

  for_each = {
    for record in flatten([
      for key, value in local.cloudfront_definitions : [
        for alias in value.aliases : {
          alias      = alias
          parent_key = key
        }
      ]
    ]) : record.alias => record
  }

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.alias
  type    = "A"

  alias {
    name                   = module.cloudfront[each.value.parent_key].cloudfront_distribution_domain_name
    zone_id                = module.cloudfront[each.value.parent_key].cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
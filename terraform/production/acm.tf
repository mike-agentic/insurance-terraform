module "acm_cloudfront" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0.0"

  providers = {
    aws = aws.global
  }

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]

  # subject_alternative_names = concat(
  #   [for app in values(var.ecs_apps) : "${app.name}-backend.${var.domain_name}"],
  #   var.cloudfront_alternative_names
  # )

  zone_id                = data.aws_route53_zone.this.zone_id
  validation_method      = "DNS"
  create_route53_records = false
  wait_for_validation    = false

  tags = merge(
    var.tags,
    {
      Name = format("acm-cloudfront-%s", var.domain_name)
    }
  )
}

module "acm_load_balancer" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0.0"

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]

  # subject_alternative_names = concat(
  #   [for app in values(var.ecs_apps) : "${app.name}-backend.${var.domain_name}"],
  #   var.alb_alternative_names
  # )

  zone_id                = data.aws_route53_zone.this.zone_id
  validation_method      = "DNS"
  create_route53_records = false
  wait_for_validation    = false

  tags = merge(
    var.tags,
    {
      Name = format("acm-alb-%s", var.domain_name)
    }
  )
}

module "route53_records" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0.0"

  providers = {
    aws = aws.shared
  }

  create_certificate          = false
  create_route53_records_only = true

  validation_method = "DNS"
  zone_id           = data.aws_route53_zone.this.zone_id

  distinct_domain_names = concat(
    module.acm_cloudfront.distinct_domain_names,
    module.acm_load_balancer.distinct_domain_names
  )

  acm_certificate_domain_validation_options = concat(
    module.acm_cloudfront.acm_certificate_domain_validation_options,
    module.acm_load_balancer.acm_certificate_domain_validation_options
  )

  validation_timeout = 2
}
locals {
  default_cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  default_origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
  no_cache_policy_id               = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
  all_viewer_policy_id             = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
  # acm_certificate_arn              = module.acm_cloudfront.certificate_arn #"arn:aws:acm:us-east-1:432629721957:certificate/2753a239-fe22-488c-8216-87c32f38f52a"

  # Define S3 origins that need OAC
  s3_origins = [
    "frontend"
  ]

  # Common error responses for SPAs
  error_responses = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]

  oac_definitions = {
    for key in local.s3_origins : key => {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  cloudfront_definitions = {
    frontend = {
      comment                  = "CloudFront Distribution for Insurance Frontend - Production"
      origin_id                = "s3-assets-origin"
      domain_name              = module.s3["${var.prefix}-${var.environment}-frontend"].s3_bucket_bucket_domain_name
      cache_policy_id          = local.default_cache_policy_id
      origin_request_policy_id = local.default_origin_request_policy_id
      default_root_object      = "index.html"
      aliases = [
        "insurance-demo.${var.domain_name}"
      ]
      allowed_methods = ["GET", "HEAD", "OPTIONS"]
    }

    backend = {
      comment                  = "CloudFront Distribution for Insurance Backend APIs - Production"
      origin_id                = "alb-api-origin"
      domain_name              = module.alb.dns_name
      cache_policy_id          = local.no_cache_policy_id
      origin_request_policy_id = local.all_viewer_policy_id
      aliases = [
        "insurance-backend.${var.domain_name}",
        "insurance-sync.${var.domain_name}",
        "insurance-mcp.${var.domain_name}",
        "insurance-outlook.${var.domain_name}"
      ]
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    }
  }
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 5.0.0"

  for_each = local.cloudfront_definitions

  comment             = each.value.comment
  enabled             = true
  aliases             = each.value.aliases
  default_root_object = try(each.value.default_root_object, null)

  # Use consistent logic for error responses
  custom_error_response = contains(local.s3_origins, each.key) ? local.error_responses : [{}]

  web_acl_id = aws_wafv2_web_acl.main.arn

  viewer_certificate = {
    acm_certificate_arn      = module.acm_cloudfront.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  create_origin_access_control = contains(local.s3_origins, each.key)
  origin_access_control = contains(local.s3_origins, each.key) ? {
    "oac-${var.prefix}-${var.environment}-${each.key}" = local.oac_definitions[each.key]
  } : {}

  create_vpc_origin = false

  logging_config = {
    bucket = module.s3["${var.prefix}-${var.environment}-cloudfront-logs"].s3_bucket_bucket_domain_name
    prefix = "${var.environment}/website/"
  }

  origin = merge(
    each.key == "frontend" ? {
      (each.value.origin_id) = {
        domain_name           = each.value.domain_name
        origin_id             = each.value.origin_id
        origin_access_control = "oac-${var.prefix}-${var.environment}-${each.key}"
      }
    } : {},
    each.key == "backend" ? {
      (each.value.origin_id) = {
        domain_name = each.value.domain_name
        origin_id   = each.value.origin_id
        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    } : {}
  )

  default_cache_behavior = {
    target_origin_id         = each.value.origin_id
    viewer_protocol_policy   = "https-only"
    allowed_methods          = each.value.allowed_methods
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = each.value.cache_policy_id
    origin_request_policy_id = each.value.origin_request_policy_id
    compress                 = false
    use_forwarded_values     = false
    min_ttl                  = 0
  }

  tags = merge(
    var.tags,
    {
      Name = format("%s-%s-cloudfront-%s", var.prefix, var.environment, each.key)
    }
  )
}
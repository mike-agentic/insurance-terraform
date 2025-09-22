resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "${var.prefix}-${var.environment}-vpc-flow-logs"

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs.bucket

  rule {
    id     = "vpc_flow_logs_lifecycle"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.prefix}-${var.environment}-vpc-flow-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.base_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.prefix}-${var.environment}-vpc-flow-logs"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.base_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

module "s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.2.0"

  for_each = {
    "${var.prefix}-${var.environment}-cloudfront-logs" = {
      name                     = "${var.prefix}-${var.environment}-cloudfront-logs"
      object_ownership         = "ObjectWriter"
      control_object_ownership = true
    }

    "${var.prefix}-${var.environment}-frontend" = {
      name             = "${var.prefix}-${var.environment}-frontend"
      object_ownership = "ObjectWriter"
    }
  }

  bucket        = each.value.name
  force_destroy = try(each.value.force_destroy, false)

  object_ownership         = try(each.value.object_ownership, null)
  control_object_ownership = try(each.value.control_object_ownership, false)
  attach_policy            = try(each.value.attach_policy, false)

  grant = each.key == "${var.prefix}-cloudfront-logs" ? [
    {
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
      id         = data.aws_canonical_user_id.current.id
    },
    {
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
      id         = data.aws_cloudfront_log_delivery_canonical_user_id.cloudfront.id
    }
  ] : []

  lifecycle_rule = try(each.value.lifecycle_rule, [])

  attach_elb_log_delivery_policy        = try(each.value.attach_elb_log_delivery_policy, false)
  attach_lb_log_delivery_policy         = try(each.value.attach_lb_log_delivery_policy, false)
  attach_access_log_delivery_policy     = try(each.value.attach_access_log_delivery_policy, false)
  attach_deny_insecure_transport_policy = try(each.value.attach_deny_insecure_transport_policy, false)
  attach_require_latest_tls_policy      = try(each.value.attach_require_latest_tls_policy, false)

  access_log_delivery_policy_source_accounts = try(each.value.access_log_delivery_policy_source_accounts, [])
  access_log_delivery_policy_source_buckets  = try(each.value.access_log_delivery_policy_source_buckets, [])

  tags = var.tags
}

resource "aws_s3_bucket_policy" "main" {
  for_each = {
    "${var.prefix}-${var.environment}-frontend" = {
      name           = "${var.prefix}-${var.environment}-frontend"
      cloudfront_key = "frontend"
    }
  }

  bucket = module.s3[each.key].s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3[each.key].s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront[each.value.cloudfront_key].cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
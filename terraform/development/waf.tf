resource "aws_cloudwatch_log_group" "main" {
  provider = aws.global

  name              = "aws-waf-logs-${var.prefix}-${var.environment}" # must start with aws-waf-logs-
  retention_in_days = 30                                              # 30 days
}

resource "aws_wafv2_web_acl" "main" {
  provider = aws.global

  name        = "${var.prefix}-${var.environment}-web-acl"
  description = "Insurance Web ACL"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.prefix}-${var.environment}-web-acl"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  provider = aws.global

  # for_each = {
  #   frontend = {
  #     name = "web-acl-frontend-${var.prefix}"
  #   }

  #   backend = {
  #     name = "web-acl-backend-${var.prefix}"
  #   }
  # }

  log_destination_configs = [aws_cloudwatch_log_group.main.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn

  depends_on = [
    aws_cloudwatch_log_group.main,
    aws_wafv2_web_acl.main
  ]
}

# # Associate WAF with CloudFront
# resource "aws_wafv2_web_acl_association" "main" {
#   provider = aws.global

#   for_each = {
#     frontend = {
#       name = "web-acl-frontend-${var.prefix}"
#     }

#     backend = {
#       name = "web-acl-backend-${var.prefix}"
#     }
#   }

#   # The ARN of the CloudFront distribution
#   # resource_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cloudfront[each.key].cloudfront_distribution_id}"
#   resource_arn = module.cloudfront[each.key].cloudfront_distribution_arn
#   web_acl_arn  = aws_wafv2_web_acl.main[each.key].arn

#   depends_on = [ 
#     aws_wafv2_web_acl.main,
#     aws_wafv2_web_acl_logging_configuration.main,
#     module.cloudfront
#   ]
# }
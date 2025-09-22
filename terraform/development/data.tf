data "aws_canonical_user_id" "current" {}
data "aws_cloudfront_log_delivery_canonical_user_id" "cloudfront" {}

data "aws_route53_zone" "this" {
  provider = aws.shared
  name     = var.domain_name
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# # ECR API endpoint policy

# data "aws_iam_policy_document" "generic_endpoint_policy" {
#   statement {
#     effect    = "Deny"
#     actions   = ["*"]
#     resources = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:SourceVpc"

#       values = [module.vpc.vpc_id]
#     }
#   }
# }

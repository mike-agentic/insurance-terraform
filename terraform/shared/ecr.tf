module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = ">= 2.4.0"

  for_each = {
    "insurance-backend" = {
      name = "insurance-backend"
    },

    "insurance-nova-sync" = {
      name = "insurance-nova-sync"
    },

    "insurance-edge-mcp-app" = {
      name = "insurance-edge-mcp-app"
    },

    "insurance-outlook-mail-agent" = {
      name = "insurance-outlook-mail-agent"
    },

    "insurance-frontend" = {
      name = "insurance-frontend"
    }
  }

  repository_name = each.value.name


  create_lifecycle_policy       = try(each.value.create_lifecycle_policy, false)
  repository_image_scan_on_push = try(each.value.repository_image_scan_on_push, false)

  repository_image_tag_mutability = "MUTABLE"
  repository_encryption_type      = "AES256"

  # The ARNs of the IAM users/roles that have read access to the repository
  repository_read_access_arns = try(each.value.repository_read_access_arns, [
    "arn:aws:iam::432629721957:root", # Dev Account
    "arn:aws:iam::792172459077:root"  # Prod Account
  ])

  # The ARNs of the Lambda service roles that have read access to the repository
  repository_lambda_read_access_arns = try(each.value.repository_lambda_read_access_arns, [])

  # The ARNs of the IAM users/roles that have read/write access to the repository
  repository_read_write_access_arns = try(each.value.repository_read_write_access_arns, [])

  # If `true`, will delete the repository even if it contains images.
  repository_force_delete = false

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )
}
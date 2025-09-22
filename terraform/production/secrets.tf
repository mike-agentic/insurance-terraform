# module "secrets" {
#   source  = "terraform-aws-modules/secrets-manager/aws"
#   version = "1.3.1"

#   for_each = {
#     "agenticai-api" = {
#       name        = "agenticai-api"
#       description = "Agentic API Secrets"

#       secrets = {
#         MS_CLIENT_ID             = "placeholder"
#         MS_CLIENT_SECRET         = "placeholder"
#         MS_USER_EMAIL            = "placeholder"
#         AWS_REGION_NAME          = "placeholder"
#         POSTGRES_USER            = "placeholder"
#         POSTGRES_PASSWORD        = "placeholder"
#         POSTGRES_HOST            = "placeholder"
#         POSTGRES_PORT            = "placeholder"
#         POSTGRES_DB              = "placeholder"
#         API_KEY                  = "placeholder"
#         SHAREPOINT_SITE_NAME     = "placeholder"
#         SHAREPOINT_NOTEBOOK_NAME = "placeholder"
#       }
#     }

#     "crewai" = {
#       name        = "crewai"
#       description = "Crew AI Secrets"

#       secrets = {
#         MODEL                     = "placeholder"
#         CONTENT_STRUCTURING_MODEL = "placeholder"
#         MARKDOWN_RENDERING_MODEL  = "placeholder"
#         EMBEDDING_MODEL           = "placeholder"
#         RERANK_MODEL              = "placeholder"
#         AWS_REGION_NAME           = "placeholder"
#         CREWAI_DISABLE_TELEMETRY  = "placeholder"
#         milvus_uri                = "placeholder"
#         milvus_token              = "placeholder"
#         milvus_collection_name    = "placeholder"
#         APP_ENV                   = "placeholder"
#         JWT_SECRET_KEY            = "placeholder"
#         RERANK_THRESHOLD          = "placeholder"
#         DATABASE_URL              = "placeholder"
#       }
#     }

#     "training-agent" = {
#       name        = "training-agent"
#       description = "Training Agent Secrets"

#       secrets = {
#         DATABASE_URL                = "placeholder"
#         SECRET_KEY                  = "placeholder"
#         ALGORITHM                   = "placeholder"
#         ACCESS_TOKEN_EXPIRE_MINUTES = "placeholder"
#         PORT                        = "placeholder"
#       }
#     }
#   }

#   name                    = each.value.name
#   description             = each.value.description
#   recovery_window_in_days = 0

#   create_policy          = true
#   block_public_policy    = true
#   ignore_secret_changes  = true
#   enable_rotation        = false
#   create_random_password = false
#   # random_password_length = 10

#   # policy_statements = {
#   #   read = {
#   #     sid = "AllowECSTasksToReadSecret"
#   #     principals = [{
#   #       type = "AWS"
#   #       identifiers = [
#   #         for app in var.ecs_apps : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${app.name}-tasks-role"
#   #       ]
#   #     }]
#   #     actions   = ["secretsmanager:GetSecretValue"]
#   #     resources = ["*"]
#   #   }
#   # }

#   policy_statements = {
#     read = {
#       sid = "AllowECSTasksToReadSecret"
#       principals = [{
#         type = "AWS"
#         identifiers = flatten([
#           for app in var.ecs_apps : [
#             "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${app.name}-tasks-role",
#             "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${app.name}-role-execution"
#           ]
#         ])
#       }]
#       actions   = ["secretsmanager:GetSecretValue"]
#       resources = ["*"]
#     }
#   }

#   secret_string = jsonencode(
#     each.value.secrets
#   )

#   tags = merge(
#     var.tags,
#     {
#       Name = each.key
#     }
#   )
# }

module "secrets" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  // Create one secret resource per application that has secrets defined
  for_each = {
    for app_name, app in var.ecs_apps :
    app_name => app
    if length(app.secret_names) > 0
  }

  name                    = each.key
  description             = "${title(each.key)} Secrets"
  recovery_window_in_days = 0

  create_policy          = true
  block_public_policy    = true
  ignore_secret_changes  = true
  enable_rotation        = false
  create_random_password = false

  // Only allow the app's specific roles to access its secrets
  policy_statements = {
    read = {
      sid = "AllowECSTasksToReadSecret"
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.key}-tasks-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.key}-role-execution"
        ]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  // Create the secret with placeholder values for each secret name
  secret_string = jsonencode({
    for secret_name in each.value.secret_names :
    secret_name => "placeholder"
  })

  tags = merge(
    var.tags,
    {
      Name = each.key
    }
  )
}
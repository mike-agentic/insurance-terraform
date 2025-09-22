locals {
  // Map app secret names to properly formatted ECS secret objects
  ecs_secrets = {
    for app_name, app in var.ecs_apps :
    app_name => [
      for secret_name in app.secret_names : {
        name      = secret_name
        valueFrom = "${module.secrets[app_name].secret_arn}:${secret_name}::"
      }
    ] if contains(keys(module.secrets), app_name)
  }

}
variable "base_region" {
  description = "The base region to use for the provider"
  type        = string

  default = "ap-southeast-6"
}

variable "prefix" {
  description = "The prefix to use for resource names"
  type        = string

  default = "insurance"
}

variable "environment" {
  description = "The environment name"
  type        = string

  default = "production"
}

variable "tags" {
  description = "The tags to apply to all resources"
  type        = map(string)

  default = {
    Workload    = "Insurance"
    Version     = "1.0.0"
    Environment = "production"
  }
}

variable "domain_name" {
  description = "The domain name for the ACM certificate"
  type        = string
}

# variable "cloudfront_alternative_names" {
#   description = "List of additional SANs for the CloudFront ACM certificate"
#   type        = list(string)
#   default     = []
# }

# variable "alb_alternative_names" {
#   description = "List of additional SANs for the ALB ACM certificate"
#   type        = list(string)
#   default     = []
# }

variable "ecs_apps" {
  description = "The ECS applications to create"
  type = map(object({
    name                               = string
    container_image                    = string
    protocol                           = optional(string, "HTTP")
    path                               = optional(string, null)
    task_definition_name               = optional(string, null)
    service_name                       = optional(string, null)
    service_port                       = optional(number, 80)
    cpu                                = optional(number, 256)
    memory                             = optional(number, 512)
    desired_count                      = optional(number, 2)
    autoscaling_min_capacity           = optional(number, 1)
    autoscaling_max_capacity           = optional(number, 10)
    scale_in_cooldown                  = optional(number, 60)
    scale_out_cooldown                 = optional(number, 60)
    cpu_target_value                   = optional(number, 75)
    memory_target_value                = optional(number, 80)
    deployment_minimum_healthy_percent = optional(number, 100)
    readonlyRootFilesystem             = optional(bool, false)
    enable_cloudwatch_logging          = optional(bool, true)
    enable_autoscaling                 = optional(bool, true)

    // Add a simplified list of secret names
    secret_names = optional(list(string), [])

    environment = optional(list(
      object(
        {
          name  = optional(string)
          value = optional(string)
        }
      )
    ), [])

    secrets = optional(list(
      object(
        {
          name      = optional(string)
          valueFrom = optional(string)
        }
      )
    ), [])
  }))

  default = {}

}
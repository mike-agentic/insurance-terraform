module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.0.5"

  cluster_name = "${var.prefix}-ECSCluster-${var.environment}"

  default_capacity_provider_strategy = {}

  create_cloudwatch_log_group = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-ECSCluster-${var.environment}"
    }
  )
}

module "service" {
  for_each = var.ecs_apps
  version  = "~> 6.0.5"

  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = each.value.service_name
  family      = each.value.task_definition_name
  cluster_arn = module.ecs.cluster_arn

  task_exec_iam_role_name = "${each.value.name}-role-execution"
  tasks_iam_role_name     = "${each.value.name}-tasks-role"

  security_group_name = "${each.value.name}-service-${var.environment}-sg"

  cpu                                = each.value.cpu
  memory                             = each.value.memory
  desired_count                      = each.value.desired_count
  autoscaling_min_capacity           = each.value.autoscaling_min_capacity
  autoscaling_max_capacity           = each.value.autoscaling_max_capacity
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent

  enable_execute_command             = true
  create_security_group              = true
  security_group_use_name_prefix     = false
  task_exec_iam_role_use_name_prefix = false
  tasks_iam_role_use_name_prefix     = false
  enable_autoscaling                 = each.value.enable_autoscaling

  autoscaling_policies = {
    cpu = {
      name        = "ecs-plc-${each.value.name}-cpu"
      policy_type = "TargetTrackingScaling"

      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }

        scale_in_cooldown  = each.value.scale_in_cooldown
        scale_out_cooldown = each.value.scale_out_cooldown
        target_value       = each.value.cpu_target_value
      }
    }
  }

  container_definitions = {
    "${each.value.name}" = {
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true
      image     = each.value.container_image

      readonlyRootFilesystem = each.value.readonlyRootFilesystem

      linuxParameters = {
        initProcessEnabled = true
      }

      portMappings = [
        {
          name          = each.value.name
          containerPort = each.value.service_port
          hostPort      = each.value.service_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      enable_cloudwatch_logging = each.value.enable_cloudwatch_logging

      # secrets     = each.value.secrets
      secrets     = lookup(local.ecs_secrets, each.key, [])
      environment = each.value.environment
    }

  }

  # service_connect_configuration = {
  #   namespace_name = aws_service_discovery_http_namespace.main[each.value.cluster_name].name

  #   dns_config = {
  #     namespace_id   = aws_service_discovery_http_namespace.main[each.value.cluster_name].id
  #     routing_policy = "MULTIVALUE"
  #   }

  #   service = {
  #     discovery_name        = each.value.name
  #     container_name        = each.value.name
  #     container_port        = each.value.service_port
  #     ingress_port_override = null

  #     client_alias = {
  #       dns_name = null
  #       port     = each.value.service_port
  #     }

  #     port_name = each.value.name
  #   }
  # }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["tg-${each.value.name}"].arn
      container_name   = each.value.name
      container_port   = each.value.service_port
    }
  }

  # load_balancer = each.value.name == "agenticai-api" ? {
  #   service = {
  #     target_group_arn = module.alb.target_groups["tg-${each.value.name}"].arn
  #     container_name   = each.value.name
  #     container_port   = each.value.service_port
  #   }
  # } : {}

  security_group_ingress_rules = {
    allow-http = {
      description                  = "Inbound traffic from load balancer"
      from_port                    = each.value.service_port
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tasks_iam_role_statements = [
    {
      sid = "AllowBedrock"
      actions = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
      ]
      resources = ["*"]
    }
  ]


  subnet_ids = module.vpc.private_subnets
  # security_group_ids = [module.security_groups_ecs.security_group_id]

  depends_on = [
    module.ecs
  ]

  tags = merge(
    var.tags,
    {
      Name = each.value.service_name
    }
  )
}

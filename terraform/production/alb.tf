module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.17.0"

  name                       = "${var.prefix}-${var.environment}-alb"
  security_group_name        = "${var.prefix}-${var.environment}-private-alb-sg"
  security_group_description = "Security Group for ALB"
  load_balancer_type         = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    # http = {
    #   from_port      = 80
    #   to_port        = 80
    #   ip_protocol    = "tcp"
    #   cidr_ipv4      = "0.0.0.0/0"
    #   description    = "Allow HTTP traffic from anywhere"
    # }

    https = {
      from_port      = 443
      to_port        = 443
      ip_protocol    = "tcp"
      prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
      description    = "OnlyAllowHttpsFromCloudFront"
    }

    # api_tcp = {
    #   from_port   = 52000
    #   to_port     = 52005
    #   ip_protocol = "tcp"
    #   description = "OnlyAllowApiTcpFromCloudFront"
    #   prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
    # }

    # api_udp = {
    #   from_port   = 52000
    #   to_port     = 52005
    #   ip_protocol = "udp"
    #   description = "OnlyAllowApiUdpFromCloudFront"
    #   prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
    # }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    # http-listener = {
    #   port     = 80
    #   protocol = "HTTP"

    #   # forward = {
    #   #   target_group_key = "tg-agenticai-api"
    #   # }

    #   redirect = {
    #     port        = "443"
    #     protocol    = "HTTPS"
    #     status_code = "HTTP_301"
    #   }
    # }

    https-listener = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = module.acm_load_balancer.acm_certificate_arn #arn:aws:acm:ap-southeast-6:432629721957:certificate/55da3264-6962-4eea-9167-054ba5e2671d

      forward = {
        target_group_key = "tg-backend"
      }

      rules = [
        {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "tg-backend"
            }
          ]
          conditions = [
            {
              host_header = {
                values = ["insurance-backend.${var.domain_name}"]
              }
            }
          ]
        },
        {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_key = "tg-nova-sync"
            }
          ]
          conditions = [
            {
              host_header = {
                values = ["insurance-sync.${var.domain_name}"]
              }
            }
          ]
        },
        {
          priority = 3
          actions = [
            {
              type             = "forward"
              target_group_key = "tg-edge-mcp-app"
            }
          ]
          conditions = [
            {
              host_header = {
                values = ["insurance-mcp.${var.domain_name}"]
              }
            }
          ]
        },
        {
          priority = 4
          actions = [
            {
              type             = "forward"
              target_group_key = "tg-outlook-mail-agent"
            }
          ]
          conditions = [
            {
              host_header = {
                values = ["insurance-outlook.${var.domain_name}"]
              }
            }
          ]
        }
      ]

      # rules = [
      #   {
      #     priority = 1
      #     actions = [
      #       {
      #         type             = "forward"
      #         target_group_key = "tg-crewai"
      #       }
      #     ]
      #     conditions = [
      #       {
      #         path_pattern = {
      #           values = ["/crewai*"]
      #         }
      #       }
      #     ]
      #   },
      #   {
      #     priority = 2
      #     actions = [
      #       {
      #         type             = "forward"
      #         target_group_key = "tg-training-agent"
      #       }
      #     ]
      #     conditions = [
      #       {
      #         path_pattern = {
      #           values = ["/training-agent*"]
      #         }
      #       }
      #     ]
      #   }
      # ]
    }
  }

  target_groups = merge([
    for app_name, app in var.ecs_apps : {
      "tg-${app_name}" = {
        name        = "tg-${app_name}"
        protocol    = "HTTP"
        port        = app.service_port
        target_type = "ip"

        health_check = {
          enabled             = true
          healthy_threshold   = 5
          interval            = 30
          matcher             = "200"
          path                = app.path
          port                = app.service_port
          protocol            = "HTTP"
          timeout             = 10
          unhealthy_threshold = 2
        }

        create_attachment = false
      }
    } if app.path != null
  ]...)

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.environment}-private-alb-sg"
    }
  )
}
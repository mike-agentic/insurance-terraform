module "vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0.1"

  vpc_id = module.vpc.vpc_id

  create_security_group = true
  security_group_name   = "${var.prefix}-${var.environment}-vpc-endpoints-sg"
  # security_group_name_prefix = false
  security_group_description = "VPC endpoint security group"

  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = true

      route_table_ids = flatten([
        module.vpc.public_route_table_ids,
        module.vpc.private_route_table_ids,
        module.vpc.intra_route_table_ids
      ])

      tags = merge(var.tags, {
        Name = "s3-vpc-endpoint"
      })
    }

    # ssmmessages = {
    #   service             = "ssmmessages" # ec2messages #ssm
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.private_subnets

    #   tags = {
    #     Name = "vpce-snet-private-to-ssmmessages"
    #   }
    # }

    # ec2messages = {
    #   service             = "ec2messages" #  #ssm
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.private_subnets

    #   tags = {
    #     Name = "vpce-snet-private-to-ec2messages"
    #   }
    # }

    # ssm = {
    #   service             = "ssm" #  #ssm
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.private_subnets

    #   tags = {
    #     Name = "vpce-snet-private-to-ssm"
    #   }
    # }

    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets

      tags = merge(var.tags, {
        Name = "ecr-vpc-endpoint"
      })
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets

      tags = merge(var.tags, {
        Name = "ecr-dkr-vpc-endpoint"
      })
    }

# Bedrock VPC Endpoints removed due to cross-region limitation:
    # VPC is in ap-southeast-6 but Bedrock is only available in ap-southeast-2
    # Applications will access Bedrock APIs through NAT Gateway
  }
}
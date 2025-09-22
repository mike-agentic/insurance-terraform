module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0.1"

  name = "${var.prefix}-${var.environment}-vpc"
  cidr = "10.1.0.0/16"

  azs = [
    "ap-southeast-6a",
    "ap-southeast-6b",
    "ap-southeast-6c"
  ]

  public_subnets = [
    "10.1.0.0/20",
    "10.1.16.0/20",
    "10.1.32.0/20"
  ]

  private_subnets = [
    "10.1.64.0/20",
    "10.1.80.0/20",
    "10.1.96.0/20"
  ]

  intra_subnets = [
    "10.1.128.0/20",
    "10.1.144.0/20",
    "10.1.160.0/20"
  ]

  public_subnet_names = [
    "${var.prefix}-${var.environment}-public-sn-a",
    "${var.prefix}-${var.environment}-public-sn-b",
    "${var.prefix}-${var.environment}-public-sn-c"
  ]

  private_subnet_names = [
    "${var.prefix}-${var.environment}-private-app-sn-a",
    "${var.prefix}-${var.environment}-private-app-sn-b",
    "${var.prefix}-${var.environment}-private-app-sn-c"
  ]

  intra_subnet_names = [
    "${var.prefix}-${var.environment}-private-data-sn-a",
    "${var.prefix}-${var.environment}-private-data-sn-b",
    "${var.prefix}-${var.environment}-private-data-sn-c"
  ]

  igw_tags = {
    Name = "${var.prefix}-${var.environment}-igw"
  }

  nat_gateway_tags = {
    Name = "${var.prefix}-${var.environment}-ngw"
  }

  public_route_table_tags = {
    Name = "${var.prefix}-${var.environment}-public-rt"
  }

  private_route_table_tags = {
    Name = "${var.prefix}-${var.environment}-private-app-rt"
  }

  intra_route_table_tags = {
    Name = "${var.prefix}-${var.environment}-private-data-rt"
  }

  public_acl_tags = {
    Name = "${var.prefix}-${var.environment}-public-nacl"
  }

  private_acl_tags = {
    Name = "${var.prefix}-${var.environment}-private-app-nacl"
  }

  intra_acl_tags = {
    Name = "${var.prefix}-${var.environment}-private-data-nacl"
  }

  public_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  intra_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "deny"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "10.1.0.0/18"
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  intra_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "deny"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "10.1.0.0/18"
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  enable_nat_gateway            = true
  single_nat_gateway            = true
  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
  intra_dedicated_network_acl   = true

  manage_default_network_acl    = false
  manage_default_route_table    = false
  create_database_subnet_group  = false
  manage_default_security_group = false

  # # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  flow_log_file_format      = "plain-text"
  flow_log_destination_type = "s3"
  enable_flow_log           = true
  flow_log_destination_arn  = aws_s3_bucket.vpc_flow_logs.arn

  tags = var.tags
}
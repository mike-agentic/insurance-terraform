module "postgres_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.0"

  name        = "${var.prefix}-${var.environment}-rds-sg"
  description = "Permits network communication over the ports and protocols required for RDS instance."
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    for cidr in module.vpc.private_subnets_cidr_blocks : {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from private subnet ${cidr}"
      cidr_blocks = cidr
    }
  ]

  # egress
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.environment}-rds-sg"
    }
  )
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.12.0"

  identifier = "${var.prefix}-${var.environment}-db"

  apply_immediately = true

  engine               = "postgres"
  engine_version       = "16.8"
  family               = "postgres16" # DB parameter group
  major_engine_version = "16"         # DB option group
  instance_class       = "db.m6g.large"
  storage_type         = "gp3"

  allocated_storage     = 20
  max_allocated_storage = 200

  db_name  = "postgres"
  username = "postgres"
  port     = 5432

  multi_az               = true
  publicly_accessible    = false
  create_db_subnet_group = true

  subnet_ids = module.vpc.intra_subnets

  vpc_security_group_ids = [module.postgres_security_group.security_group_id]

  maintenance_window = "Sat:17:00-Sat:18:00"
  backup_window      = "16:00-17:00"

  # enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  # create_cloudwatch_log_group     = true

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${var.prefix}-${var.environment}-db-monitoring-role"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Role for RDS monitoring"

  # blue_green_update = {
  #   enabled = true
  # }

  # parameters = [
  #   # required for blue-green deployment
  #   {
  #     name         = "rds.logical_replication"
  #     value        = 1
  #     apply_method = "pending-reboot"
  #   }
  # ]

  db_instance_tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.environment}-db"
    }
  )
}
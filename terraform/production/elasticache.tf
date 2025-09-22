# ElastiCache Redis Security Group
module "redis_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.0"

  name        = "${var.prefix}-${var.environment}-redis-sg"
  description = "Security Group for ElastiCache Redis"
  vpc_id      = module.vpc.vpc_id

  # Allow Redis access from private app subnets
  ingress_with_cidr_blocks = [
    for cidr in module.vpc.private_subnets_cidr_blocks : {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      description = "Redis access from private app subnet ${cidr}"
      cidr_blocks = cidr
    }
  ]

  # Allow all outbound traffic
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.environment}-redis-sg"
    }
  )
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.prefix}-${var.environment}-redis-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.environment}-redis-subnet-group"
    }
  )
}

# ElastiCache Redis Cluster - Production optimized
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.prefix}-${var.environment}-redis"
  description          = "Redis cluster for insurance application - Production"

  # Redis configuration - Production sizing
  node_type            = "cache.t3.small"
  port                 = 6379
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"

  # High Availability configuration - Production setup
  num_cache_clusters         = 3
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [module.redis_security_group.security_group_id]

  # Backup and maintenance - Production schedule
  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_update_strategy = "SET"

  # Management
  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.environment}-redis"
    }
  )
}

# Output Redis endpoint for applications
output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

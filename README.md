# Insurance Platform AWS Infrastructure

This repository contains Terraform code to deploy and manage an AWS infrastructure environment for the Insurance Platform. It includes configurations for services like CloudFront, WAF, ALB, ECS Fargate, ECR, ACM, RDS PostgreSQL, Amazon ElastiCache for Redis, and VPC Endpoints.

### Multi-Account Setup
- **Management Account** (`183631338318`): Hosts dependency resources and IAM roles for authentication
- **Shared Account** (`448734340304`): Hosts shared ECR and Route 53 resources
- **Development Account** (`432629721957`): Hosts application-specific resources
- **Production Account** (`792172459077`): Hosts application-specific resources


The deployment pipeline is managed using **GitHub Actions** with OIDC authentication.

## Architecture Overview

### Regional Strategy
- **Primary Region**: `ap-southeast-6` (Auckland, New Zealand) for optimal performance to New Zealand users
- **Cross-Region Services**: AWS Bedrock services accessed via NAT Gateway from `ap-southeast-2` (Sydney) due to service availability limitations
- **DNS & CDN**: Route53 and CloudFront distributions managed from appropriate regions

### Application Stack
The Insurance Platform consists of:

**Backend Applications (4)**:
- **backend** (`port 8001`): Main API service for insurance operations
- **nova-sync** (`port 8002`): Document processing and synchronization service  
- **edge-mcp-app** (`port 8003`): External API integration service (requires fixed egress IP)
- **outlook-mail-agent** (`port 8004`): Email processing service (requires fixed egress IP)

**Frontend Application (1)**:
- **frontend**: React-based web interface served via S3 and CloudFront

**Data Services**:
- **PostgreSQL**: Primary database (RDS)
- **Redis**: Caching and session management (ElastiCache)
- **S3**: File storage and static asset hosting

### Network Architecture
- **VPC**: Multi-tier architecture with public, private app, and private data subnets
- **NAT Gateway**: Single NAT Gateway providing fixed egress IP for external API access
- **VPC Endpoints**: Private connectivity to AWS services (S3, ECR) - Bedrock accessed via NAT Gateway
- **ALB**: Application Load Balancer with SSL termination and host-based routing

## Pipeline Workflow

The general workflow for each environment includes the following steps:

1. **Terraform Init**: Initializes the Terraform working directory, downloads modules, and sets up the backend.
2. **Terraform Plan**: Previews the infrastructure changes to be applied.
3. **Terraform Apply**: Applies the changes to the AWS infrastructure (manual approval can be configured if needed).

## Workflow Files

The following workflows are included in this repository:

- **`tf-shared.yml`**: Manages the `shareed` account baseline.
- **`tf-development.yml`**: Manages the `development` account baseline.
- **`tf-production.yml`**: Manages the `production` account baseline.

Each workflow ensures that the necessary IAM roles are assumed and the appropriate Terraform commands are executed for the targeted environment. For more details, refer to the respective workflow files in the `.github/workflows/` directory.

## Authentication

The Pipeline authenticates with the Management Account using the following IAM roles:

1. **iam-role-github-aws-agenticai-oidc-assume**: This role is used to assume the necessary permissions via OIDC for the github pipeline to interact with AWS.
    - **Restriction**: This role is restricted to specific repositories, as defined in the trust relationship of the role. Currently, only repositories matching the pattern `["repo:Agenticai-Limited/flexr-terraform:*"` are allowed.

    - This IAM role is **NOT** managed by Terraform and can be modified manually.

2. **iam-role-github-aws-agenticai-execution**: This role is used to execute the Terraform commands and apply the infrastructure changes.

## Terraform State

The Terraform state is stored in the S3 bucket `s3-dependency-terraform-state-all-apse6` in the **Management Account** (ap-southeast-6 region). This ensures that the state is managed and shared across different environments.

## Configuration Management for ECS Clusters and Applications

The infrastructure for ECS clusters and applications is designed to allow flexibility for environment-specific configurations while maintaining a consistent structure for core resources.

### Environment-Specific Configurations

You can modify or update environment-specific configurations, such as ECS cluster and application settings, by editing the `terraform.tfvars` file. This includes parameters like:

- ECS cluster names and namespaces
- Application-specific settings (e.g., container image, CPU, memory, ports, secrets, etc.)
- Autoscaling configurations

Example:
```terraform
ecs_apps = {
  backend = {
    name                 = "backend"
    task_definition_name = "ecs-td-backend"
    service_name         = "ecs-srv-backend"
    container_image      = "448734340304.dkr.ecr.ap-southeast-6.amazonaws.com/insurance-backend:latest"
    service_port         = 8001
    cpu                  = 512
    memory               = 1024
    desired_count        = 2
    path                 = "/health"

    secret_names = [
      # Database Configuration
      "DATABASE_URL",
      # AWS Configuration
      "AWS_REGION_NAME",
      "S3_BUCKET_NAME",
      "S3_FROEND_UPLOAD_FILE",
      # Microsoft Graph Configuration
      "MS_CLIENT_ID",
      "MS_CLIENT_SECRET",
      "MS_USER_EMAIL",
      # SharePoint Configuration
      "SHAREPOINT_SITE_NAME",
      "SHAREPOINT_NOTEBOOK_NAME",
      # LLM Configuration
      "CLAUDE_SONNET_MODEL_ID",
      "CLAUDE_HAIKU_MODEL_ID",
      "BEDROCK_REGION",
      # Other application secrets...
    ]
  }
  
  nova-sync = {
    name                 = "nova-sync"
    task_definition_name = "ecs-td-nova-sync"
    service_name         = "ecs-srv-nova-sync"
    container_image      = "448734340304.dkr.ecr.ap-southeast-6.amazonaws.com/insurance-nova-sync:latest"
    service_port         = 8002
    cpu                  = 512
    memory               = 1024
    desired_count        = 1
    path                 = "/health"

    secret_names = [
      "DATABASE_URL",
      "BEDROCK_REGION",
      "DEFAULT_LLM_MODEL",
      # Additional nova-sync specific secrets...
    ]
  }
  
  # Additional applications: edge-mcp-app, outlook-mail-agent, etc.
}
```

## CloudFront Aliases

The following table lists the CloudFront distribution domain names and their associated DNS aliases for each environment.

| Environment | CloudFront Distribution | Aliases                                                                                           | CloudFront Domain Name                |
|-------------|------------------------|---------------------------------------------------------------------------------------------------|---------------------------------------|
| **DEV**     | frontend               | insurance-demo.dev.agenticai.co.nz                                                                | TBD (will be generated)               |
| **DEV**     | backend                | insurance-backend.dev.agenticai.co.nz,<br>insurance-sync.dev.agenticai.co.nz,<br>insurance-mcp.dev.agenticai.co.nz,<br>insurance-outlook.dev.agenticai.co.nz | TBD (will be generated)               |
| **PROD**    | frontend               | insurance-demo.agenticai.co.nz                                                                     | TBD (will be generated)               |
| **PROD**    | backend                | insurance-backend.agenticai.co.nz,<br>insurance-sync.agenticai.co.nz,<br>insurance-mcp.agenticai.co.nz,<br>insurance-outlook.agenticai.co.nz | TBD (will be generated)               |


### Structural Configurations

Structural configurations that are critical to the overall design and architecture are defined in specific `.tf` files. These configurations are not intended to be modified frequently and are aligned with the design document.

Examples include:

- CloudFront Configuration: Defined in `cloudfront.tf` for managing CloudFront destribution and settings.
- ECS: Defined in `ecs.tf` for managing ECS settings.
- Load Balancers: Defined in `alb.tf` for managing application load balancers.

These `.tf` files ensure that the infrastructure adheres to the design document and maintain consistency across environments.

### Best Practices

- Use `terraform.tfvars` for environment-specific updates to avoid altering the core infrastructure logic.
- Modify `.tf` files only when structural changes are required, and ensure they align with the design document.
- Review changes to `.tf` files carefully, as they may impact multiple environments.

By following this approach, you can maintain a balance between flexibility for environment-specific needs and consistency with the overall infrastructure design.

## 🚀 Deployment Guide

### Prerequisites
1. **AWS Provider Version**: Ensure Terraform AWS Provider `>= 6.14.0` for `ap-southeast-6` region support
2. **AWS Credentials**: Proper OIDC/IAM role configuration for cross-account access
3. **Backend State**: S3 backend state bucket `s3-dependency-terraform-state-all-apse6` in Management Account

### Deployment Order
Deploy environments in the following sequence:

1. **Shared Environment** (`terraform/shared/`)
   ```bash
   cd terraform/shared
   terraform init
   terraform plan -var-file=terraform.tfvars
   terraform apply -var-file=terraform.tfvars
   ```

2. **Development Environment** (`terraform/development/`)
   ```bash
   cd terraform/development
   terraform init
   terraform plan -var-file=terraform.tfvars
   terraform apply -var-file=terraform.tfvars
   ```

3. **Production Environment** (`terraform/production/`)
   ```bash
   cd terraform/production
   terraform init
   terraform plan -var-file=terraform.tfvars
   terraform apply -var-file=terraform.tfvars
   ```

### Important Notes
- **Always use `-var-file=terraform.tfvars`** to ensure correct environment-specific configuration
- **Fixed Egress IP**: Applications requiring external API access (`edge-mcp-app`, `outlook-mail-agent`) will use the NAT Gateway's fixed Elastic IP
- **Bedrock Access**: Due to regional limitations, Bedrock APIs are accessed via NAT Gateway with minimal additional cost (~$0.014/month for typical usage)
- **Cross-Region Considerations**: 
  - VPC and applications in `ap-southeast-6` (New Zealand)
  - Bedrock services accessed from `ap-southeast-2` (Sydney) 
  - ACM certificates for CloudFront in `us-east-1`

### Security Configuration
- **Secrets Management**: All sensitive configuration stored in AWS Secrets Manager
- **IAM Roles**: Applications use IAM roles instead of hardcoded AWS access keys
- **VPC Security**: Private subnets with controlled outbound access via NAT Gateway
- **SSL/TLS**: End-to-end encryption with ACM certificates

## 📝 Contributing

1. Create feature branch from `main`
2. Make changes and test in non-production environment
3. Update documentation as needed
4. Submit pull request with detailed description
5. Ensure peer review before merging

## 🔧 Troubleshooting

### Common Issues
1. **Region Support Error**: Upgrade AWS Provider to `>= 6.14.0`
2. **Backend Access**: Verify S3 bucket and DynamoDB table exist in Management Account
3. **IAM Permissions**: Check OIDC role trust relationships and execution role permissions
4. **Variable Defaults**: Ensure `terraform/production/variables.tf` defaults to "production" environment
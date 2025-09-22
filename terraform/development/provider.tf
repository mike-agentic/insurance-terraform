terraform {
  # required_version = "~> 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14.0"
    }
  }
}

data "aws_regions" "current" {}
data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.base_region
  assume_role {
    role_arn     = "arn:aws:iam::432629721957:role/iam-role-github-aws-agenticai-execution"
    session_name = "terraform"
  }
}

provider "aws" {
  alias  = "global"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::432629721957:role/iam-role-github-aws-agenticai-execution"
    session_name = "terraform"
  }
}

provider "aws" {
  alias  = "shared"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::448734340304:role/iam-role-github-aws-agenticai-execution"
    session_name = "terraform"
  }
}

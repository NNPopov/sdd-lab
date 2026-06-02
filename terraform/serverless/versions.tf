# ============================================================
# fastapi-demo (serverless) — provider + base data sources
# Region: us-east-1
# Fully self-contained stack: ECS Fargate + RDS + ElastiCache
# + ALB + S3/CloudFront. No EKS / no kubectl.
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ============================================================
# VARIABLES — serverless stack
# Namespaced as "fastapi-demo-sl" so it never collides with the
# EKS stack (separate ECR, separate everything).
# ============================================================

variable "project_name" {
  description = "Prefix for all AWS resources (kept distinct from the EKS stack)"
  type        = string
  default     = "fastapi-demo-sl"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID — find it with: aws sts get-caller-identity"
  type        = string
  default     = "017091936354"
}

variable "common_tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Project     = "fastapi-demo-sl"
    Environment = "learn"
    ManagedBy   = "terraform"
    Stack       = "serverless"
  }
}

# ---------- Compute (ECS Fargate) ----------
variable "container_cpu" {
  description = "Fargate task CPU units (256 = .25 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Number of running API tasks. Set to 0 to pause compute billing."
  type        = number
  default     = 1
}

variable "image_tag" {
  description = "ECR image tag the task definition points at (CD re-registers with the deployed tag)"
  type        = string
  default     = "latest"
}

# ---------- Database (RDS Postgres) ----------
variable "db_username" {
  description = "Master username for RDS Postgres (injected into the app as POSTGRES_USER)"
  type        = string
  default     = "dbadmin"
}

variable "db_name" {
  description = "Initial database name (injected as POSTGRES_DB)"
  type        = string
  default     = "appdb"
}

variable "db_instance_class" {
  description = "RDS instance class (Free Tier eligible)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB"
  type        = number
  default     = 20
}

# ---------- Cache (ElastiCache Redis) ----------
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

# ---------- Application admin ----------
variable "admin_username" {
  description = "Bootstrap admin username"
  type        = string
  default     = "admin"
}

variable "admin_email" {
  description = "Bootstrap admin email"
  type        = string
  default     = "admin@example.com"
}

variable "admin_password" {
  description = "Bootstrap admin password (stored in SSM as a SecureString)"
  type        = string
  default     = "ChangeMe!Admin123"
  sensitive   = true
}

variable "project_name" {
  description = "Prefix for all AWS resources"
  type        = string
  default     = "fastapi-demo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID — find it with aws sts get-caller-identity"
  type        = string
  default     = "017091936354"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.small"
}

variable "common_tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Project     = "fastapi-demo"
    Environment = "learn"
    ManagedBy   = "terraform"
  }
}

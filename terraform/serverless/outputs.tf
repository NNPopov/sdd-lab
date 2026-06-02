# ============================================================
# OUTPUTS — printed after `terraform apply`. Used by the deploy
# scripts and cd-serverless.yml.
# ============================================================

output "cloudfront_domain" {
  description = "Public HTTPS URL of the app (Flutter + /api/v1)"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.this.id
}

output "alb_dns_name" {
  description = "ALB DNS name (internal origin behind CloudFront)"
  value       = aws_lb.this.dns_name
}

output "ecr_backend_url" {
  description = "ECR repository URL for backend images"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS API service name"
  value       = aws_ecs_service.api.name
}

output "ecs_task_family" {
  description = "ECS task definition family (used by run-task for migrations)"
  value       = aws_ecs_task_definition.api.family
}

output "s3_web_bucket" {
  description = "S3 bucket that hosts the Flutter web bundle"
  value       = aws_s3_bucket.web.bucket
}

output "rds_endpoint" {
  description = "RDS Postgres endpoint"
  value       = aws_db_instance.this.address
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "ecr_login_command" {
  description = "Command for docker login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.backend.repository_url}"
}

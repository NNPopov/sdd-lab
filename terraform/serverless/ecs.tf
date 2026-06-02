# ============================================================
# ECS Fargate — cluster, log group, task definition, service.
#
# The same task definition is reused for one-shot jobs (migrations)
# via `aws ecs run-task` with a containerOverrides command — see
# cd-serverless.yml. Container name is "api" everywhere.
# ============================================================

locals {
  container_name = "api"
  ecr_image      = "${aws_ecr_repository.backend.repository_url}:${var.image_tag}"

  # Non-secret runtime configuration. Endpoints come straight from
  # the RDS / ElastiCache resources Terraform manages.
  app_environment = [
    { name = "POSTGRES_SERVER", value = aws_db_instance.this.address },
    { name = "POSTGRES_PORT", value = "5432" },
    { name = "POSTGRES_USER", value = var.db_username },
    { name = "POSTGRES_DB", value = var.db_name },
    { name = "POSTGRES_ASYNC_PREFIX", value = "postgresql+asyncpg://" },
    { name = "POSTGRES_SYNC_PREFIX", value = "postgresql://" },

    { name = "REDIS_CACHE_HOST", value = aws_elasticache_cluster.this.cache_nodes[0].address },
    { name = "REDIS_CACHE_PORT", value = "6379" },
    { name = "REDIS_QUEUE_HOST", value = aws_elasticache_cluster.this.cache_nodes[0].address },
    { name = "REDIS_QUEUE_PORT", value = "6379" },
    { name = "REDIS_RATE_LIMIT_HOST", value = aws_elasticache_cluster.this.cache_nodes[0].address },
    { name = "REDIS_RATE_LIMIT_PORT", value = "6379" },

    { name = "ALGORITHM", value = "HS256" },
    { name = "ACCESS_TOKEN_EXPIRE_MINUTES", value = "60" },

    { name = "ADMIN_NAME", value = var.admin_username },
    { name = "ADMIN_EMAIL", value = var.admin_email },
    { name = "ADMIN_USERNAME", value = var.admin_username },

    { name = "APP_NAME", value = "FastAPI Demo (serverless)" },
    { name = "APP_DESCRIPTION", value = "Serverless deployment stack" },
    { name = "APP_VERSION", value = "0.1" },

    { name = "CORS_ORIGINS", value = "[\"*\"]" },
    { name = "CORS_METHODS", value = "[\"*\"]" },
    { name = "CORS_HEADERS", value = "[\"*\"]" },

    { name = "CLIENT_CACHE_MAX_AGE", value = "60" },
    { name = "ENVIRONMENT", value = "production" },
    { name = "CRUD_ADMIN_ENABLED", value = "false" },
  ]

  # Secret values pulled from SSM by the execution role.
  app_secrets = [
    { name = "POSTGRES_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
    { name = "SECRET_KEY", valueFrom = aws_ssm_parameter.secret_key.arn },
    { name = "ADMIN_PASSWORD", valueFrom = aws_ssm_parameter.admin_password.arn },
  ]
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
  tags              = var.common_tags
}

# ECS task security group — only the ALB may reach port 8000.
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "ECS tasks: ingress from ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "App port from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name        = local.container_name
      image       = local.ecr_image
      essential   = true
      environment = local.app_environment
      secrets     = local.app_secrets
      portMappings = [
        { containerPort = 8000, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])

  tags = var.common_tags
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = local.container_name
    container_port   = 8000
  }

  # CD re-registers the task definition with the deployed image tag,
  # so ignore Terraform-side drift on the task definition revision.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.http]

  tags = var.common_tags
}

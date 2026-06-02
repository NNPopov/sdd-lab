# ============================================================
# RDS PostgreSQL — db.t3.micro, single-AZ, private.
# Stop it from the console/CLI to pause compute billing (storage
# only). deletion_protection off + skip_final_snapshot for clean
# teardown on a learning stack.
# ============================================================

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db"
  subnet_ids = module.vpc.private_subnets
  tags       = var.common_tags
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS: Postgres ingress from ECS tasks only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false
  publicly_accessible    = false

  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = var.common_tags
}

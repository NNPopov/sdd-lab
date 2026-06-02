# ============================================================
# SECRETS — generated in Terraform, stored in SSM Parameter Store
# as SecureString. Only truly-secret values live here; non-secret
# config (endpoints, CORS, ...) is passed as plain ECS environment.
#
# Naming convention: /fastapi-demo-sl/{KEY}
# ============================================================
resource "random_password" "db" {
  length  = 24
  special = false # avoid characters that complicate connection strings
}

resource "random_password" "secret_key" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/POSTGRES_PASSWORD"
  type  = "SecureString"
  value = random_password.db.result
  tags  = var.common_tags
}

resource "aws_ssm_parameter" "secret_key" {
  name  = "/${var.project_name}/SECRET_KEY"
  type  = "SecureString"
  value = random_password.secret_key.result
  tags  = var.common_tags
}

resource "aws_ssm_parameter" "admin_password" {
  name  = "/${var.project_name}/ADMIN_PASSWORD"
  type  = "SecureString"
  value = var.admin_password
  tags  = var.common_tags
}

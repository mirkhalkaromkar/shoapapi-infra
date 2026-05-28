# ── SSM Parameter Store ───────────────────────────────────
# Stores all app secrets — EC2 reads these at startup
# Path pattern: /<project>/<env>/<key>

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.project}/${var.env}/db_host"
  type  = "String"
  value = var.db_host

  tags = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.project}/${var.env}/db_name"
  type  = "String"
  value = var.db_name

  tags = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.project}/${var.env}/db_username"
  type  = "String"
  value = var.db_username

  tags = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project}/${var.env}/db_password"
  type  = "SecureString"   # encrypted at rest using KMS
  value = var.db_password

  tags = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "redis_host" {
  name  = "/${var.project}/${var.env}/redis_host"
  type  = "String"
  value = var.redis_host
  tags  = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "sqs_queue_url" {
  name  = "/${var.project}/${var.env}/sqs_queue_url"
  type  = "String"
  value = var.sqs_queue_url
  tags  = { Project = var.project, Env = var.env }
}

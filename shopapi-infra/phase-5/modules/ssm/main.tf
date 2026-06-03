resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.project}/${var.env}/db_host"
  type  = "String"
  value = var.db_host
  tags  = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.project}/${var.env}/db_name"
  type  = "String"
  value = var.db_name
  tags  = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.project}/${var.env}/db_username"
  type  = "String"
  value = var.db_username
  tags  = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project}/${var.env}/db_password"
  type  = "SecureString"
  value = var.db_password
  tags  = { Project = var.project, Env = var.env }
}

resource "aws_ssm_parameter" "sqs_queue_url" {
  name  = "/${var.project}/${var.env}/sqs_queue_url"
  type  = "String"
  value = var.sqs_queue_url
  tags  = { Project = var.project, Env = var.env }
}

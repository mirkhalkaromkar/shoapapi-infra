# ── CodeDeploy Application ────────────────────────────────
resource "aws_codedeploy_app" "app" {
  name             = "${var.project}-${var.env}"
  compute_platform = "Server"
}

# ── Deployment Group ──────────────────────────────────────
resource "aws_codedeploy_deployment_group" "app" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${var.project}-${var.env}-dg"
  service_role_arn      = var.codedeploy_role_arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  # Target EC2 by tag
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Project"
      type  = "KEY_AND_VALUE"
      value = var.project
    }
    ec2_tag_filter {
      key   = "Env"
      type  = "KEY_AND_VALUE"
      value = var.env
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

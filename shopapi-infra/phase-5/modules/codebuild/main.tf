# ── S3 Artifact Bucket ────────────────────────────────────
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-${var.env}-pipeline-artifacts-${var.account_id}"
  force_destroy = true

  tags = { Project = var.project, Env = var.env }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

# ── CodeBuild Project ─────────────────────────────────────
resource "aws_codebuild_project" "app" {
  name          = "${var.project}-${var.env}-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 10

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true   # required for Docker builds

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.ecr_repo_url
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/${var.project}/${var.env}/codebuild"
      stream_name = "build"
    }
  }

  tags = { Project = var.project, Env = var.env }
}

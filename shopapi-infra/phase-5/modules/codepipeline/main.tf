# ── GitHub Connection ─────────────────────────────────────
# After terraform apply, this connection must be manually
# activated in AWS Console → Developer Tools → Connections
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project}-${var.env}-github"
  provider_type = "GitHub"
}

# ── CodePipeline ──────────────────────────────────────────
resource "aws_codepipeline" "app" {
  name     = "${var.project}-${var.env}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artifact_bucket
    type     = "S3"
  }

  # Stage 1 — Source (GitHub)
  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  # Stage 2 — Build (CodeBuild → ECR)
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  # Stage 3 — Deploy (CodeDeploy → EC2)
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = var.codedeploy_app_name
        DeploymentGroupName = var.codedeploy_deployment_group
      }
    }
  }

  tags = { Project = var.project, Env = var.env }
}

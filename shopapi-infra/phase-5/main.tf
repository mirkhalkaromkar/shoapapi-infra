terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" { region = var.aws_region }

data "aws_caller_identity" "current" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ── Phase 1-4 modules (unchanged) ─────────────────────────
module "vpc" {
  source   = "./modules/vpc"
  project  = var.project
  env      = var.env
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

module "sg" {
  source  = "./modules/sg"
  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
  env     = var.env
}

module "sqs" {
  source  = "./modules/sqs"
  project = var.project
  env     = var.env
}

module "rds" {
  source             = "./modules/rds"
  project            = var.project
  env                = var.env
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  db_sg_id           = module.sg.db_sg_id
}

module "ssm" {
  source        = "./modules/ssm"
  project       = var.project
  env           = var.env
  db_host       = module.rds.db_endpoint
  db_name       = var.db_name
  db_username   = var.db_username
  db_password   = var.db_password
  redis_host    = "127.0.0.1"
  sqs_queue_url = module.sqs.queue_url
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
  env     = var.env
}

module "cloudfront" {
  source                 = "./modules/cloudfront"
  project                = var.project
  env                    = var.env
  bucket_id              = module.s3.bucket_id
  bucket_regional_domain = module.s3.bucket_regional_domain
  oac_id                 = module.s3.oac_id
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.sg.alb_sg_id
}

module "ec2" {
  source               = "./modules/ec2"
  project              = var.project
  env                  = var.env
  ami_id               = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  public_subnet_id     = module.vpc.public_subnet_ids[0]
  app_sg_id            = module.sg.app_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  target_group_arn     = module.alb.target_group_arn
  aws_region           = var.aws_region
  project_env          = "${var.project}/${var.env}"
  depends_on           = [module.ssm]
}

module "cloudwatch" {
  source          = "./modules/cloudwatch"
  project         = var.project
  env             = var.env
  aws_region      = var.aws_region
  alert_email     = var.alert_email
  ec2_instance_id = module.ec2.instance_id
  rds_identifier  = "${var.project}-${var.env}-mysql"
  sqs_queue_name  = "${var.project}-${var.env}-product-events"
  alb_arn_suffix  = module.alb.alb_arn_suffix
}

# ── Phase 5 — CI/CD modules ───────────────────────────────
module "ecr" {
  source  = "./modules/ecr"
  project = var.project
  env     = var.env
}

module "codebuild" {
  source             = "./modules/codebuild"
  project            = var.project
  env                = var.env
  aws_region         = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
  ecr_repo_url       = module.ecr.repository_url
  codebuild_role_arn = module.iam_cicd.codebuild_role_arn
}

module "iam_cicd" {
  source              = "./modules/iam_cicd"
  project             = var.project
  env                 = var.env
  artifact_bucket_arn = module.codebuild.artifact_bucket_arn
}

module "codedeploy" {
  source               = "./modules/codedeploy"
  project              = var.project
  env                  = var.env
  codedeploy_role_arn  = module.iam_cicd.codedeploy_role_arn
}

module "codepipeline" {
  source                     = "./modules/codepipeline"
  project                    = var.project
  env                        = var.env
  codepipeline_role_arn      = module.iam_cicd.codepipeline_role_arn
  artifact_bucket            = module.codebuild.artifact_bucket
  github_repo                = var.github_repo
  github_branch              = var.github_branch
  codebuild_project_name     = module.codebuild.project_name
  codedeploy_app_name        = module.codedeploy.app_name
  codedeploy_deployment_group = module.codedeploy.deployment_group
}

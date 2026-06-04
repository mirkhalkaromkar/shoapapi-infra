terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" { region = var.aws_region }

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

resource "random_id" "suffix" {
  byte_length = 4
}

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

# ── RDS Multi-AZ ─────────────────────────────────────────
# multi_az = true — automatic failover to standby in second AZ
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

# ── S3 — product images ───────────────────────────────────
module "s3" {
  source  = "./modules/s3"
  project = var.project
  env     = var.env
}

# ── S3 — React frontend ───────────────────────────────────
module "frontend" {
  source  = "./modules/frontend"
  project = var.project
  env     = var.env
  suffix  = random_id.suffix.hex
}

# ── CloudFront — serves both frontend + images ────────────
module "cloudfront" {
  source                 = "./modules/cloudfront"
  project                = var.project
  env                    = var.env
  frontend_bucket_domain = module.frontend.bucket_regional_domain
  frontend_oac_id        = module.frontend.oac_id
  images_bucket_domain   = module.s3.bucket_regional_domain
  images_oac_id          = module.s3.oac_id
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.sg.alb_sg_id
}

# ── Auto Scaling Group ────────────────────────────────────
# Replaces direct EC2 — min 1, max 2, across both AZs
module "asg" {
  source               = "./modules/asg"
  project              = var.project
  env                  = var.env
  ami_id               = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  iam_instance_profile = module.iam.instance_profile_name
  app_sg_id            = module.sg.app_sg_id
  public_subnet_ids    = module.vpc.public_subnet_ids
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
  ec2_instance_id = "asg"
  rds_identifier  = "${var.project}-${var.env}-mysql"
  sqs_queue_name  = "${var.project}-${var.env}-product-events"
  alb_arn_suffix  = module.alb.alb_arn_suffix
}

# ── GitHub OIDC ───────────────────────────────────────────
module "iam_github" {
  source      = "./modules/iam_github"
  project     = var.project
  env         = var.env
  github_org  = var.github_org
  github_repo = var.github_repo
}

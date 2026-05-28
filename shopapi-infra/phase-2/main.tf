terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Latest Amazon Linux 2023 AMI ──────────────────────────
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

# ── VPC ───────────────────────────────────────────────────
module "vpc" {
  source   = "./modules/vpc"
  project  = var.project
  env      = var.env
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

# ── Security Groups ───────────────────────────────────────
module "sg" {
  source  = "./modules/sg"
  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id
}

# ── IAM ───────────────────────────────────────────────────
module "iam" {
  source  = "./modules/iam"
  project = var.project
  env     = var.env
}

# ── SSM Parameter Store ───────────────────────────────────
# Stores secrets — EC2 reads these at startup instead of hardcoded .env
module "ssm" {
  source      = "./modules/ssm"
  project     = var.project
  env         = var.env
  db_host     = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

# ── RDS MySQL ─────────────────────────────────────────────
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

# ── S3 + CloudFront ───────────────────────────────────────
module "s3" {
  source  = "./modules/s3"
  project = var.project
  env     = var.env
}

module "cloudfront" {
  source      = "./modules/cloudfront"
  project     = var.project
  env         = var.env
  bucket_id           = module.s3.bucket_id
  bucket_regional_domain = module.s3.bucket_regional_domain
  oac_id      = module.s3.oac_id
}

# ── ALB ───────────────────────────────────────────────────
module "alb" {
  source            = "./modules/alb"
  project           = var.project
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.sg.alb_sg_id
}

# ── EC2 App Server ────────────────────────────────────────
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
}

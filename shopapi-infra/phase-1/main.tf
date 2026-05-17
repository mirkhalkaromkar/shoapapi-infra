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

# ── VPC ───────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project    = var.project
  env        = var.env
  vpc_cidr   = var.vpc_cidr
  azs        = var.azs
}

# ── Security Groups ───────────────────────────────────────
module "sg" {
  source = "./modules/sg"

  project = var.project
  env     = var.env
  vpc_id  = module.vpc.vpc_id
}

# ── IAM ───────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project = var.project
  env     = var.env
}

# ── RDS MySQL ─────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project             = var.project
  env                 = var.env
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_sg_id            = module.sg.db_sg_id
}

# ── EC2 App Server ────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  project              = var.project
  env                  = var.env
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  public_subnet_id     = module.vpc.public_subnet_ids[0]
  app_sg_id            = module.sg.app_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  db_host              = module.rds.db_endpoint
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
}

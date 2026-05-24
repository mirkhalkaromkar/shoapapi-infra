variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"   # Mumbai — closest to Bengaluru
}

variable "project" {
  description = "Project name — used in resource naming and tags"
  type        = string
  default     = "shopapi"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI — update if region changes"
  type        = string
  # Amazon Linux 2023 in ap-south-1 (free tier eligible)
  default     = "ami-09ed39e30153c3bf9"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"   # free tier
}

# ── Database ──────────────────────────────────────────────
variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "shopdb"
}

variable "db_username" {
  description = "MySQL master username"
  type        = string
  default     = "shopuser"
}

variable "db_password" {
  description = "MySQL master password — override via terraform.tfvars or env var"
  type        = string
  sensitive   = true
}

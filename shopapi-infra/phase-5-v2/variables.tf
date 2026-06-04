variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "project" {
  type    = string
  default = "shopapi"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "db_name" {
  type    = string
  default = "shopdb"
}
variable "db_username" {
  type    = string
  default = "shopuser"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "alert_email" {
  type    = string
  default = "omkar@gmail.com"
}
variable "github_org" {
  type    = string
  default = "mirkhalkaromkar"
}
variable "github_repo" {
  type    = string
  default = "shopapi"
}

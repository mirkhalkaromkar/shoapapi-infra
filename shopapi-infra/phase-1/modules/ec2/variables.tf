variable "project"              { type = string }
variable "env"                  { type = string }
variable "ami_id"               { type = string }
variable "instance_type"        { type = string }
variable "public_subnet_id"     { type = string }
variable "app_sg_id"            { type = string }
variable "iam_instance_profile" { type = string }
variable "db_host"              { type = string }
variable "db_name"              { type = string }
variable "db_username"          { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}


resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  iam_instance_profile   = var.iam_instance_profile

  # user_data runs once on first boot — installs everything and starts the app
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_host     = var.db_host
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
  }))

  # Root volume — 8GB is enough, free tier gives up to 30GB
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name    = "${var.project}-${var.env}-app"
    Project = var.project
    Env     = var.env
  }
}

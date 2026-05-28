resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    aws_region  = var.aws_region
    project_env = var.project_env
  }))

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name    = "${split("/", var.project_env)[0]}-${split("/", var.project_env)[1]}-app"
    Project = split("/", var.project_env)[0]
    Env     = split("/", var.project_env)[1]
  }
}

# ── Register EC2 into ALB target group ────────────────────
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.app.id
  port             = 3000
}

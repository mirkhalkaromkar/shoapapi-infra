# ── Redis EC2 Instance ────────────────────────────────────
resource "aws_instance" "redis" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.redis_sg_id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y redis6
    systemctl enable redis6
    systemctl start redis6
    # Bind to all interfaces so app EC2 can connect
    sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis6/redis6.conf
    systemctl restart redis6
    echo "Redis bootstrap complete"
  EOF
  )

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name    = "${var.project}-${var.env}-redis"
    Project = var.project
    Env     = var.env
  }
}

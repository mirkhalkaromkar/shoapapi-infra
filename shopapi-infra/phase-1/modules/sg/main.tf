# ── App Security Group (EC2) ──────────────────────────────
resource "aws_security_group" "app" {
  name        = "${var.project}-${var.env}-app-sg"
  description = "Allow HTTP on 3000 and SSH from anywhere"
  vpc_id      = var.vpc_id

  # SSH — tighten to your IP in production
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App port
  ingress {
    description = "ShopAPI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound allowed — EC2 needs to reach RDS, internet for npm
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-app-sg"
    Project = var.project
  }
}

# ── DB Security Group (RDS) ───────────────────────────────
# Only accepts connections from the app security group
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.env}-db-sg"
  description = "Allow MySQL only from app security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-db-sg"
    Project = var.project
  }
}

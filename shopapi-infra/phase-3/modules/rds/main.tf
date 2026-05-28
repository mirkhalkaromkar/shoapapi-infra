# ── DB Subnet Group ───────────────────────────────────────
# RDS needs subnets in at least 2 AZs
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name    = "${var.project}-${var.env}-db-subnet-group"
    Project = var.project
  }
}

# ── RDS MySQL Instance ────────────────────────────────────
resource "aws_db_instance" "mysql" {
  identifier = "${var.project}-${var.env}-mysql"

  # Free tier eligible
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"      # free tier: 750 hrs/month
  allocated_storage    = 20                 # free tier: 20 GB
  storage_type         = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  # Free tier: single-AZ, no Multi-AZ (Phase 6 will add this)
  multi_az               = false
  publicly_accessible    = false   # private subnet — only EC2 can reach it

  # Backups — keep 1 day (free tier eligible)
  backup_retention_period = 1
  backup_window           = "02:00-03:00"   # 2-3 AM UTC

  # Maintenance
  maintenance_window         = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade = true

  # Don't delete accidentally
  deletion_protection = false   # set to true in production
  skip_final_snapshot = true    # set to false in production

  tags = {
    Name    = "${var.project}-${var.env}-mysql"
    Project = var.project
    Env     = var.env
  }
}

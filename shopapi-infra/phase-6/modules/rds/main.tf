resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.project}-${var.env}-db-subnet-group", Project = var.project }
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project}-${var.env}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az               = true
  publicly_accessible    = false
  backup_retention_period = 1
  backup_window          = "02:00-03:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = { Name = "${var.project}-${var.env}-mysql", Project = var.project, Env = var.env }
}

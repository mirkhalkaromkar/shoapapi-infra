output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id"  { value = aws_security_group.db.id }
output "alb_sg_id" { value = aws_security_group.alb.id }

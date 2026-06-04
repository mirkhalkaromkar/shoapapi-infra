output "db_endpoint" { value = split(":", aws_db_instance.mysql.endpoint)[0] }
output "db_arn"      { value = aws_db_instance.mysql.arn }

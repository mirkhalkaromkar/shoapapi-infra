output "db_host_path"     { value = aws_ssm_parameter.db_host.name }
output "db_password_path" { value = aws_ssm_parameter.db_password.name }

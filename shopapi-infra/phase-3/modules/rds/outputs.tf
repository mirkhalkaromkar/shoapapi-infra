output "db_endpoint" {
  # RDS gives endpoint as host:port — we strip the port for the app
  value = split(":", aws_db_instance.mysql.endpoint)[0]
}

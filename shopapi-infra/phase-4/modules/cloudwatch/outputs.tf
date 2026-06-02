output "log_group_app"    { value = aws_cloudwatch_log_group.app.name }
output "log_group_worker" { value = aws_cloudwatch_log_group.worker.name }
output "sns_topic_arn"    { value = aws_sns_topic.alerts.arn }
output "dashboard_name"   { value = aws_cloudwatch_dashboard.main.dashboard_name }

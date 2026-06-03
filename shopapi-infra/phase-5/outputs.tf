output "app_url" {
  value = "http://${module.alb.alb_dns}"
}
output "alb_dns" {
  value = module.alb.alb_dns
}
output "cloudfront_url" {
  value = "https://${module.cloudfront.cloudfront_domain}"
}
output "ec2_instance_id" {
  value = module.ec2.instance_id
}
output "ecr_repo_url" {
  value = module.ecr.repository_url
}
output "pipeline_name" {
  value = module.codepipeline.pipeline_name
}
output "github_connection_arn" {
  value       = module.codepipeline.github_connection_arn
  description = "Activate this connection manually in AWS Console after apply"
}
output "github_connection_status" {
  value       = module.codepipeline.github_connection_status
  description = "Must be AVAILABLE before pipeline works — activate in console"
}
output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.cloudwatch.dashboard_name}"
}
output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

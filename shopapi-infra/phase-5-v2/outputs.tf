output "app_url" {
  value = "http://${module.alb.alb_dns}"
}
output "alb_dns" {
  value = module.alb.alb_dns
}
output "cloudfront_url" {
  value = "https://${module.cloudfront.cloudfront_domain}"
}
output "s3_bucket" {
  value = module.s3.bucket_id
}
output "ec2_instance_id" {
  value = module.ec2.instance_id
}
output "sqs_queue_url" {
  value = module.sqs.queue_url
}
output "github_actions_role_arn" {
  value       = module.iam_github.role_arn
  description = "Paste this into GitHub repo secrets as AWS_DEPLOY_ROLE_ARN"
}
output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.cloudwatch.dashboard_name}"
}
output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

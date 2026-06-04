output "app_url" {
  value       = "http://${module.alb.alb_dns}"
  description = "API endpoint via ALB"
}
output "frontend_url" {
  value       = "https://${module.cloudfront.cloudfront_domain}"
  description = "React frontend via CloudFront"
}
output "cloudfront_id" {
  value       = module.cloudfront.cloudfront_id
  description = "Needed for GitHub Actions cache invalidation"
}
output "frontend_bucket" {
  value       = module.frontend.bucket_id
  description = "S3 bucket for React build — used by GitHub Actions"
}
output "images_bucket" {
  value = module.s3.bucket_id
}
output "asg_name" {
  value = module.asg.asg_name
}
output "github_actions_role_arn" {
  value       = module.iam_github.role_arn
  description = "Set as AWS_DEPLOY_ROLE_ARN in GitHub secrets"
}
output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

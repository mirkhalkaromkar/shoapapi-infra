output "alb_dns" {
  description = "ALB DNS — use this to access the API (not EC2 IP directly)"
  value       = module.alb.alb_dns
}

output "app_url" {
  description = "ShopAPI URL via ALB"
  value       = "http://${module.alb.alb_dns}"
}

output "cloudfront_url" {
  description = "CloudFront URL for static assets"
  value       = "https://${module.cloudfront.cloudfront_domain}"
}

output "s3_bucket" {
  description = "S3 bucket name for product images"
  value       = module.s3.bucket_id
}

output "ec2_instance_id" {
  description = "EC2 instance ID — for SSM session"
  value       = module.ec2.instance_id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

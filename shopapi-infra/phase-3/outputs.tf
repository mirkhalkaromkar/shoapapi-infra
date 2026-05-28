output "alb_dns" {
  value = module.alb.alb_dns
}
output "app_url" {
  value = "http://${module.alb.alb_dns}"
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
output "redis_instance_id" {
  value = module.redis.redis_instance_id
}
output "redis_private_ip" {
  value = module.redis.redis_private_ip
}
output "sqs_queue_url" {
  value = module.sqs.queue_url
}
output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

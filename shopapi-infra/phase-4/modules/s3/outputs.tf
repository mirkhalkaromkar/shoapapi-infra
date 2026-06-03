output "bucket_id"              { value = aws_s3_bucket.images.id }
output "bucket_arn"             { value = aws_s3_bucket.images.arn }
output "bucket_regional_domain" { value = aws_s3_bucket.images.bucket_regional_domain_name }
output "oac_id"                 { value = aws_cloudfront_origin_access_control.oac.id }

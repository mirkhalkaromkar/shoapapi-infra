output "cloudfront_domain" { value = aws_cloudfront_distribution.images.domain_name }
output "cloudfront_id"     { value = aws_cloudfront_distribution.images.id }

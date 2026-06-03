resource "aws_cloudfront_distribution" "images" {
  enabled             = true
  comment             = "${var.project}-${var.env} CDN"
  default_root_object = "index.html"

  origin {
    domain_name              = var.bucket_regional_domain
    origin_id                = "s3-${var.bucket_id}"
    origin_access_control_id = var.oac_id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${var.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Project = var.project, Env = var.env }
}

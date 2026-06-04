# ── CloudFront Distribution ───────────────────────────────
# Phase 6: serves both frontend (/) and product images (/images/*)
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "${var.project}-${var.env} CDN"
  default_root_object = "index.html"

  # Origin 1 — React frontend (S3)
  origin {
    domain_name              = var.frontend_bucket_domain
    origin_id                = "frontend-s3"
    origin_access_control_id = var.frontend_oac_id
  }

  # Origin 2 — Product images (S3)
  origin {
    domain_name              = var.images_bucket_domain
    origin_id                = "images-s3"
    origin_access_control_id = var.images_oac_id
  }

  # Default behaviour — serve React frontend
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "frontend-s3"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # /images/* — serve product images
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "images-s3"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # SPA routing — return index.html for 404s (React Router)
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Project = var.project, Env = var.env }
}

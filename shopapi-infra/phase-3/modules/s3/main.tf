# ── S3 Bucket ─────────────────────────────────────────────
resource "aws_s3_bucket" "images" {
  bucket = "${var.project}-${var.env}-images-${random_id.suffix.hex}"

  tags = { Name = "${var.project}-${var.env}-images", Project = var.project }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Block all public access — CloudFront accesses via OAC
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Origin Access Control ─────────────────────────────────
# Allows CloudFront to access private S3 bucket securely
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-${var.env}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── Bucket Policy ─────────────────────────────────────────
# Only CloudFront can read from this bucket
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontAccess"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.images.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::*:distribution/*"
        }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.images]
}

# ── CORS ─────────────────────────────────────────────────
resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# This file defines the resources for hosting the Single-Page Application (SPA) frontend.

# --- S3 Bucket for SPA ---
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.stack}-frontend-spa"
}

# Block all public access settings for the bucket initially
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- CloudFront Origin Access Identity ---
# This creates a special CloudFront user that can be granted access to the S3 bucket,
# ensuring that users can only access the content through CloudFront.
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${aws_s3_bucket.frontend.id}"
}

# --- S3 Bucket Policy ---
# This policy allows the CloudFront Origin Access Identity to read objects from the bucket.
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "s3:GetObject",
        Effect    = "Allow",
        Resource  = "${aws_s3_bucket.frontend.arn}/*",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
      }
    ]
  })
}

# --- CloudFront Distribution ---
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Main distribution for the Sally application"
  default_root_object = "index.html"

  # --- Origins ---
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  origin {
    # The domain name for the API Gateway v2 is the invoke URL without the protocol.
    domain_name = replace(aws_apigatewayv2_api.main.api_endpoint, "https://", "")
    origin_id   = "API-Gateway-${aws_apigatewayv2_api.main.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --- Default Behavior (SPA) ---
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # --- API Behavior ---
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "API-Gateway-${aws_apigatewayv2_api.main.id}"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # --- Viewer Certificate ---
  # This uses the default CloudFront certificate (*.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

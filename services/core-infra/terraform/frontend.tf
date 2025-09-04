# Create a private S3 bucket for the frontend assets
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.stack}-${var.module_name}-frontend-spa"
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a CloudFront Origin Access Control (OAC)
# This is the modern, recommended way to grant CloudFront access to a private S3 bucket
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-${var.stack}-frontend-oac"
  description                       = "OAC for Sally frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Update the S3 bucket policy to allow access from CloudFront via the OAC
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

# Create the CloudFront distribution
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    # Use the S3 bucket's regional domain name as the origin
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend.id

    # Associate the Origin Access Control with this origin
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Handle 403/404 errors from S3 by returning the index.html page,
  # which is standard for Single Page Applications (SPAs)
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend.id

    # Use a managed cache policy for optimal caching
    # CachingOptimized forwards no cookies, headers, or query strings
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
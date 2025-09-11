terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---

# Get outputs from the core infrastructure stack, like the frontend bucket name
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "sally-terraform-state-bucket"
    key    = "${var.stack}/services/core-infra/terraform.tfstate"
    region = var.aws_region
  }
}

# --- Locals ---
locals {
  # Create the content for the config.json file dynamically
  config_content = jsonencode({
    cognito_hosted_ui_url = data.terraform_remote_state.core.outputs.cognito_hosted_ui_url
  })

  # Map file extensions to MIME types for S3 content_type
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    # Add more as needed
  }
}

# --- Resource Provisioning ---

# This resource unpacks the frontend assets from the zip file created by the build process.
resource "null_resource" "unzip_frontend" {
  triggers = {
    zip_hash = fileexists("../frontend-lambda.zip") ? filebase64sha256("../frontend-lambda.zip") : ""
  }

  provisioner "local-exec" {
    command = "unzip -o ../frontend-lambda.zip -d ../dist"
  }
}

# This resource uploads all the files extracted by the null_resource to the S3 bucket.
resource "aws_s3_object" "frontend_files" {
  # Use try() to handle cases where ../dist might not exist during plan phase
  for_each = try(fileset("../dist", "**"), toset([]))

  depends_on = [null_resource.unzip_frontend]

  bucket = data.terraform_remote_state.core.outputs.frontend_bucket_name
  key    = each.value
  source = "../dist/${each.value}"
  etag   = filemd5("../dist/${each.value}")
  
  # Dynamically set content_type based on file extension
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# This resource creates and uploads the dynamic config.json file to the S3 bucket.
resource "aws_s3_object" "config_file" {
  bucket       = data.terraform_remote_state.core.outputs.frontend_bucket_name
  key          = "config.json"
  content      = local.config_content
  content_type = "application/json"
  etag         = md5(local.config_content)
}

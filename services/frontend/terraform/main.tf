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

# --- Resource Provisioning ---

# This resource unpacks the frontend assets from the zip file created by the build process.
# It uses a local-exec provisioner, which is a way to run shell commands during apply.
# The trigger ensures this only runs when the content of the zip file changes.
resource "null_resource" "unzip_frontend" {
  # This path is relative to the terraform/ directory where this script is run from.
  triggers = {
    zip_hash = fileexists("../frontend-lambda.zip") ? filebase64sha256("../frontend-lambda.zip") : ""
  }

  provisioner "local-exec" {
    # Unzip the contents into a temporary directory at the root of the service folder.
    command = "unzip -o ../frontend-lambda.zip -d ../dist"
  }
}

# This resource uploads all the files extracted by the null_resource to the S3 bucket.
resource "aws_s3_object" "frontend_files" {
  # The for_each meta-argument iterates over all files found in the ../dist directory.
  for_each = fileexists("../dist") ? fileset("../dist", "**") : toset([])

  # This ensures that the files are unzipped before Terraform tries to upload them.
  depends_on = [null_resource.unzip_frontend]

  bucket = data.terraform_remote_state.core.outputs.frontend_bucket_name
  key    = each.value
  source = "../dist/${each.value}"
  # The etag attribute ensures that the file is only re-uploaded if its content changes.
  etag   = filemd5("../dist/${each.value}")
  # Set the content type for HTML files to ensure they render correctly in the browser.
  content_type = "text/html"
}

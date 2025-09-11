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
}

# This resource handles unzipping the frontend package and uploading files to S3.
resource "null_resource" "frontend_deploy" {
  triggers = {
    # Trigger a redeploy if the zip file content changes
    zip_hash = fileexists("../frontend-lambda.zip") ? filebase64sha256("../frontend-lambda.zip") : ""
    # Trigger a redeploy if the config.json content changes
    config_hash = md5(local.config_content)
  }

  provisioner "local-exec" {
    # Commands are executed from the directory where terraform is run (services/frontend/terraform)
    # So, ../ refers to services/frontend
    # And ../dist refers to services/frontend/dist
    command = <<EOT
      rm -rf ../dist
      mkdir -p ../dist
      unzip -o ../frontend-lambda.zip -d ../dist

      # Use aws s3 sync to upload all files, relying on S3's MIME type guessing
      # Exclude config.json as it's uploaded separately with explicit content-type
      aws s3 sync ../dist/ s3://${data.terraform_remote_state.core.outputs.frontend_bucket_name}/ --exclude "config.json" --delete

      # Upload config.json separately to ensure its content type is always application/json
      echo '${local.config_content}' | aws s3 cp - s3://${data.terraform_remote_state.core.outputs.frontend_bucket_name}/config.json --content-type application/json
    EOT
  }
}

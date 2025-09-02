terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Note: This was already correct, no change needed here.
    }
  }
}

# --- Data Sources ---
# Use a remote state to get outputs from the core infrastructure stack
data "terraform_remote_state" "core" {
  backend = "s3" # This should be configured to your actual remote state backend
  config = {
    bucket = "sally-terraform-state-bucket" # Example bucket
    key    = "${var.environment}/core/terraform.tfstate"
    region = var.aws_region
  }
}
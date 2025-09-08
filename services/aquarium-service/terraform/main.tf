terraform {
  backend "s3" {
    bucket = "sally-terraform-state-bucket" # Replace with the name of the S3 bucket you created
    key    = "state/aquarium-service/terraform.tfstate" # The prefix will be set dynamically during init
    region = "eu-west-3"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Note: This was already correct, no change needed here.
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---
# Use a remote state to get outputs from the core infrastructure stack
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "sally-terraform-state-bucket"
    key    = "${var.stack}/services/core-infra/terraform.tfstate"
    region = "eu-west-3"
  }
}

# This data source reads the outputs from the global-infra module,
# allowing this service to access shared resources like the VPC and subnets.
data "terraform_remote_state" "global_infra" {
  backend = "s3"
  config = {
    bucket = "sally-terraform-state-bucket"
    key    = "global/global-infra/infra/terraform.tfstate"
    region = "eu-west-3"
  }
}

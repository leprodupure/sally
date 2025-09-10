terraform {
  backend "s3" {
    bucket = "sally-terraform-state-bucket"
    # The key is dynamically set by the CI pipeline to something like:
    # key = "pr123/services/measurement-service/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

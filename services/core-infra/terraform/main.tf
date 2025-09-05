terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "sally-terraform-state-bucket" # Replace with the name of the S3 bucket you created
    key    = "state/core-infra/terraform.tfstate" # The prefix will be set dynamically during init
    region = "eu-west-3"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
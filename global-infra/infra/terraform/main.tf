terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "sally-terraform-state-bucket" # Replace with the name of the S3 bucket you created
    key    = "global-infra/terraform.tfstate"
    region = "eu-west-3"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3" # This can be hardcoded as it's a global resource
}

variable "stack" {
  description = "placeholder for the CI pipeline"
}

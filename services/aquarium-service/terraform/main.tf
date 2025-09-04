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

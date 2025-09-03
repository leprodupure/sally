# Terraform variable values for the 'production' environment.
# These variables can be shared across multiple modules.
#
# To use this file, navigate to a module's directory (e.g., services/core-infra/terraform)
# and run terraform with the -var-file flag using the relative path:
#
# terraform apply -var-file="../../../environments/common.tfvars" -var-file="../../../environments/production.tfvars"

environment = "production"

# It's a good practice to use a different CIDR block for each environment
# to prevent IP address conflicts if you ever need to peer VPCs.
vpc_cidr = "10.30.0.0/16"
# Terraform variable values for the 'staging' environment.
#
# To use this file, run terraform with the -var-file flag:
# terraform apply -var-file="staging.tfvars"

environment = "staging"

# It's a good practice to use a different CIDR block for each environment
# to prevent IP address conflicts if you ever need to peer VPCs.
vpc_cidr = "10.10.0.0/16"

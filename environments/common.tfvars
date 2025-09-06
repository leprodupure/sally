# Common Terraform variable values shared across all environments.
# This file should be loaded before the environment-specific .tfvars file.
#
# Example usage from a module directory:
# terraform apply -var-file="../../../environments/common.tfvars" -var-file="../../../environments/staging.tfvars"

project_name = "sally"
aws_region   = "eu-west-3" # Paris
db_username  = "sally"
s3_package_registry_bucket_name = "sally-package-registry"

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "stack" {
  description = "The deployment stack (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "module_name" {
  description = "The name of the module or service, used for resource naming."
  type        = string
  default     = "core"
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
}

variable "s3_package_registry_bucket_name" {
  description = "The name of the S3 bucket used as a package registry."
  type        = string
}

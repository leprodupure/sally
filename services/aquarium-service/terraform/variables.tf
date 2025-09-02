variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "module_name" {
  description = "The name of the module or service, used for resource naming."
  type        = string
  default     = "aquarium-service"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "image_uri" {
  description = "The ECR image URI for the Lambda function, passed from the CI/CD pipeline."
  type        = string
}
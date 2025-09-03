variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

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
  default     = "core"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
}
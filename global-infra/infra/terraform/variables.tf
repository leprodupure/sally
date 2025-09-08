variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
  default     = "sally"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

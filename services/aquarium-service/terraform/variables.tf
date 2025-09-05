variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "stack" {
  description = "The name of the stack, used for isolating environments (e.g., 'staging', 'pr123')."
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
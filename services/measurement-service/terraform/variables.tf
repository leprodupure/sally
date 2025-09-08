variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "stack" {
  description = "The name of the stack (e.g., 'staging', 'pr123')."
  type        = string
}

variable "module_name" {
  description = "The name of the service module."
  type        = string
  default     = "measurement-service"
}

variable "aws_region" {
  description = "The AWS region for the service."
  type        = string
}

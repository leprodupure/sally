variable "stack" {
  description = "The name of the stack (e.g., 'staging', 'pr123')."
  type        = string
}

variable "aws_region" {
  description = "The AWS region for the service."
  type        = string
}

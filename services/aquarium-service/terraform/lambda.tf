# A security group for the Lambda function to control its network access
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-${var.module_name}-lambda-sg"
  description = "Security group for the Aquarium Service Lambda function"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Lambda Function ---
resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}-${var.module_name}"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.image_uri # This will be passed from the CI/CD pipeline
  timeout       = 30

  vpc_config {
    subnet_ids         = data.terraform_remote_state.core.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = data.terraform_remote_state.core.outputs.db_credentials_secret_arn
      DB_ENDPOINT   = data.terraform_remote_state.core.outputs.db_instance_endpoint
      AWS_REGION    = var.aws_region
    }
  }
}
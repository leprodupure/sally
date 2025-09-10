# A security group for the Lambda function to control its network access
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.stack}-${var.module_name}-lambda-sg"
  description = "Security group for the Measurement Service Lambda function"
  vpc_id      = data.terraform_remote_state.global_infra.outputs.vpc_id

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
  function_name = "${var.project_name}-${var.stack}-${var.module_name}"
  handler       = "main.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 30

  # Assumes the build script has created a zip file with a standard name
  # in the parent directory of this terraform module.
  package_type     = "Zip"
  filename         = "../${var.module_name}-lambda.zip"
  source_code_hash = fileexists("../${var.module_name}-lambda.zip") ? filebase64sha256("../${var.module_name}-lambda.zip") : null

  vpc_config {
    subnet_ids         = data.terraform_remote_state.global_infra.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = data.terraform_remote_state.core.outputs.db_credentials_secret_arn
    }
  }
}

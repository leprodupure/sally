# Read the latest version of the database credentials secret
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.terraform_remote_state.global_infra.outputs.db_credentials_secret_arn
}

# Decode the JSON string from the secret
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  # Construct the database URL from the secret's values
  database_url = "postgresql+psycopg2://${local.db_credentials.username}:${local.db_credentials.password}@${local.db_credentials.endpoint}/${local.db_credentials.db_name}"
}

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

  package_type     = "Zip"
  filename         = "../${var.module_name}-lambda.zip"
  source_code_hash = fileexists("../${var.module_name}-lambda.zip") ? filebase64sha256("../${var.module_name}-lambda.zip") : null

  vpc_config {
    subnet_ids         = data.terraform_remote_state.global_infra.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DATABASE_URL = local.database_url,
      STAGE        = var.stack
    }
  }
}

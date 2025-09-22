# This Lambda function provides a secure way to run ad-hoc SQL queries against the database.

# Read the latest version of the database credentials secret
data "aws_secretsmanager_secret_version" "db_credentials_qr" { # Use a unique name to avoid conflict
  secret_id = data.terraform_remote_state.global_infra.outputs.db_credentials_secret_arn
}

# Decode the JSON string from the secret
locals {
  db_credentials_qr = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_qr.secret_string)
  # Construct the database URL from the secret's values
  database_url_qr = "postgresql+psycopg2://${local.db_credentials_qr.username}:${local.db_credentials_qr.password}@${local.db_credentials_qr.endpoint}/${local.db_credentials_qr.db_name}"
}

resource "aws_iam_role" "query_runner_lambda_exec" {
  name = "${var.project_name}-${var.stack}-query-runner-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "query_runner_vpc_access" {
  role       = aws_iam_role.query_runner_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# IAM policy is now empty as the Lambda no longer needs to call Secrets Manager
resource "aws_iam_role_policy" "query_runner_policy" {
  name = "${var.project_name}-${var.stack}-query-runner-lambda-policy"
  role = aws_iam_role.query_runner_lambda_exec.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [] })
}

resource "aws_security_group" "query_runner_lambda" {
  name        = "${var.project_name}-${var.stack}-query-runner-lambda-sg"
  description = "Security group for the SQL Query Runner Lambda function"
  vpc_id      = data.terraform_remote_state.global_infra.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_db_access_from_query_runner" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.query_runner_lambda.id
  security_group_id        = data.terraform_remote_state.global_infra.outputs.db_security_group_id
  description              = "Allow SQL query runner to connect to the database"
}

resource "aws_lambda_function" "query_runner" {
  function_name = "${var.project_name}-${var.stack}-query-runner"
  handler       = "query_runner.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.query_runner_lambda_exec.arn
  timeout       = 60

  package_type     = "Zip"
  filename         = "../core-infra-lambda.zip"
  source_code_hash = fileexists("../core-infra-lambda.zip") ? filebase64sha256("../core-infra-lambda.zip") : null

  vpc_config {
    subnet_ids         = data.terraform_remote_state.global_infra.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.query_runner_lambda.id]
  }

  environment {
    variables = {
      DATABASE_URL = local.database_url_qr
    }
  }
}

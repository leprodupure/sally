# This Lambda function is a generic utility to run database migrations.
# It is invoked by the CI/CD pipeline.

# Read the latest version of the database credentials from SSM Parameter Store
data "aws_ssm_parameter" "db_credentials" {
  name = data.terraform_remote_state.global_infra.outputs.db_credentials_parameter_name
}

# Decode the JSON string from the parameter
locals {
  db_credentials = jsondecode(data.aws_ssm_parameter.db_credentials.value)
  # Construct the database URL from the secret's values
  database_url = "postgresql+psycopg2://${local.db_credentials.username}:${local.db_credentials.password}@${local.db_credentials.endpoint}/${local.db_credentials.db_name}"
}

resource "aws_iam_role" "migration_runner_lambda_exec" {
  name = "${var.project_name}-${var.stack}-migration-runner-lambda-role"

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

resource "aws_iam_role_policy_attachment" "migration_runner_vpc_access" {
  role       = aws_iam_role.migration_runner_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "migration_runner_policy" {
  name = "${var.project_name}-${var.stack}-migration-runner-lambda-policy"
  role = aws_iam_role.migration_runner_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_package_registry_bucket_name}/*",
          "arn:aws:s3:::${var.s3_package_registry_bucket_name}"
        ]
      }
    ]
  })
}

resource "aws_security_group" "migration_runner_lambda" {
  name        = "${var.project_name}-${var.stack}-migration-runner-lambda-sg"
  description = "Security group for the Migration Runner Lambda function"
  vpc_id      = data.terraform_remote_state.global_infra.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_db_access_from_migration_runner" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.migration_runner_lambda.id
  security_group_id        = data.terraform_remote_state.global_infra.outputs.db_security_group_id
  description              = "Allow migration runner to connect to the database"
}

resource "aws_lambda_function" "migration_runner" {
  function_name = "${var.project_name}-${var.stack}-migration-runner"
  handler       = "migration_runner.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.migration_runner_lambda_exec.arn
  timeout       = 60

  package_type     = "Zip"
  filename         = "../core-infra-lambda.zip"
  source_code_hash = fileexists("../core-infra-lambda.zip") ? filebase64sha256("../core-infra-lambda.zip") : null

  vpc_config {
    subnet_ids         = data.terraform_remote_state.global_infra.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.migration_runner_lambda.id]
  }

  environment {
    variables = {
      DATABASE_URL = local.database_url
      S3_BUCKET    = var.s3_package_registry_bucket_name
    }
  }
}

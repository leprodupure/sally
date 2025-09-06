# This Lambda function is a generic utility to run database migrations.
# It is invoked by the CI/CD pipeline.

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
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_package_registry_bucket_name}/*", # Grant access to the objects
          "arn:aws:s3:::${var.s3_package_registry_bucket_name}"  # Grant access to the bucket itself (for operations like ListBucket)
        ]
      }
    ]
  })
}

resource "aws_security_group" "migration_runner_lambda" {
  name        = "${var.project_name}-${var.stack}-migration-runner-lambda-sg"
  description = "Security group for the Migration Runner Lambda function"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "migration_runner" {
  function_name = "${var.project_name}-${var.stack}-migration-runner"
  handler       = "migration_runner.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.migration_runner_lambda_exec.arn
  timeout       = 60 # Migrations can take time

  # The code for this lambda is built and packaged with the core-infra service
  package_type     = "Zip"
  filename         = "../core-infra-lambda.zip"
  source_code_hash = filebase64sha256("../core-infra-lambda.zip")

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.migration_runner_lambda.id]
  }

  environment {
    variables = {
      # Pass the secret ARN to the migration runner so it can connect to the DB
      DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
      S3_BUCKET     = var.s3_package_registry_bucket_name
    }
  }
}

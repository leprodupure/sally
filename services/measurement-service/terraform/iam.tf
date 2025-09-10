# This file defines the IAM role and policies for the Lambda function.

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-lambda-role"

  # This policy allows the Lambda function to be assumed by the Lambda service.
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

# This policy attachment grants the Lambda function basic execution permissions,
# including writing logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# This policy grants the Lambda function permission to get the database
# credentials from AWS Secrets Manager.
resource "aws_iam_role_policy" "get_db_credentials" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-get-db-creds"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = data.terraform_remote_state.core.outputs.db_credentials_secret_arn
      }
    ]
  })
}

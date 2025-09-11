# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach the AWS managed policy for VPC access. This covers ENI creation and CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# A separate policy for custom permissions, like accessing Secrets Manager.
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = data.terraform_remote_state.core.outputs.db_credentials_secret_arn
      }
    ]
  })
}
data "aws_region" "current" {}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-${var.stack}-http-api"
  protocol_type = "HTTP"
  description   = "Main HTTP API for the ${var.project_name} project"
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

# --- CloudWatch Log Group for API Gateway Access Logs ---
resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.stack}-http-api-access-logs"
  retention_in_days = 7 # Retain logs for 7 days
}

# --- IAM Role for API Gateway to write logs ---
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.project_name}-${var.stack}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  name = "${var.project_name}-${var.stack}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = ["${aws_cloudwatch_log_group.api_gateway_access_logs.arn}:*", "${aws_cloudwatch_log_group.api_gateway_access_logs.arn}"]
      }
    ]
  })
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.stack
  auto_deploy = true

  # --- Access Log Settings ---
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    # Use the CLF format for common web server log compatibility
    format = "{\"requestId\":\"$context.requestId\",\"ip\":\"$context.identity.sourceIp\",\"caller\":\"$context.identity.caller\",\"user\":\"$context.identity.user\",\"requestTime\":\"$context.requestTime\",\"httpMethod\":\"$context.httpMethod\",\"resourcePath\":\"$context.resourcePath\",\"status\":\"$context.status\",\"protocol\":\"$context.protocol\",\"responseLength\":\"$context.responseLength\"}"
  }
}

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
    issuer   = aws_cognito_user_pool.main.endpoint
  }
}

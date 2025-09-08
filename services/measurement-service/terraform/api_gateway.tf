# This file defines the API Gateway routes and integrations for the service.

# --- API Gateway Integration ---
# This resource connects the API Gateway to the Lambda function.
resource "aws_apigatewayv2_integration" "main" {
  api_id           = data.terraform_remote_state.core.outputs.api_gateway_id
  integration_type = "AWS_PROXY"
  # The URI of the Lambda function to invoke.
  integration_uri  = aws_lambda_function.main.invoke_arn
}

# --- API Gateway Routes ---
# This defines the publicly accessible routes for the service.

# GET /measurements
resource "aws_apigatewayv2_route" "get_measurements" {
  api_id    = data.terraform_remote_state.core.outputs.api_gateway_id
  route_key = "GET /measurements"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# POST /measurements
resource "aws_apigatewayv2_route" "create_measurement" {
  api_id    = data.terraform_remote_state.core.outputs.api_gateway_id
  route_key = "POST /measurements"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# This permission allows API Gateway to invoke the Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"

  # The ARN of the API Gateway. This is a broad permission, but necessary for the proxy integration.
  source_arn = "${data.terraform_remote_state.core.outputs.api_gateway_execution_arn}/*/*"
}

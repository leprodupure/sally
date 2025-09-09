output "api_gateway_id" {
  description = "The ID of the main API Gateway v2 (HTTP API)."
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the main API Gateway, used for invoking Lambda functions."
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "db_credentials_secret_arn" {
  description = "The ARN of the secret containing the database credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_security_group_id" {
  description = "The ID of the security group for the database."
  value       = aws_security_group.db.id
}

output "api_gateway_id" {
  description = "The ID of the main API Gateway v2 (HTTP API)."
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the main API Gateway, used for invoking Lambda functions."
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "api_gateway_invoke_url" {
  description = "The base URL for invoking the API Gateway."
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_authorizer_id" {
  description = "The ID of the Cognito JWT Authorizer for the API Gateway."
  value       = aws_apigatewayv2_authorizer.cognito.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution for the frontend."
  value       = aws_cloudfront_distribution.main.domain_name
}

output "frontend_bucket_name" {
  description = "The name of the S3 bucket for the frontend SPA."
  value       = aws_s3_bucket.frontend.id
}

output "db_credentials_secret_arn" {
  description = "The ARN of the secret containing the database credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_security_group_id" {
  description = "The ID of the security group for the database."
  value       = aws_security_group.db.id
}

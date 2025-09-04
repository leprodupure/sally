# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-user-pool"

  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = false
    required            = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  tags = {
    Name        = "${var.project_name}-${var.stack}-${var.module_name}-user-pool"
    Project     = var.project_name
    Environment = var.stack
  }
}

# --- Cognito User Pool Client ---
resource "aws_cognito_user_pool_client" "main" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-app-client"

  user_pool_id = aws_cognito_user_pool.main.id

  # A client secret is not generated for a web-based application (SPA)
  generate_secret = false

  # These flows are recommended for use with the Amplify library
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}
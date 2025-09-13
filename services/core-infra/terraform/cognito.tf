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

# --- Cognito User Pool Domain ---
# This creates a unique domain for the Cognito Hosted UI.
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.stack}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

# --- Cognito User Pool Client ---
resource "aws_cognito_user_pool_client" "main" {
  name = "${var.project_name}-${var.stack}-${var.module_name}-app-client"

  user_pool_id = aws_cognito_user_pool.main.id

  # A client secret is not generated for a web-based application (SPA)
  generate_secret = false

  # These flows are recommended for use with the Amplify library or a traditional web app.
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH" # Often needed for Amplify
  ]

  # --- Hosted UI Configuration ---
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  # The callback URL is where the user is redirected to after a successful login.
  # For this setup, we'll point it to the CloudFront distribution.
  callback_urls = ["https://${aws_cloudfront_distribution.main.domain_name}"]

  # The logout URL is where the user is redirected to after logging out.
  logout_urls = ["https://${aws_cloudfront_distribution.main.domain_name}"]
}

variable "oauth_flows" {
  description = "OAuth flows habilitados para el App Client"
  type        = list(string)
  default     = ["implicit"]
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_cognito_user_pool" "user_pool" {
  name = "minimarkets-user-pool"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "frontend-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false   

  # Redirección directa a index.html (esto es CRÍTICO)
  callback_urls = [
  "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/",
  "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/index.html"
  ]

  logout_urls = [
    "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/",
    "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/index.html"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = var.oauth_flows
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "minimarkets-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

module "lambda_redirect" {
  source          = "../lambda_redirect"
  cognito_domain  = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.us-east-1.amazoncognito.com"
  client_id       = var.manual_client_id
  lambda_role_arn = aws_iam_role.lambda_edge_role.arn
}
resource "local_file" "frontend_config" {
  content = <<-EOT
    const base = "https://m4iyoh88pd.execute-api.us-east-1.amazonaws.com/prod";
    window.COGNITO_DOMAIN = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.region}.amazoncognito.com";
    window.COGNITO_CLIENT_ID = "${aws_cognito_user_pool_client.user_pool_client.id}";
  EOT
  filename = "${path.module}/../frontend/config.js"
}
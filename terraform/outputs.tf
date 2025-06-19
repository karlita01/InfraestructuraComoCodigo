output "lambda_function_guardar_producto" {
  description = "Nombre de la función Lambda principal"
  value       = aws_lambda_function.guardar_producto.function_name
}

output "rds_endpoint" {
  description = "Endpoint de la base de datos PostgreSQL"
  value       = aws_db_instance.productos_db.address
}

output "rds_port" {
  description = "Puerto de la base de datos PostgreSQL"
  value       = aws_db_instance.productos_db.port
}

output "rds_db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  value       = aws_db_instance.productos_db.db_name
}

output "api_gateway_url" {
  description = "URL para invocar el endpoint de productos vía API Gateway"
  value       = "https://${aws_api_gateway_rest_api.productos_api.id}.execute-api.${var.region}.amazonaws.com/prod"
}

output "cloudfront_url" {
  description = "URL del frontend servida desde CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}"
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

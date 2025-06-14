resource "aws_api_gateway_rest_api" "productos_api" {
  name = "productos-api"

    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_role.arn
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/productos-api"
  retention_in_days = 7
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

locals {
  resources = {
    productos = {
      methods = ["POST"]
      lambda  = aws_lambda_function.guardar_producto
    }
    pedidos = {
      methods = ["POST"]
      lambda  = aws_lambda_function.gestionar_pedidos
    }
    informes = {
      methods = ["GET"]
      lambda  = aws_lambda_function.generar_informes
    }
  }

  cors_response_headers = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  cors_integration_headers = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }
}

resource "aws_api_gateway_resource" "resource" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  parent_id   = aws_api_gateway_rest_api.productos_api.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "options" {
  for_each             = local.resources
  rest_api_id          = aws_api_gateway_rest_api.productos_api.id
  resource_id          = aws_api_gateway_resource.resource[each.key].id
  http_method          = "OPTIONS"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.body_validator.id
}

resource "aws_api_gateway_integration" "options" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"
  response_parameters = local.cors_response_headers
}

resource "aws_api_gateway_integration_response" "options" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"
  response_parameters = local.cors_integration_headers

  depends_on = [
    aws_api_gateway_integration.options,
    aws_api_gateway_method_response.options
  ]
}

resource "aws_api_gateway_method" "method" {
  for_each    = { for k, v in local.resources : k => v if length(v.methods) > 0 }
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = each.value.methods[0]
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  for_each    = { for k, v in local.resources : k => v if length(v.methods) > 0 }
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.method[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "method" {
  for_each    = { for k, v in local.resources : k => v if length(v.methods) > 0 }
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.method[each.key].http_method
  status_code = "200"
  response_parameters = local.cors_response_headers
}

resource "aws_api_gateway_integration_response" "method" {
  for_each    = { for k, v in local.resources : k => v if length(v.methods) > 0 }
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.method[each.key].http_method
  status_code = "200"
  response_parameters = local.cors_integration_headers

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.method
  ]
}

resource "aws_lambda_permission" "api_gateway_permissions" {
  for_each     = local.resources
  statement_id = "AllowAPIGatewayInvoke_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.productos_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration_response.method,
    aws_api_gateway_integration.options,
    aws_api_gateway_integration_response.options
  ]
}
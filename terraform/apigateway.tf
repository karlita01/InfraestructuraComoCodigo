resource "aws_api_gateway_rest_api" "productos_api" {
  name = "productos-api"
}

resource "aws_api_gateway_resource" "productos" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  parent_id   = aws_api_gateway_rest_api.productos_api.root_resource_id
  path_part   = "productos"
}

resource "aws_api_gateway_method" "options_productos" {
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  resource_id   = aws_api_gateway_resource.productos.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_productos_integration" {
  rest_api_id          = aws_api_gateway_rest_api.productos_api.id
  resource_id          = aws_api_gateway_resource.productos.id
  http_method          = aws_api_gateway_method.options_productos.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_productos_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.productos.id
  http_method = aws_api_gateway_method.options_productos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_method_response" "post_productos_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.productos.id
  http_method = aws_api_gateway_method.post_productos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "post_productos_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.productos.id
  http_method = aws_api_gateway_method.post_productos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [aws_api_gateway_integration.lambda_productos]
}

resource "aws_api_gateway_integration_response" "options_productos_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.productos.id
  http_method = aws_api_gateway_method.options_productos.http_method
  status_code = aws_api_gateway_method_response.options_productos_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [aws_api_gateway_integration.options_productos_integration]
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/productos-api"
  retention_in_days = 7
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_role.arn
}

resource "aws_api_gateway_method" "post_productos" {
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  resource_id   = aws_api_gateway_resource.productos.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_productos" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.productos.id
  http_method = aws_api_gateway_method.post_productos.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.guardar_producto.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_perm" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardar_producto.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.productos_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda_productos,
    aws_api_gateway_integration.lambda_pedidos,
    aws_api_gateway_integration_response.post_productos_integration_response,
    aws_api_gateway_integration_response.options_productos_integration_response,
    aws_api_gateway_integration_response.post_pedidos_integration_response,
    aws_api_gateway_integration_response.options_pedidos_integration_response,
    aws_api_gateway_integration.lambda_informes,
    aws_api_gateway_integration_response.get_informes_integration_response,
    aws_api_gateway_integration_response.options_informes_integration_response
  ]
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
}


resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  stage_name    = "prod"
    access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      caller          = "$context.identity.caller",
      user            = "$context.identity.user",
      requestTime     = "$context.requestTime",
      httpMethod      = "$context.httpMethod",
      resourcePath    = "$context.resourcePath",
      status          = "$context.status",
      protocol        = "$context.protocol",
      responseLength  = "$context.responseLength"
    })
  }
}

resource "aws_api_gateway_integration" "lambda_pedidos" {
  rest_api_id             = aws_api_gateway_rest_api.productos_api.id
  resource_id             = aws_api_gateway_resource.pedidos.id
  http_method             = aws_api_gateway_method.post_pedidos.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.gestionar_pedidos.invoke_arn
}

resource "aws_api_gateway_resource" "pedidos" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  parent_id   = aws_api_gateway_rest_api.productos_api.root_resource_id
  path_part   = "pedidos"
}

resource "aws_api_gateway_method" "post_pedidos" {
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  resource_id   = aws_api_gateway_resource.pedidos.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_pedidos" {
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  resource_id   = aws_api_gateway_resource.pedidos.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_pedidos_integration" {
  rest_api_id          = aws_api_gateway_rest_api.productos_api.id
  resource_id          = aws_api_gateway_resource.pedidos.id
  http_method          = aws_api_gateway_method.options_pedidos.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_pedidos_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.pedidos.id
  http_method = aws_api_gateway_method.options_pedidos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  depends_on = [aws_api_gateway_method.options_pedidos]
}

resource "aws_api_gateway_integration_response" "options_pedidos_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.pedidos.id
  http_method = aws_api_gateway_method.options_pedidos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [
    aws_api_gateway_integration.options_pedidos_integration,
    aws_api_gateway_method_response.options_pedidos_response
  ]
}

resource "aws_api_gateway_method_response" "post_pedidos_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.pedidos.id
  http_method = aws_api_gateway_method.post_pedidos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  depends_on = [aws_api_gateway_method.post_pedidos]
}

resource "aws_api_gateway_integration_response" "post_pedidos_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.pedidos.id
  http_method = aws_api_gateway_method.post_pedidos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [
    aws_api_gateway_integration.lambda_pedidos,
    aws_api_gateway_method_response.post_pedidos_response
  ]
}

resource "aws_lambda_permission" "api_gateway_perm_pedidos" {
  statement_id  = "AllowAPIGatewayInvokePedidos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gestionar_pedidos.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.productos_api.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "informes" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  parent_id   = aws_api_gateway_rest_api.productos_api.root_resource_id
  path_part   = "informes"
}

resource "aws_api_gateway_method" "options_informes" {
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  resource_id   = aws_api_gateway_resource.informes.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_informes_integration" {
  rest_api_id          = aws_api_gateway_rest_api.productos_api.id
  resource_id          = aws_api_gateway_resource.informes.id
  http_method          = aws_api_gateway_method.options_informes.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_informes_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.informes.id
  http_method = aws_api_gateway_method.options_informes.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "options_informes_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.informes.id
  http_method = aws_api_gateway_method.options_informes.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }
  depends_on = [
    aws_api_gateway_integration.options_informes_integration,
    aws_api_gateway_method_response.options_informes_response
  ]
}


resource "aws_api_gateway_integration" "lambda_informes" {
  rest_api_id             = aws_api_gateway_rest_api.productos_api.id
  resource_id             = aws_api_gateway_resource.informes.id
  http_method             = aws_api_gateway_method.get_informes.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generar_informes.invoke_arn
}


resource "aws_api_gateway_method_response" "get_informes_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.informes.id
  http_method = aws_api_gateway_method.get_informes.http_method  
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "get_informes_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.productos_api.id
  resource_id = aws_api_gateway_resource.informes.id
  http_method = aws_api_gateway_method.get_informes.http_method  
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [aws_api_gateway_integration.lambda_informes]
}

resource "aws_api_gateway_method" "get_informes" {
  rest_api_id   = aws_api_gateway_rest_api.productos_api.id
  resource_id   = aws_api_gateway_resource.informes.id
  http_method   = "GET" 
  authorization = "NONE"
}
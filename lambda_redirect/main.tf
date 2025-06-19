data "template_file" "auth_redirect" {
  template = file("${path.module}/auth_redirect_template.js")
  vars = {
    cognito_domain = var.cognito_domain
    client_id      = var.client_id
  }
}

resource "local_file" "auth_redirect_final" {
  content  = data.template_file.auth_redirect.rendered
  filename = "${path.module}/auth_redirect.js"
}

data "archive_file" "lambda_edge_zip" {
  type        = "zip"
  source_file = local_file.auth_redirect_final.filename
  output_path = "${path.module}/lambda_edge.zip"
}

resource "aws_lambda_function" "auth_redirect_edge" {
  filename         = data.archive_file.lambda_edge_zip.output_path
  function_name    = "authRedirectEdge"
  role             = var.lambda_role_arn
  handler          = "auth_redirect.handler"
  runtime          = "nodejs18.x"
  publish          = true
  source_code_hash = data.archive_file.lambda_edge_zip.output_base64sha256
}

output "lambda_arn" {
  value = aws_lambda_function.auth_redirect_edge.qualified_arn
}

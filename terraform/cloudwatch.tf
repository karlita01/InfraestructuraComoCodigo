resource "aws_cloudwatch_event_rule" "cada_minuto" {
  name                = "cada_minuto"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "target_lambda" {
  rule      = aws_cloudwatch_event_rule.cada_minuto.name
  target_id = "lambda"
  arn       = aws_lambda_function.generar_informes.arn
}

resource "aws_lambda_permission" "permitir_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generar_informes.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cada_minuto.arn
}

resource "aws_kms_key" "logs_key" {
  description         = "KMS key for CloudWatch log group encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid       = "Allow account to use the key"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = [
          "kms:*"
        ]
        Resource  = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
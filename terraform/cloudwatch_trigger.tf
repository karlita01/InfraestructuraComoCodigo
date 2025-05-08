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

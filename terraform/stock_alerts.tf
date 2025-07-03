resource "aws_sns_topic" "stock_alerts" {
  name = "stock-alerts"
}

resource "aws_sqs_queue" "stock_alerts_queue" {
  name = "stock-alerts-queue"
}

resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.stock_alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.stock_alerts_queue.arn
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.stock_alerts.arn
  protocol  = "email"
  endpoint  = "bensonlag200@gmail.com" 
}

resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.stock_alerts_queue.id
  policy    = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = "*",
      Action = "sqs:SendMessage",
      Resource = aws_sqs_queue.stock_alerts_queue.arn,
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.stock_alerts.arn
        }
      }
    }]
  })
}

data "archive_file" "lambda_verificar_stock" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/verificar_stock"
  output_path = "${path.module}/verificar_stock.zip"
}

resource "aws_lambda_function" "verificar_stock" {
  function_name    = "verificar_stock"
  role             = aws_iam_role.lambda_rds_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda_verificar_stock.output_path
  source_code_hash = data.archive_file.lambda_verificar_stock.output_base64sha256
  timeout          = 10

  vpc_config {
    subnet_ids         = local.lambda_config.vpc.subnet_ids
    security_group_ids = local.lambda_config.vpc.security_group_ids
  }

  environment {
    variables = merge(
      local.lambda_config.environment,
      { SNS_TOPIC_ARN = aws_sns_topic.stock_alerts.arn }
    )
  }
}
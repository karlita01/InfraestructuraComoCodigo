# Lambda function to generar informes

data "archive_file" "lambda_generar_informes" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/generar_informes"
  output_path = "${path.module}/generar_informes.zip"
}

resource "aws_lambda_function" "generar_informes" {
  function_name    = "generar_informes"
  role             = aws_iam_role.lambda_rds_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda_generar_informes.output_path
  source_code_hash = data.archive_file.lambda_generar_informes.output_base64sha256

  vpc_config {
  subnet_ids         = local.lambda_config.vpc.subnet_ids
  security_group_ids = local.lambda_config.vpc.security_group_ids
  }

  environment {
    variables = local.lambda_config.environment
  }
}

# Lambda function to gestionar pedidos

data "archive_file" "lambda_gestionar_pedidos" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/gestionar_pedidos"
  output_path = "${path.module}/gestionar_pedido.zip"
}

resource "aws_lambda_function" "gestionar_pedidos" {
  function_name    = "gestionar_pedidos"
  role             = aws_iam_role.lambda_rds_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda_gestionar_pedidos.output_path
  source_code_hash = data.archive_file.lambda_gestionar_pedidos.output_base64sha256

  vpc_config {
  subnet_ids         = local.lambda_config.vpc.subnet_ids
  security_group_ids = local.lambda_config.vpc.security_group_ids
  }

  environment {
    variables = local.lambda_config.environment
  }
}

# Lambda function to initialize the database

data "archive_file" "lambda_init_db" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/init_db"
  output_path = "${path.module}/init_db.zip"
}

resource "aws_lambda_function" "init_db" {
  function_name    = "init_db"
  role             = aws_iam_role.lambda_rds_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda_init_db.output_path
  source_code_hash = data.archive_file.lambda_init_db.output_base64sha256

  vpc_config {
  subnet_ids         = local.lambda_config.vpc.subnet_ids
  security_group_ids = local.lambda_config.vpc.security_group_ids
  }

  environment {
    variables = local.lambda_config.environment
  }
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "null_resource" "invoke_init_db" {
  depends_on = [
    aws_lambda_function.init_db,
    aws_db_instance.productos_db
  ]

  triggers = {
    lambda_code_hash = aws_lambda_function.init_db.source_code_hash
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.init_db.function_name} --payload '{}' NUL"
  }
}


resource "aws_security_group" "lambda_sg" {
  name        = "lambda-to-rds"
  description = "Permite a Lambda acceder a RDS"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_lambda_access_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}

# guardar producto lambda function

data "archive_file" "lambda_guardar_producto" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/gestionar_productos"
  output_path = "${path.module}/gestionar_productos.zip"
}

resource "aws_lambda_function" "guardar_producto" {
  function_name    = "guardar_producto"
  role             = aws_iam_role.lambda_rds_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda_guardar_producto.output_path
  source_code_hash = data.archive_file.lambda_guardar_producto.output_base64sha256
  timeout          = 10

  vpc_config {
  subnet_ids         = local.lambda_config.vpc.subnet_ids
  security_group_ids = local.lambda_config.vpc.security_group_ids
  }

  environment {
    variables = local.lambda_config.environment
  }
}
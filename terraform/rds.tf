resource "aws_db_instance" "productos_db" {
  allocated_storage     = local.rds_config.allocated_storage
  max_allocated_storage = local.rds_config.max_allocated_storage
  engine                = local.rds_config.engine
  engine_version        = local.rds_config.engine_version
  instance_class        = local.rds_config.instance_class
  db_name               = local.rds_config.db_name
  username              = local.rds_config.username
  password              = local.rds_config.password
  parameter_group_name  = local.rds_config.parameter_group_name
  publicly_accessible   = local.rds_config.publicly_accessible
  skip_final_snapshot   = local.rds_config.skip_final_snapshot

  deletion_protection = false

  auto_minor_version_upgrade = true

  monitoring_interval = 60

  multi_az = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  performance_insights_kms_key_id = aws_kms_key.logs_key.arn

  storage_encrypted = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade", "error", "general", "slowquery"]

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name        = "ProductosDB"
    Environment = "dev"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow access to RDS from the application"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permite acceso al puerto 5432 desde cualquier IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permite salida a cualquier destino"
  }
}

locals {
  rds_config = {
    allocated_storage    = var.db_allocated_storage
    max_allocated_storage = var.db_max_allocated_storage
    engine               = var.db_engine
    engine_version       = var.db_engine_version
    instance_class       = var.db_instance_class
    db_name              = var.db_name
    username             = var.db_username
    password             = var.db_password
    parameter_group_name = var.parameter_group_name
    publicly_accessible  = var.publicly_accessible
    skip_final_snapshot  = var.skip_final_snapshot
  }
}

locals {
  lambda_config = {
    environment = {
      DB_HOST     = aws_db_instance.productos_db.address
      DB_PORT     = aws_db_instance.productos_db.port
      DB_NAME     = local.rds_config.db_name
      DB_USER     = local.rds_config.username
      DB_PASSWORD = local.rds_config.password
    }

    vpc = {
      subnet_ids         = [aws_subnet.main.id, aws_subnet.secondary.id]
      security_group_ids = [aws_security_group.lambda_sg.id]
    }
  }
}

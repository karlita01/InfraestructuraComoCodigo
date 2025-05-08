resource "aws_db_instance" "productos_db" {
  allocated_storage    = 20
  max_allocated_storage = 100
  engine               = "postgres"
  engine_version       = "14.14"
  instance_class       = "db.t3.micro"
  db_name              = "productosdb" 
  username             = "dbadmin123"      
  password             = "dbadmin123" 
  parameter_group_name = "default.postgres14"
  publicly_accessible  = true
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name        = "ProductosDB"
    Environment = "dev"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow access to RDS from the application"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

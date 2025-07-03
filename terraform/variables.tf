variable "region" {
  description = "Región donde se desplegarán los recursos en AWS"
  type        = string
  default     = "us-east-2"
}

variable "db_allocated_storage" {
  description = "Tamaño inicial del almacenamiento para RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Tamaño máximo del almacenamiento para RDS (GB)"
  type        = number
  default     = 100
}

variable "db_engine" {
  description = "Motor de base de datos"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Versión del motor de base de datos"
  type        = string
  default     = "14.15"
}

variable "db_instance_class" {
  description = "Clase de instancia para RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "productosdb"
}

variable "db_username" {
  description = "Usuario para la base de datos"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña para la base de datos"
  type        = string
  sensitive   = true
}

variable "parameter_group_name" {
  description = "Grupo de parámetros de RDS"
  type        = string
  default     = "default.postgres14"
}

variable "publicly_accessible" {
  description = "Si la base de datos es accesible públicamente"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Si se debe omitir snapshot final"
  type        = bool
  default     = true
}

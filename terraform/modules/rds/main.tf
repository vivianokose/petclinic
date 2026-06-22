locals {
  tags = merge(
    {
      Project     = "petclinic"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  db_identifier   = "petclinic-${var.environment}-mysql"
  secret_name     = "petclinic/${var.environment}/rds-credentials-${random_id.secret_suffix.hex}"
  master_username = "petclinic_admin"
  database_name   = "petclinic"
}

# Random suffix for globally-unique names (e.g. Secrets Manager secret)
resource "random_id" "secret_suffix" {
  byte_length = 2
}

# Master password
resource "random_password" "master_password" {
  length           = 32
  special          = true
  override_special = "-_"
}

# DB parameter group: MySQL 8.0 with utf8mb4
resource "aws_db_parameter_group" "this" {
  name   = "petclinic-${var.environment}-mysql80"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = merge(
    local.tags,
    {
      Name = "petclinic-${var.environment}-mysql80"
    },
  )
}

# DB subnet group spanning the two public subnets
resource "aws_db_subnet_group" "this" {
  name       = "petclinic-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.tags,
    {
      Name = "petclinic-${var.environment}-db-subnet-group"
    },
  )
}

# RDS instance
resource "aws_db_instance" "this" {
  identifier     = local.db_identifier
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  multi_az = false

  db_name  = local.database_name
  username = local.master_username
  password = random_password.master_password.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = var.backup_retention_period

  tags = merge(
    local.tags,
    {
      Name = local.db_identifier
    },
  )
}

# Secrets Manager secret for RDS credentials
resource "aws_secretsmanager_secret" "this" {
  name        = local.secret_name
  description = "RDS credentials for petclinic ${var.environment}"

  tags = merge(
    local.tags,
    {
      Name = local.secret_name
    },
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = local.master_username
    password = random_password.master_password.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    database = local.database_name
  })
}

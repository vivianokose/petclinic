output "endpoint" {
  description = "RDS endpoint (host:port)"
  value       = "${aws_db_instance.this.address}:${aws_db_instance.this.port}"
  sensitive   = true
}

output "host" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
  sensitive   = true
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_instance_id" {
  description = "RDS DB instance ID"
  value       = aws_db_instance.this.id
}

output "secret_arn" {
  description = "Secrets Manager secret ARN for RDS credentials"
  value       = aws_secretsmanager_secret.this.arn
  sensitive   = true
}

output "secret_name" {
  description = "Secrets Manager secret name for RDS credentials"
  value       = aws_secretsmanager_secret.this.name
  sensitive   = true
}

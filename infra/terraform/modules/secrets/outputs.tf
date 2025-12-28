output "secret_arn" {
  description = "ARN of the secrets manager secret"
  value       = aws_secretsmanager_secret.credentials.arn
}

output "secret_name" {
  description = "Name of the secrets manager secret"
  value       = aws_secretsmanager_secret.credentials.name
}

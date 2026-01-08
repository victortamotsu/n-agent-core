output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_domain" {
  description = "Full Cognito domain URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "web_client_id" {
  description = "ID of the web app client"
  value       = aws_cognito_user_pool_client.web.id
}

output "web_client_secret" {
  description = "Secret of the web app client (if generated)"
  value       = aws_cognito_user_pool_client.web.client_secret
  sensitive   = true
}

# Data source for current region
data "aws_region" "current" {}

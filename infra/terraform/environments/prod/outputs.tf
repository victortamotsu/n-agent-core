# Cognito Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.web_client_id
}

output "cognito_domain" {
  description = "Cognito Domain URL"
  value       = module.cognito.cognito_domain
}

# API Gateway Outputs
output "api_endpoint" {
  description = "API Gateway Endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "api_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_id
}

# Lambda Outputs
output "lambda_bff_function_name" {
  description = "Lambda BFF Function Name"
  value       = module.lambda_bff.function_name
}

output "lambda_bff_function_arn" {
  description = "Lambda BFF Function ARN"
  value       = module.lambda_bff.function_arn
}

# Deployment Summary
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment        = var.environment
    api_endpoint       = module.api_gateway.api_endpoint
    cognito_pool_id    = module.cognito.user_pool_id
    cognito_client_id  = module.cognito.web_client_id
    lambda_bff         = module.lambda_bff.function_name
    agentcore_agent_id = var.agentcore_agent_id
  }
}


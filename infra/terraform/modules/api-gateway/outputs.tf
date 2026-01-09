output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = aws_apigatewayv2_api.main.arn
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "api_execution_arn" {
  description = "Execution ARN for Lambda permissions"
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "authorizer_id" {
  description = "ID of the Cognito authorizer"
  value       = aws_apigatewayv2_authorizer.cognito.id
}

output "stage_name" {
  description = "Name of the stage"
  value       = aws_apigatewayv2_stage.prod.name
}

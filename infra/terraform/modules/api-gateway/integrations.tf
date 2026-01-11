# API Gateway Integration Module
# Connects Lambda BFF to API Gateway routes
# Updated: Jan 11, 2026 - Enable integrations with JWT protection

# Integration with Lambda BFF
resource "aws_apigatewayv2_integration" "lambda_bff" {
  count = var.enable_integrations && var.lambda_invoke_arn != "" ? 1 : 0

  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.lambda_invoke_arn

  integration_method        = "POST"
  payload_format_version    = "2.0"
  timeout_milliseconds      = 30000
  
  request_parameters = {
    "overwrite:header.X-Request-Id" = "$context.requestId"
  }
}

# POST /chat route (protected)
resource "aws_apigatewayv2_route" "chat" {
  count = var.enable_integrations && var.lambda_invoke_arn != "" ? 1 : 0

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /chat"

  authorization_type = length(aws_apigatewayv2_authorizer.cognito) > 0 ? "JWT" : "NONE"
  authorizer_id      = length(aws_apigatewayv2_authorizer.cognito) > 0 ? aws_apigatewayv2_authorizer.cognito[0].id : null

  target = "integrations/${aws_apigatewayv2_integration.lambda_bff[0].id}"
}

# GET /health route (public)
resource "aws_apigatewayv2_integration" "health" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"

  target = "integrations/${aws_apigatewayv2_integration.health.id}"
}

# CORS Preflight (OPTIONS) - handled by CORS configuration in main API
# No need for explicit OPTIONS routes with AWS HTTP API CORS

# API Gateway Integration Module
# Connects Lambda BFF to API Gateway routes

# Integration with Lambda BFF
resource "aws_apigatewayv2_integration" "lambda_bff" {
  api_id           = var.api_id
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
  api_id    = var.api_id
  route_key = "POST /chat"

  authorization_type = var.authorizer_id != null ? "JWT" : "NONE"
  authorizer_id      = var.authorizer_id

  target = "integrations/${aws_apigatewayv2_integration.lambda_bff.id}"
}

# GET /health route (public)
resource "aws_apigatewayv2_integration" "health" {
  api_id           = var.api_id
  integration_type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  response_templates = {
    "application/json" = jsonencode({
      status  = "healthy"
      service = "n-agent-api"
      version = "1.0.0"
    })
  }
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = var.api_id
  route_key = "GET /health"

  target = "integrations/${aws_apigatewayv2_integration.health.id}"
}

# CORS Preflight (OPTIONS)
resource "aws_apigatewayv2_integration" "options" {
  api_id           = var.api_id
  integration_type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_apigatewayv2_route" "options" {
  api_id    = var.api_id
  route_key = "OPTIONS /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.options.id}"
}

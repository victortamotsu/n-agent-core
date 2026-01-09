# API Gateway HTTP API Module
# Provides REST API for n-agent with Cognito authentication

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "n-agent API Gateway - ${var.environment}"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = [
      "Content-Type",
      "Authorization",
      "X-Amz-Date",
      "X-Api-Key",
      "X-Amz-Security-Token"
    ]
    allow_credentials = true
    max_age           = 300
  }

  tags = merge(
    var.tags,
    {
      Name        = var.api_name
      Module      = "api-gateway"
      Environment = var.environment
    }
  )
}

# Production stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "prod"
  auto_deploy = true

  # Access logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  # Default route settings
  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

  tags = var.tags
}

# CloudWatch Log Group for API Gateway logs
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 30

  tags = merge(
    var.tags,
    {
      Name = "/aws/apigateway/${var.api_name}"
    }
  )
}

# Cognito Authorizer (only created when Cognito is configured)
resource "aws_apigatewayv2_authorizer" "cognito" {
  count = var.cognito_issuer_url != "" && var.cognito_app_client_id != "" ? 1 : 0

  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [var.cognito_app_client_id]
    issuer   = var.cognito_issuer_url
  }
}

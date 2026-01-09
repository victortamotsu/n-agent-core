# Production environment

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "n-agent-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "n-agent-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "n-agent-core"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Cognito User Pool for authentication
module "cognito" {
  source = "../../modules/cognito"

  user_pool_name   = "${var.project_name}-users-${var.environment}"
  user_pool_domain = "${var.project_name}-${var.environment}"

  callback_urls = [
    "http://localhost:5173/auth/callback",
    "https://app.n-agent.com/auth/callback"
  ]

  logout_urls = [
    "http://localhost:5173",
    "https://app.n-agent.com"
  ]

  # OAuth Providers (optional) - use google_oauth_* variables directly from workflow
  google_client_id        = var.google_oauth_client_id
  google_client_secret    = var.google_oauth_client_secret
  microsoft_client_id     = var.microsoft_client_id
  microsoft_client_secret = var.microsoft_client_secret
  microsoft_tenant_id     = var.microsoft_tenant_id

  tags = {
    Module = "cognito"
  }
}

# API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name    = "${var.project_name}-api-${var.environment}"
  environment = var.environment

  cors_allow_origins = [
    "http://localhost:5173",
    "https://app.n-agent.com"
  ]

  # Connect to Cognito
  cognito_issuer_url    = module.cognito.issuer_url
  cognito_app_client_id = module.cognito.web_client_id

  tags = {
    Module = "api-gateway"
  }
}

# Lambda BFF
module "lambda_bff" {
  source = "../../modules/lambda-bff"

  function_name = "${var.project_name}-bff-${var.environment}"

  agentcore_agent_id       = var.agentcore_agent_id
  agentcore_agent_alias_id = var.agentcore_agent_alias_id
  agentcore_agent_arn      = var.agentcore_agent_arn

  # Note: API Gateway integration will be created after both modules are provisioned
  api_gateway_execution_arn = "" # Will be set after first apply

  tags = {
    Module = "lambda-bff"
  }
}

# API Gateway Integrations (commented out - will be added after first apply)
# resource "aws_apigatewayv2_integration" "lambda_bff" {
#   api_id           = module.api_gateway.api_id
#   integration_type = "AWS_PROXY"
#   integration_uri  = module.lambda_bff.function_invoke_arn
#
#   integration_method     = "POST"
#   payload_format_version = "2.0"
#   timeout_milliseconds   = 30000
# }
#
# resource "aws_apigatewayv2_route" "chat" {
#   api_id    = module.api_gateway.api_id
#   route_key = "POST /chat"
#
#   authorization_type = "JWT"
#   authorizer_id      = module.api_gateway.authorizer_id
#
#   target = "integrations/${aws_apigatewayv2_integration.lambda_bff.id}"
# }

# Use root module configuration (existing infrastructure)
module "infrastructure" {
  source = "../.."

  # Pass all variables
  aws_region                 = var.aws_region
  environment                = var.environment
  project_name               = var.project_name
  agentcore_timeout          = var.agentcore_timeout
  agentcore_memory           = var.agentcore_memory
  router_model               = var.router_model
  chat_model                 = var.chat_model
  planning_model             = var.planning_model
  vision_model               = var.vision_model
  whatsapp_verify_token      = var.whatsapp_verify_token
  whatsapp_access_token      = var.whatsapp_access_token
  whatsapp_phone_number_id   = var.whatsapp_phone_number_id
  google_oauth_client_id     = var.google_oauth_client_id
  google_oauth_client_secret = var.google_oauth_client_secret
  facebook_app_id            = var.facebook_app_id
  facebook_app_secret        = var.facebook_app_secret
  microsoft_client_id        = var.microsoft_client_id
  microsoft_client_secret    = var.microsoft_client_secret
}

# Output all infrastructure outputs
output "infrastructure" {
  description = "All infrastructure outputs"
  value       = module.infrastructure
  sensitive   = true
}

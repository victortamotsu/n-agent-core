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

# Use root module configuration
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

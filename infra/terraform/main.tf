# Main Terraform configuration

# Secrets Manager module
module "secrets" {
  source = "./modules/secrets"

  project_name                = var.project_name
  environment                 = var.environment
  whatsapp_verify_token       = var.whatsapp_verify_token
  whatsapp_access_token       = var.whatsapp_access_token
  whatsapp_phone_number_id    = var.whatsapp_phone_number_id
  google_oauth_client_id      = var.google_oauth_client_id
  google_oauth_client_secret  = var.google_oauth_client_secret
  facebook_app_id             = var.facebook_app_id
  facebook_app_secret         = var.facebook_app_secret
  microsoft_client_id         = var.microsoft_client_id
  microsoft_client_secret     = var.microsoft_client_secret
}

# IAM roles module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  secret_arn   = module.secrets.secret_arn
}

# Storage module (S3 + DynamoDB)
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# Bedrock AgentCore module
module "agentcore" {
  source = "./modules/agentcore"

  project_name      = var.project_name
  environment       = var.environment
  timeout           = var.agentcore_timeout
  memory            = var.agentcore_memory
  router_model      = var.router_model
  chat_model        = var.chat_model
  planning_model    = var.planning_model
  vision_model      = var.vision_model
  iam_role_arn      = module.iam.agentcore_role_arn
  s3_bucket         = module.storage.documents_bucket
}

# WhatsApp Lambda module
module "whatsapp_webhook" {
  source = "./modules/whatsapp-lambda"

  project_name       = var.project_name
  environment        = var.environment
  iam_role_arn       = module.iam.lambda_role_arn
  secret_arn         = module.secrets.secret_arn
  agentcore_agent_id = module.agentcore.agent_id
}

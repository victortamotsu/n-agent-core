# Variables file - Production environment

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "n-agent-core"
}

variable "agentcore_timeout" {
  description = "AgentCore timeout in seconds"
  type        = number
  default     = 600
}

variable "agentcore_memory" {
  description = "AgentCore memory in MB"
  type        = number
  default     = 2048
}

variable "router_model" {
  description = "Bedrock model for router agent"
  type        = string
  default     = "us.amazon.nova-micro-v1:0"
}

variable "chat_model" {
  description = "Bedrock model for chat agent"
  type        = string
  default     = "us.amazon.nova-lite-v1:0"
}

variable "planning_model" {
  description = "Bedrock model for planning agent"
  type        = string
  default     = "us.amazon.nova-pro-v1:0"
}

variable "vision_model" {
  description = "Bedrock model for vision agent"
  type        = string
  default     = "us.amazon.nova-pro-v1:0"
}

variable "whatsapp_verify_token" {
  description = "WhatsApp webhook verification token"
  type        = string
  sensitive   = true
}

variable "whatsapp_access_token" {
  description = "WhatsApp API access token"
  type        = string
  sensitive   = true
}

variable "whatsapp_phone_number_id" {
  description = "WhatsApp phone number ID"
  type        = string
  sensitive   = true
}

variable "google_oauth_client_id" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
}

variable "google_oauth_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

variable "facebook_app_id" {
  description = "Facebook app ID"
  type        = string
  sensitive   = true
}

variable "facebook_app_secret" {
  description = "Facebook app secret"
  type        = string
  sensitive   = true
}

variable "microsoft_client_id" {
  description = "Microsoft OAuth client ID"
  type        = string
  sensitive   = true
}

variable "microsoft_client_secret" {
  description = "Microsoft OAuth client secret"
  type        = string
  sensitive   = true
}

variable "microsoft_tenant_id" {
  description = "Microsoft Azure AD Tenant ID"
  type        = string
  default     = "common"
}

# AgentCore Configuration
variable "agentcore_agent_id" {
  description = "AgentCore Agent ID (from .bedrock_agentcore.yaml)"
  type        = string
  default     = "nagent-GcrnJb6DU5"
}

variable "agentcore_agent_alias_id" {
  description = "AgentCore Agent Alias ID"
  type        = string
  default     = "TSTALIASID"
}

variable "agentcore_agent_arn" {
  description = "AgentCore Agent ARN"
  type        = string
  default     = "arn:aws:bedrock-agentcore:us-east-1:944938120078:runtime/nagent-GcrnJb6DU5"
}
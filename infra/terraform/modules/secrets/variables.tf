variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "whatsapp_verify_token" {
  description = "WhatsApp webhook verification token"
  type        = string
  sensitive   = true
}

variable "whatsapp_access_token" {
  description = "WhatsApp Business API access token"
  type        = string
  sensitive   = true
}

variable "whatsapp_phone_number_id" {
  description = "WhatsApp Business phone number ID"
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
  description = "Facebook App ID"
  type        = string
  sensitive   = true
}

variable "facebook_app_secret" {
  description = "Facebook App secret"
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

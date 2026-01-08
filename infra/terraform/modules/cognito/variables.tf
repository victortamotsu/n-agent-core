variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "n-agent-users"
}

variable "user_pool_domain" {
  description = "Domain prefix for Cognito hosted UI"
  type        = string
}

variable "callback_urls" {
  description = "List of callback URLs for OAuth"
  type        = list(string)
  default = [
    "http://localhost:5173/auth/callback",
    "http://localhost:3000/auth/callback"
  ]
}

variable "logout_urls" {
  description = "List of logout URLs"
  type        = list(string)
  default = [
    "http://localhost:5173",
    "http://localhost:3000"
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# OAuth Providers
variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "microsoft_client_id" {
  description = "Microsoft (Azure AD) Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "microsoft_client_secret" {
  description = "Microsoft (Azure AD) Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "microsoft_tenant_id" {
  description = "Microsoft (Azure AD) Tenant ID"
  type        = string
  default     = ""
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "n-agent-api"
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
  default     = "prod"
}

variable "cors_allow_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default = [
    "http://localhost:5173",
    "http://localhost:3000"
  ]
}

variable "cognito_issuer_url" {
  description = "Issuer URL of the Cognito User Pool for JWT authentication (format: https://cognito-idp.{region}.amazonaws.com/{user_pool_id})"
  type        = string
  default     = ""
}

variable "cognito_app_client_id" {
  description = "Cognito App Client ID for JWT audience"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

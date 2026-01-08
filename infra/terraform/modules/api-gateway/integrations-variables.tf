variable "api_id" {
  description = "API Gateway ID"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN"
  type        = string
}

variable "authorizer_id" {
  description = "Cognito authorizer ID"
  type        = string
  default     = null
}

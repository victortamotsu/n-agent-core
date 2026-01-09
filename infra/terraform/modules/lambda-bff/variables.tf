variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "n-agent-bff"
}

variable "agentcore_agent_id" {
  description = "AgentCore Agent ID"
  type        = string
}

variable "agentcore_agent_alias_id" {
  description = "AgentCore Agent Alias ID"
  type        = string
  default     = "TSTALIASID"
}

variable "agentcore_agent_arn" {
  description = "AgentCore Agent ARN for IAM permissions"
  type        = string
  default     = ""
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  type        = string
  default     = ""
}

# Note: AWS_REGION is not needed as Lambda environment variable
# It's automatically injected by the Lambda runtime

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

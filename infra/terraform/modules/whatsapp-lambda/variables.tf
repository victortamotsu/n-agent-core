variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for Lambda"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}

variable "agentcore_agent_id" {
  description = "AgentCore agent ID"
  type        = string
}

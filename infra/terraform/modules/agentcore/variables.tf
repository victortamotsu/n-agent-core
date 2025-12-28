variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "timeout" {
  description = "AgentCore timeout in seconds"
  type        = number
}

variable "memory" {
  description = "AgentCore memory in MB"
  type        = number
}

variable "router_model" {
  description = "Bedrock model for router agent"
  type        = string
}

variable "chat_model" {
  description = "Bedrock model for chat agent"
  type        = string
}

variable "planning_model" {
  description = "Bedrock model for planning agent"
  type        = string
}

variable "vision_model" {
  description = "Bedrock model for vision agent"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for AgentCore"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket for documents"
  type        = string
}

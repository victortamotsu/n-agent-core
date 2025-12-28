output "agent_id" {
  description = "AgentCore agent ID (from deployment)"
  value       = "deployed-via-cli" # Placeholder since CLI doesn't return ID
}

output "agent_arn" {
  description = "AgentCore agent ARN"
  value       = "arn:aws:bedrock:us-east-1:${data.aws_caller_identity.current.account_id}:agent/${var.project_name}-${var.environment}"
}

output "memory_id" {
  description = "Bedrock AgentCore memory ID"
  value       = aws_bedrockagent_knowledge_base.memory.id
}

output "memory_arn" {
  description = "Bedrock AgentCore memory ARN"
  value       = aws_bedrockagent_knowledge_base.memory.arn
}

data "aws_caller_identity" "current" {}

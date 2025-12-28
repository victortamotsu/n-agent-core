# Terraform outputs

output "agentcore_agent_id" {
  description = "Bedrock AgentCore agent ID"
  value       = module.agentcore.agent_id
}

output "agentcore_agent_arn" {
  description = "Bedrock AgentCore agent ARN"
  value       = module.agentcore.agent_arn
}

output "agentcore_memory_id" {
  description = "Bedrock AgentCore memory ID"
  value       = module.agentcore.memory_id
}

output "whatsapp_lambda_arn" {
  description = "WhatsApp Lambda function ARN"
  value       = module.whatsapp_webhook.lambda_arn
}

output "whatsapp_lambda_url" {
  description = "WhatsApp Lambda function URL"
  value       = module.whatsapp_webhook.lambda_url
}

output "whatsapp_sns_topic_arn" {
  description = "SNS topic ARN for WhatsApp messages"
  value       = module.whatsapp_webhook.sns_topic_arn
}

output "secrets_manager_arn" {
  description = "Secrets Manager secret ARN"
  value       = module.secrets.secret_arn
}

output "s3_documents_bucket" {
  description = "S3 bucket for documents"
  value       = module.storage.documents_bucket
}

output "dynamodb_table" {
  description = "DynamoDB table for application data"
  value       = module.storage.dynamodb_table
}

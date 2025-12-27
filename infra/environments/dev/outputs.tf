output "dynamodb_table_names" {
  description = "Names of DynamoDB tables"
  value = {
    core      = "n-agent-core-${var.environment}"
    chat      = "n-agent-chat-${var.environment}"
  }
}

output "s3_buckets" {
  description = "S3 bucket names"
  value = {
    documents = "n-agent-documents-${var.environment}"
    assets    = "n-agent-assets-${var.environment}"
  }
}

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.whatsapp_webhook.arn
}

output "lambda_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.whatsapp_webhook.function_name
}

output "lambda_url" {
  description = "Function URL for the Lambda"
  value       = aws_lambda_function_url.whatsapp_webhook.function_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.whatsapp_messages.arn
}

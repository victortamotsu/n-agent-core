output "agentcore_role_arn" {
  description = "ARN of the AgentCore IAM role"
  value       = aws_iam_role.agentcore.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

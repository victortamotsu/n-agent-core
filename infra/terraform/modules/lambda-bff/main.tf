# Lambda BFF Module
# Backend-for-Frontend Lambda that proxies API Gateway → AgentCore Runtime

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Data source for packaging Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/bff/src"
  output_path = "${path.module}/../../../lambdas/bff/lambda.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.function_name}-role"
    }
  )
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Bedrock Agent Runtime policy
resource "aws_iam_role_policy" "bedrock_agent" {
  name = "bedrock-agent-runtime"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeAgent",
          "bedrock-agent-runtime:InvokeAgent"
        ]
        Resource = var.agentcore_agent_arn != "" ? [var.agentcore_agent_arn] : ["*"]
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "bff" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda.arn
  handler         = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.12"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      AGENTCORE_AGENT_ID       = var.agentcore_agent_id
      AGENTCORE_AGENT_ALIAS_ID = var.agentcore_agent_alias_id
      AWS_REGION               = var.aws_region
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.function_name
    }
  )
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 30

  tags = var.tags
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  count = var.api_gateway_execution_arn != "" ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bff.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

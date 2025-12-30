# WhatsApp Lambda webhook module

# Use the pre-built lambda code zip file
# Note: The lambda code must be built before running terraform:
#   cd lambdas/whatsapp-webhook && npm run build
#   Then the zip file is generated and committed to the repo

resource "aws_lambda_function" "whatsapp_webhook" {
  filename         = "${path.module}/lambda-code.zip"
  function_name    = "${var.project_name}-${var.environment}-whatsapp-webhook"
  role             = var.iam_role_arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda-code.zip")
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      SECRET_ARN           = var.secret_arn
      SNS_TOPIC_ARN        = aws_sns_topic.whatsapp_messages.arn
      AGENTCORE_AGENT_ID   = var.agentcore_agent_id
      NODE_ENV             = var.environment
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lambda_function_url" "whatsapp_webhook" {
  function_name      = aws_lambda_function.whatsapp_webhook.function_name
  authorization_type = "NONE"

  cors {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}

resource "aws_sns_topic" "whatsapp_messages" {
  name = "${var.project_name}-${var.environment}-whatsapp-messages"

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "whatsapp_webhook" {
  name              = "/aws/lambda/${aws_lambda_function.whatsapp_webhook.function_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
  }
}

# DynamoDB Tables
resource "aws_dynamodb_table" "n_agent_core" {
  name           = "${var.project_name}-core-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = false
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "n-agent-core"
  }
}

resource "aws_dynamodb_table" "n_agent_chat" {
  name           = "${var.project_name}-chat-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "n-agent-chat"
  }
}

# S3 Buckets
resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-documents-${var.environment}"

  tags = {
    Name = "n-agent-documents"
  }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-assets-${var.environment}"

  tags = {
    Name = "n-agent-assets"
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lambda Functions
resource "aws_lambda_function" "whatsapp_bot" {
  function_name = "${var.project_name}-whatsapp-bot-${var.environment}"
  role          = aws_iam_role.whatsapp_bot_role.arn
  handler       = "webhook.handler"
  runtime       = "nodejs18.x"
  timeout       = 30
  memory_size   = 512

  filename         = "${path.module}/../../../services/whatsapp-bot/whatsapp-bot.zip"
  source_code_hash = fileexists("${path.module}/../../../services/whatsapp-bot/whatsapp-bot.zip") ? filebase64sha256("${path.module}/../../../services/whatsapp-bot/whatsapp-bot.zip") : "placeholder"

  environment {
    variables = {
      DYNAMODB_TABLE_CORE = aws_dynamodb_table.n_agent_core.name
      DYNAMODB_TABLE_CHAT = aws_dynamodb_table.n_agent_chat.name
      ENVIRONMENT         = var.environment
    }
  }

  tags = {
    Name = "whatsapp-bot"
  }
}

resource "aws_lambda_function" "trip_planner" {
  function_name = "${var.project_name}-trip-planner-${var.environment}"
  role          = aws_iam_role.trip_planner_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60
  memory_size   = 1024

  filename         = "${path.module}/../../../services/trip-planner/trip-planner.zip"
  source_code_hash = fileexists("${path.module}/../../../services/trip-planner/trip-planner.zip") ? filebase64sha256("${path.module}/../../../services/trip-planner/trip-planner.zip") : "placeholder"

  environment {
    variables = {
      DYNAMODB_TABLE_CORE = aws_dynamodb_table.n_agent_core.name
      S3_BUCKET_DOCUMENTS = aws_s3_bucket.documents.id
      ENVIRONMENT         = var.environment
    }
  }

  tags = {
    Name = "trip-planner"
  }
}

resource "aws_lambda_function" "integrations" {
  function_name = "${var.project_name}-integrations-${var.environment}"
  role          = aws_iam_role.integrations_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30
  memory_size   = 512

  filename         = "${path.module}/../../../services/integrations/integrations.zip"
  source_code_hash = fileexists("${path.module}/../../../services/integrations/integrations.zip") ? filebase64sha256("${path.module}/../../../services/integrations/integrations.zip") : "placeholder"

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "integrations"
  }
}

# CloudWatch Log Groups for Lambdas
resource "aws_cloudwatch_log_group" "whatsapp_bot" {
  name              = "/aws/lambda/${aws_lambda_function.whatsapp_bot.function_name}"
  retention_in_days = 7

  tags = {
    Name = "whatsapp-bot-logs"
  }
}

resource "aws_cloudwatch_log_group" "trip_planner" {
  name              = "/aws/lambda/${aws_lambda_function.trip_planner.function_name}"
  retention_in_days = 7

  tags = {
    Name = "trip-planner-logs"
  }
}

resource "aws_cloudwatch_log_group" "integrations" {
  name              = "/aws/lambda/${aws_lambda_function.integrations.function_name}"
  retention_in_days = 7

  tags = {
    Name = "integrations-logs"
  }
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "n-agent API Gateway for ${var.environment}"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }

  tags = {
    Name = "n-agent-api"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "default-stage"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "api-gateway-logs"
  }
}

# Lambda Integrations with API Gateway
resource "aws_apigatewayv2_integration" "whatsapp_bot" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "WhatsApp Bot Lambda integration"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.whatsapp_bot.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "trip_planner" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Trip Planner Lambda integration"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.trip_planner.invoke_arn
  payload_format_version = "2.0"
}

# API Routes
resource "aws_apigatewayv2_route" "whatsapp_webhook" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /webhooks/whatsapp"
  target    = "integrations/${aws_apigatewayv2_integration.whatsapp_bot.id}"
}

resource "aws_apigatewayv2_route" "whatsapp_verify" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /webhooks/whatsapp"
  target    = "integrations/${aws_apigatewayv2_integration.whatsapp_bot.id}"
}

resource "aws_apigatewayv2_route" "trips" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /api/v1/trips/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.trip_planner.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.trip_planner.id}"
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "whatsapp_bot_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.whatsapp_bot.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "trip_planner_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trip_planner.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

output "dynamodb_table_names" {
  description = "Names of DynamoDB tables"
  value = {
    core = "n-agent-core-${var.environment}"
    chat = "n-agent-chat-${var.environment}"
  }
}

output "s3_buckets" {
  description = "S3 bucket names"
  value = {
    documents = "n-agent-documents-${var.environment}"
    assets    = "n-agent-assets-${var.environment}"
  }
}

output "lambda_functions" {
  description = "Lambda function names and ARNs"
  value = {
    whatsapp_bot = {
      name = aws_lambda_function.whatsapp_bot.function_name
      arn  = aws_lambda_function.whatsapp_bot.arn
    }
    trip_planner = {
      name = aws_lambda_function.trip_planner.function_name
      arn  = aws_lambda_function.trip_planner.arn
    }
    integrations = {
      name = aws_lambda_function.integrations.function_name
      arn  = aws_lambda_function.integrations.arn
    }
  }
}

output "api_gateway" {
  description = "API Gateway URLs and details"
  value = {
    api_id       = aws_apigatewayv2_api.main.id
    api_endpoint = aws_apigatewayv2_api.main.api_endpoint
    urls = {
      health           = "${aws_apigatewayv2_api.main.api_endpoint}/health"
      whatsapp_webhook = "${aws_apigatewayv2_api.main.api_endpoint}/webhooks/whatsapp"
      trips            = "${aws_apigatewayv2_api.main.api_endpoint}/api/v1/trips"
    }
  }
}

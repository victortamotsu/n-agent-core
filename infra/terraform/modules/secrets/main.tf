# Secrets Manager module - stores sensitive credentials

resource "aws_secretsmanager_secret" "credentials" {
  name        = "${var.project_name}-${var.environment}-credentials"
  description = "Credentials for ${var.project_name} ${var.environment} environment"

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    whatsapp = {
      verify_token       = var.whatsapp_verify_token
      access_token       = var.whatsapp_access_token
      phone_number_id    = var.whatsapp_phone_number_id
    }
    oauth = {
      google = {
        client_id     = var.google_oauth_client_id
        client_secret = var.google_oauth_client_secret
      }
      facebook = {
        app_id     = var.facebook_app_id
        app_secret = var.facebook_app_secret
      }
      microsoft = {
        client_id     = var.microsoft_client_id
        client_secret = var.microsoft_client_secret
      }
    }
  })
}

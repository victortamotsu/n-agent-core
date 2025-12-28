variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  type        = string
}

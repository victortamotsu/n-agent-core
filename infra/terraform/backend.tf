# Backend configuration for Terraform state
# State stored in S3 with DynamoDB locking

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "n-agent-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "n-agent-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "n-agent-core"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

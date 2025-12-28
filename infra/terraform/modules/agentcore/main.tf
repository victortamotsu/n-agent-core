# Bedrock AgentCore module

# Note: This is a placeholder for AgentCore deployment
# AWS doesn't currently have native Terraform support for AgentCore Runtime
# We'll use null_resource with local-exec to deploy via CLI

data "archive_file" "agent_code" {
  type        = "zip"
  source_dir  = "${path.root}/../../agent/src"
  output_path = "${path.module}/agent-code.zip"
}

# ⚠️ COST WARNING: OpenSearch Serverless = $345.60/month minimum (2 OCUs)
# For POC/Fase 0-1: Consider commenting out OpenSearch resources below
# Agents work perfectly without Memory - just lose context between sessions
# Uncomment when you have 10+ paying customers to justify cost
# Alternative: Implement custom DynamoDB-based memory storage (~$5/month)

# Create Bedrock Agent Memory (EXPENSIVE - READ WARNING ABOVE)
resource "aws_bedrockagent_knowledge_base" "memory" {
  name        = "${var.project_name}-${var.environment}-memory"
  description = "Memory for ${var.project_name} agent"
  role_arn    = var.iam_role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.memory.arn
      vector_index_name = "bedrock-knowledge-base-default-index"

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}

# OpenSearch Serverless collection for memory
resource "aws_opensearchserverless_collection" "memory" {
  name = "${var.project_name}-${var.environment}-memory"
  type = "VECTORSEARCH"

  tags = {
    Environment = var.environment
  }
}

resource "aws_opensearchserverless_security_policy" "memory_encryption" {
  name = "${var.project_name}-${var.environment}-memory-encryption"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${aws_opensearchserverless_collection.memory.name}"
        ]
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "memory_network" {
  name = "${var.project_name}-${var.environment}-memory-network"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${aws_opensearchserverless_collection.memory.name}"
          ]
          ResourceType = "collection"
        }
      ],
      AllowFromPublic = true
    }
  ])
}

# Deploy AgentCore using CLI (since Terraform provider doesn't support it yet)
resource "null_resource" "agentcore_deploy" {
  triggers = {
    code_hash = data.archive_file.agent_code.output_md5
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.root}/../../agent && \
      export ROUTER_MODEL=${var.router_model} && \
      export CHAT_MODEL=${var.chat_model} && \
      export PLANNING_MODEL=${var.planning_model} && \
      export VISION_MODEL=${var.vision_model} && \
      export AWS_REGION=us-east-1 && \
      export BEDROCK_AGENTCORE_MEMORY_ID=${aws_bedrockagent_knowledge_base.memory.id} && \
      uv run agentcore configure --entrypoint src/main.py && \
      uv run agentcore launch --name ${var.project_name}-${var.environment}
    EOT

    environment = {
      AWS_REGION = "us-east-1"
    }
  }
}

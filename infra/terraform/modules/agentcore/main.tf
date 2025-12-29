# Bedrock AgentCore module

# Note: This is a placeholder for AgentCore deployment
# AWS doesn't currently have native Terraform support for AgentCore Runtime
# We'll use null_resource with local-exec to deploy via CLI

# Archive removed - AgentCore is deployed directly via CLI, no zip needed

# ============================================================================
# IMPORTANT: AgentCore Memory uses AWS-managed internal storage
# ============================================================================
# AgentCore Memory is a FULLY MANAGED service that does NOT require:
#   - OpenSearch Serverless ($345/month) ❌
#   - S3 Vectors ❌
#   - Aurora PostgreSQL ❌
#   - DynamoDB custom implementation ❌
#
# AWS handles all storage internally (likely DynamoDB + S3) at $0 extra cost.
# Memory is included in AgentCore Runtime pricing.
#
# To create Memory, use AWS CLI (NOT Terraform):
# 
#   aws bedrock-agentcore-control create-memory \
#     --name "${var.project_name}-${var.environment}-memory" \
#     --description "Session memory for ${var.project_name} agent" \
#     --strategies '[{
#       "summaryMemoryStrategy": {
#         "name": "SessionSummarizer",
#         "namespaces": ["/summaries/{actorId}/{sessionId}"]
#       }
#     }]' \
#     --region us-east-1
#
# Then store the Memory ID as a GitHub Secret: BEDROCK_AGENTCORE_MEMORY_ID
# and pass it as an environment variable to the agent runtime.
#
# For implementation, use the MemoryClient SDK in Python:
#   from bedrock_agentcore.memory import MemoryClient
#   memory = MemoryClient(region_name="us-east-1")
#   memory.create_event(memory_id=memory_id, messages=[...])
#
# References:
#   - https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory.html
#   - https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-sdk-memory.html
# ============================================================================


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
      uv run agentcore configure --entrypoint src/main.py && \
      uv run agentcore launch --name ${var.project_name}-${var.environment}
    EOT

    environment = {
      AWS_REGION = "us-east-1"
    }
  }
}

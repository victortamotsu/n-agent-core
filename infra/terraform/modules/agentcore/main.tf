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


# NOTE: AgentCore deployment is done manually via CLI, not through Terraform
# See the README for deployment instructions:
#   1. cd agent/
#   2. export ROUTER_MODEL=us.amazon.nova-micro-v1:0
#   3. export CHAT_MODEL=us.amazon.nova-lite-v1:0
#   4. export PLANNING_MODEL=us.amazon.nova-pro-v1:0
#   5. export VISION_MODEL=us.amazon.nova-pro-v1:0
#   6. uv run agentcore configure --entrypoint src/main.py
#   7. uv run agentcore launch --name n-agent-{env}


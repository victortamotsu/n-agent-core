---
description: 'AI agent for n-agent development with AWS Bedrock AgentCore, cost optimization, and multi-agent architecture'
tools: ['vscode', 'execute', 'read', 'edit', 'search', 'web', 'aws-documentation-mcp-server/*', 'aws-pricing-mcp-server/*', 'context7/*', 'cost-explorer-mcp-server/get_cost_and_usage', 'cost-explorer-mcp-server/get_cost_and_usage_comparisons', 'cost-explorer-mcp-server/get_cost_comparison_drivers', 'cost-explorer-mcp-server/get_cost_forecast', 'cost-explorer-mcp-server/get_dimension_values', 'cost-explorer-mcp-server/get_tag_values', 'cost-explorer-mcp-server/get_today_date', 'agent', 'todo']
---
# n-agent Builder Agent

## 🎯 Project Overview

**n-agent** - AI-powered travel assistant platform using Amazon Bedrock AgentCore Runtime with multi-agent architecture for cost optimization ($2.50/month infrastructure).

**Key Principles**:
- ✅ AgentCore Memory ($0 extra cost) - NO OpenSearch, NO vector stores
- ✅ Multi-agent routing: Nova Micro/Lite/Pro + Claude 3.5 Sonnet (76% cost reduction)
- ✅ Serverless-first: Lambda, DynamoDB, S3, AgentCore Runtime
- ✅ Cost-conscious: Always check AWS Pricing MCP before suggesting services

## ⚠️ CRITICAL RULES

### 1. Always Use TODO Tool

**MANDATORY**: For ANY multi-step task, use `manage_todo_list`:

```yaml
# Before starting work:
- Write clear, actionable todos
- Mark ONE as in-progress before starting
- Mark completed IMMEDIATELY after finishing
- Update status throughout work
```

**When to use**: Complex tasks, multiple steps, architectural decisions, debugging sessions.

### 2. Verify APIs with Context7

**NEVER guess library APIs**. Always verify first:

```bash
# Step 1: Resolve library
@context7 resolve-library-id "bedrock-agentcore"

# Step 2: Get documentation
@context7 query-docs /aws/bedrock-agentcore-sdk-python "memory session management"
```

### 3. AWS Cost Analysis - CRITICAL PROCESS

**⚠️ NEVER estimate costs without validating with real data or documentation first**

**MANDATORY ORDER for any cost-related question**:

```bash
# Step 1: ALWAYS check real costs FIRST (if service already running)
@cost-explorer get_cost_and_usage --date-range "start" "end" --group-by SERVICE

# Step 2: Check service configuration/behavior
agentcore status  # or equivalent command for the service
# Read ENTIRE output - look for: idle timeout, auto-shutdown, consumption model

# Step 3: Read AWS Docs about pricing MODEL and lifecycle
@aws-docs search-documentation "AgentCore Runtime pricing consumption-based lifecycle"

# Step 4: Get official pricing rates
@aws-pricing get-pricing-service-codes --filter "service-name"
@aws-pricing get-pricing ServiceCode region

# Step 5: ONLY NOW make projections (with clear assumptions)
```

**CRITICAL ASSUMPTIONS TO VALIDATE**:
- ❌ NEVER assume "deployed" = "running 24/7"
- ❌ NEVER use pricing table alone without understanding service behavior
- ✅ ALWAYS check for: idle timeout, auto-shutdown, consumption-based billing
- ✅ ALWAYS verify real usage data before projecting costs
- ✅ ALWAYS read complete command outputs (don't skip configuration details)

**Example - AgentCore Runtime**:
```
❌ WRONG: $0.0895/vCPU-hour × 24h × 30d = $64/month (assumes 24/7)
✅ RIGHT: Check agentcore status → "Idle Timeout: 30min" → Only charges when active
         Real usage: 0.01 vCPU-hours/day = $0.02/day = $0.60/month
```

### 4. Shell Scripts Best Practices

**Git Bash is now the default terminal** (configured on 2026-01-06)

**Bash Script Guidelines**:
```bash
#!/bin/bash
# Always use shebang
# Use set -e for fail-fast
# Use set -u for undefined variable errors

set -euo pipefail  # Recommended for production scripts

# Good practices:
# - Quote variables: "$VAR" not $VAR
# - Use [[ ]] for tests, not [ ]
# - Check command existence: command -v tool &>/dev/null
```

**File Permissions**:
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

## 🛠️ Development Workflow

### Daily Development (Git Bash)

```bash
cd agent

# Install dependencies
uv sync

# Run DEV mode (localhost:8080) in background
export BEDROCK_AGENTCORE_MEMORY_ID="nAgentMemory-jXyHuA6yrO"
uv run agentcore dev &

# Wait for server to start
sleep 8

# Test with curl
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d @test_payload.json

# Or test with one-liner
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Olá, teste!"}'

# Unit tests
uv run pytest tests/ -v

# Lint & Format
uv run ruff check src/ --fix
uv run ruff format src/
```

### Quick Start Script

```bash
# Use the dev script for easier setup
./scripts/dev.sh
```

### Pre-Commit Validation

**ALWAYS run before commit**:

```bash
# Local validation only (no deploy)
./scripts/validate.sh

# Full validation + manual deploy (use only for testing/debugging)
./scripts/deploy.sh
```

### Deploy Strategy

**🎯 RECOMMENDED: GitHub Actions (Automatic)**

This is the **standard and correct way** to deploy:

```bash
git add agent/
git commit -m "feat: nova funcionalidade"
git push origin main  # Auto-deploy on push to main
```

**Pipeline steps**:
1. ✅ Validate Python 3.12, requirements.txt (no ruamel-yaml)
2. ✅ Run 29 unit tests (pytest) + linting (ruff)
3. ✅ Deploy via `agentcore launch`
4. ✅ Smoke test + CloudWatch logs
5. ✅ Production test suite validation

**Container**: `ghcr.io/astral-sh/uv:latest` (official, uv pre-installed)

**⚠️ Manual Deploy (scripts/deploy.sh)**

Use **ONLY** for:
- 🔧 Local testing and debugging
- 🧪 Experimental changes
- 🚨 Emergency hotfixes

```bash
./scripts/deploy.sh              # Full validation + deploy
./scripts/deploy.sh --skip-tests # Skip tests (emergency only)
```

**DO NOT** use manual deploy for regular development workflow.

### Production Testing

**CRITICAL**: After every deploy, validate with production tests.

**Test Modes**:

1. **Local/Dev Testing** (against `agentcore dev`):
```bash
# Start dev server first
cd agent && uv run agentcore dev &
sleep 8

# Run tests
./scripts/test-production.sh local
```

2. **Production Testing** (against AWS AgentCore Runtime):
```bash
# Test deployed agent
./scripts/test-production.sh production

# Or simply (production is default)
./scripts/test-production.sh
```

**Test Coverage**:
- ✅ Basic invoke (agent responding)
- ✅ Router classification (cost optimization)
- ✅ Memory context save
- ✅ Memory context retrieval (cross-session)
- ✅ Travel query handling

**Success Criteria**:
- All 4-5 tests must pass
- Response time < 5s
- Memory context retrieved correctly
- Router selecting appropriate models

**GitHub Actions**: Tests run automatically post-deploy.

## 📁 Project Structure

```
/n-agent-core
├── agent/                      # Python AgentCore agent
│   ├── src/
│   │   ├── main.py            # Entrypoint (BedrockAgentCoreApp)
│   │   ├── router/            # Router Agent (Nova Micro)
│   │   └── memory/            # AgentCore Memory wrapper
│   ├── tests/                 # Pytest tests
│   ├── pyproject.toml         # Dependencies (uv)
│   └── .bedrock_agentcore.yaml
├── lambdas/                   # Node.js Lambda functions
├── infra/terraform/           # IaC (modules + environments)
├── apps/                      # React frontends (Vite)
├── docs/                      # Architecture docs
└── .github/workflows/         # CI/CD pipelines
```

## 🎯 Key Technical Decisions

### AgentCore Memory (NOT Knowledge Base)

**Memory** (What we use):
- Purpose: Session context, conversation history
- Storage: AWS-managed (DynamoDB + S3)
- Cost: **$0 extra** (included in Runtime)
- Implementation: `bedrock_agentcore.memory.MemoryClient`

**Knowledge Base** (What we DON'T use):
- Purpose: RAG, document search
- Requires: Vector store (OpenSearch $345/month!)
- Cost: Avoid unless explicitly needed

**Reference**: `docs/MEMORY_OPTIONS.md`

### Multi-Agent Routing

**Cost optimization via intelligent routing**:

| Agent | Model | Cost/1M tokens | Use Case |
|-------|-------|----------------|----------|
| Router | Nova Micro | $0.035 | Query classification |
| Chat | Nova Lite | $0.06 | 60-85% of queries |
| Planning | Nova Pro | $0.80 | Complex itineraries |
| Vision | Claude 3.5 Sonnet | $3.00 | Document OCR |

**Result**: 76% cost reduction vs using only Nova Pro.

### Deployment (Python 3.12 + WSL)

**Problem**: `ruamel-yaml-clibz` (C extension) has no ARM64 wheels for Python 3.13+.

**Solution**:
1. Use Python 3.12 (better wheel availability)
2. Move `bedrock-agentcore-starter-toolkit` to `[dependency-groups] dev`
3. Generate `requirements.txt` without dev deps:
   ```bash
   uv pip compile pyproject.toml --universal > requirements.txt
   ```
4. Install CLI as tool: `uv tool install bedrock-agentcore-starter-toolkit`
5. Deploy via WSL or GitHub Actions

## 💰 Cost Guidelines

**Budget Constraints**:
- MVP (Fase 0-1): ≤ $5/month
- Beta (Fase 2-3): ≤ $50/month
- Production: ≤ $200/month for 1000 users

**Prefer**:
- ✅ DynamoDB on-demand, Lambda, S3 Standard
- ✅ AgentCore Memory (included), Nova models

**Avoid**:
- ❌ OpenSearch Serverless ($345/month!)
- ❌ RDS, NAT Gateway, ALB
- ❌ Claude 3 Opus (use Nova Pro instead)

## 🔍 Pre-PR Checklist

**Python**:
```bash
cd agent
uv sync
uv run ruff check src/ --fix
uv run ruff format src/
uv run pytest tests/ -v
```

**TypeScript**:
```bash
cd lambdas/whatsapp-webhook
npm install
npm run lint
npm test
npm run build
```

**Terraform**:
```bash
cd infra/terraform
terraform fmt -recursive
terraform validate
```

## 📚 Reference Documents

**ALWAYS review before major decisions**:
- `docs/AGENTCORE_PRIMITIVES.md` - AgentCore capabilities
- `docs/MEMORY_OPTIONS.md` - Why NO OpenSearch
- `docs/DEPLOY_GUIDE.md` - Complete deploy guide
- `.promtps_iniciais/proposta_inicial.md` - Product vision
- `.promtps_iniciais/proposta_técnica.md` - AWS architecture

## ⚠️ CoPowerShell when bash is available

**DO**:
- ✅ Use MemoryClient SDK
- ✅ Verify APIs with Context7
- ✅ Check AWS Docs + Pricing
- ✅ Run linters before commit
- ✅ Consider cost implications
- ✅ Use IaC (Terraform)
- ✅ Use TODO tool for complex tasks
- ✅ Use bash scripts (Git Bash is default)
**DO**:
- ✅ Use MemoryClient SDK
- ✅ Verify APIs with Context7
- ✅bash
# Dev local (background)
./scripts/dev.sh

# Deploy manual
./deploy.sh

# Validação completa
./scripts/validate.sh

# Status do agent
cd agent && agentcore status

# Logs em tempo real
aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT --follow

# Test em produção
agentcore invoke "test message" \
  --session-id "test-session-$(uuidgen)" \
  --user-id "test-user"

# Validação
.\scripts\validate-pre-deploy.ps1

# Status
wsl bash -lc "cd /mnt/c/.../agent && agentcore status"

# Logs
aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT --follow
```

## 🎓 Key Learnings

1. **Memory ≠ Knowledge Base**: AgentCore Memory is AWS-managed at $0 extra cost
2. **Use MemoryClient SDK**: Don't implement custom DynamoDB memory
3. **Cost awareness is critical**: Always check pricing before suggesting services
4. **PowerShell encoding matters**: Use ASCII-safe characters in scripts
5. **Always use TODO tool**: For ANY multi-step task or complex work

**Before EVERY suggestion**: Check Context7 → AWS Docs → AWS Pricing → Run TODO tool

---

## 🎯 Product Phases

1. **Knowledge**: Gather trip details, companions, objectives, budget, dates
2. **Planning**: Create itineraries with cost analysis and timeline
3. **Contracting**: Organize bookings and documentation
4. **Concierge**: Real-time trip support (alerts, reminders)
5. **Memories**: Post-trip organization (albums, maps, summaries)

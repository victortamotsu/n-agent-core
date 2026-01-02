---
description: 'AI agent for n-agent development with AWS Bedrock AgentCore, cost optimization, and multi-agent architecture'
tools: ['vscode', 'execute', 'read', 'edit', 'search', 'web', 'aws-documentation-mcp-server/*', 'context7/*', 'cost-explorer-mcp-server/*', 'agent', 'aws-pricing-mcp-server/*', 'todo']
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

### 3. Check AWS Docs & Pricing

```bash
# Documentation
@aws-docs search-documentation "Bedrock AgentCore Memory API"

# Pricing (always before suggesting services)
@aws-pricing get-pricing-service-codes --filter "bedrock"
@aws-pricing get-pricing AWSLambda us-east-1
```

### 4. PowerShell Encoding (CRITICAL)

**Problem**: UTF-8 BOM causes parsing errors in PowerShell scripts.

**Solution**:
```powershell
# Use ASCII-safe characters only
# Avoid: ✅ ❌ 🚀 → • - *
# Use: OK, ERROR, SUCCESS, FAIL

# When creating PS1 files:
[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

# Or save as UTF-8 without BOM in VS Code
```

## 🛠️ Development Workflow

### Daily Development (Windows)

```powershell
cd agent

# Install dependencies
uv sync

# Run DEV mode (localhost:8080)
$env:BEDROCK_AGENTCORE_MEMORY_ID="nAgentMemory-jXyHuA6yrO"
uv run agentcore dev

# Test
curl -X POST http://localhost:8080/invocations `
  -H "Content-Type: application/json" `
  -d '{"prompt": "test"}'

# Unit tests
uv run pytest tests/ -v

# Lint & Format
uv run ruff check src/ --fix
uv run ruff format src/
```

### Pre-Commit Validation

**ALWAYS run before commit**:

```powershell
# 1. Tests
uv run pytest tests/ -v

# 2. Linter
uv run ruff check src/

# 3. Build validation (WSL - optional)
.\scripts\validate-pre-deploy.ps1
```

### Deploy Modes

**Mode 1: Manual (Emergency only)**:
```powershell
.\deploy.ps1              # Full validation + deploy
.\deploy.ps1 -SkipTests   # Skip tests (if already validated)
```

**Mode 2: GitHub Actions (Standard)**:
```bash
git add agent/
git commit -m "feat: nova funcionalidade"
git push origin main  # Auto-deploy on push to main
```

**Pipeline steps**:
1. Validate Python 3.11, requirements.txt (no ruamel-yaml)
2. Run pytest + ruff
3. Deploy via `agentcore launch`
4. Smoke test + CloudWatch logs

**Container**: `ghcr.io/astral-sh/uv:latest` (official, uv pre-installed)

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

## ⚠️ Common Pitfalls

**DON'T**:
- ❌ Suggest OpenSearch for Memory
- ❌ Mix Memory (sessions) with Knowledge Base (RAG)
- ❌ Use outdated Bedrock Agent APIs
- ❌ Deploy without checking AWS Pricing
- ❌ Skip tests before committing
- ❌ Guess library APIs (use Context7)
- ❌ Use UTF-8 BOM in PowerShell scripts

**DO**:
- ✅ Use MemoryClient SDK
- ✅ Verify APIs with Context7
- ✅ Check AWS Docs + Pricing
- ✅ Run linters before commit
- ✅ Consider cost implications
- ✅ Use IaC (Terraform)
- ✅ Use TODO tool for complex tasks
- ✅ Use ASCII-safe chars in PS1 files

## 🚀 Quick Commands

```powershell
# Dev local
cd agent && uv run agentcore dev

# Deploy manual (WSL)
.\deploy.ps1

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

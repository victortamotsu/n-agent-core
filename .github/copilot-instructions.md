# GitHub Copilot Custom Instructions - n-agent Project

## Project Context

You are working on **n-agent**, an AI-powered personal travel assistant platform that helps users organize, plan, and manage their trips from start to finish.

### Core Product Phases

1. **Knowledge Phase**: Gather trip details, companions, objectives, budget, dates
2. **Planning Phase**: Create detailed itineraries with cost analysis and timeline
3. **Contracting Phase**: Organize service bookings and trip documentation
4. **Concierge Phase**: Real-time support during the trip (alerts, reminders, assistance)
5. **Memories Phase**: Post-trip organization with albums, maps, and summaries

### Key Technical Decisions

- **AgentCore Memory**: AWS-managed session memory at **$0 extra cost** (NO OpenSearch, NO vector stores needed!)
- **Multi-Agent Architecture**: Router (Nova Micro) → Chat (Nova Lite) → Planning (Nova Pro) → Vision (Claude 3.5 Sonnet)
- **Serverless AWS**: Lambda, DynamoDB, S3, Bedrock AgentCore Runtime
- **Cost-Optimized**: $2.50/month infrastructure (saved $345/month by avoiding OpenSearch)

### Reference Documents

**ALWAYS review these before major decisions:**
- `#file:.promtps_iniciais/proposta_inicial.md` - Original product vision, business model, functional requirements
- `#file:.promtps_iniciais/proposta_técnica.md` - AWS architecture, integrations, data model, API contracts
- `#file:docs/AGENTCORE_PRIMITIVES.md` - AgentCore primitives guide (Runtime, Memory, Gateway, Identity, etc.)
- `#file:docs/MEMORY_OPTIONS.md` - Memory architecture decision (why we DON'T use OpenSearch)

## CRITICAL RULES - Read Before EVERY Task

### 1. Library/Package Documentation

**BEFORE suggesting any library or API usage:**

```bash
# Use MCP Context7 to get up-to-date documentation
@context7 resolve-library-id <library-name>
@context7 get-library-docs /org/project --topic "<relevant-topic>"
```

**Examples:**
- Bedrock AgentCore SDK: `@context7 get-library-docs /aws/bedrock-agentcore-sdk-python --topic "memory"`
- Strands Agents: `@context7 get-library-docs /aws/strands-agents --topic "agent routing"`
- AWS CDK: `@context7 get-library-docs /aws/aws-cdk --topic "lambda constructs"`

**Never guess API signatures or library capabilities!** Always verify with Context7 first.

### 2. AWS Product Information

**BEFORE implementing AWS services:**

```bash
# Use MCP AWS Documentation to get official AWS docs
@aws-docs search-documentation "<service> <feature>"
@aws-docs read-documentation <aws-docs-url>

# Use MCP AWS Pricing for cost analysis
@aws-pricing get-pricing-service-codes --filter "<service>"
@aws-pricing get-pricing AmazonEC2 us-east-1 --filters [...]
```

**Examples:**
- AgentCore Memory: `@aws-docs search-documentation "Bedrock AgentCore Memory session management"`
- Lambda pricing: `@aws-pricing get-pricing AWSLambda us-east-1`
- DynamoDB capacity: `@aws-docs read-documentation https://docs.aws.amazon.com/dynamodb/...`

**Cost awareness is critical!** Always check pricing before suggesting services.

### 3. Amazon Bedrock AgentCore Overview

**What is AgentCore?**

Amazon Bedrock AgentCore is an **agentic platform** for building, deploying, and operating AI agents securely at scale using any framework and foundation model. AgentCore services work together or independently with any open-source framework (CrewAI, LangGraph, LlamaIndex, Strands Agents) and any foundation model.

**Core Services (9 Primitives):**

1. **Runtime** - Serverless runtime for deploying and scaling AI agents with fast cold starts, extended runtime for async agents, true session isolation, and built-in identity.

2. **Memory** - Build context-aware agents with short-term (multi-turn conversations) and long-term memory (persists across sessions). **$0 extra cost** - AWS-managed storage included in Runtime.

3. **Gateway** - Convert APIs, Lambda functions, and services into MCP-compatible tools. Makes backend instantly accessible to agents without rewriting code.

4. **Identity** - Secure agent identity, access and authentication management compatible with existing IdPs (Cognito, Okta, Azure Entra ID, Auth0).

5. **Code Interpreter** - Isolated sandbox for agents to execute code (Python, JavaScript, TypeScript) to solve complex tasks.

6. **Browser** - Cloud-based browser runtime for agents to interact with web apps, fill forms, navigate websites (Playwright, BrowserUse).

7. **Observability** - Unified view to trace, debug, and monitor agent performance with OpenTelemetry-compatible format.

8. **Evaluations** - Automated, data-driven agent assessment measuring task execution, edge cases, and output reliability.

9. **Policy** - Deterministic control using natural language or Cedar to ensure agents operate within defined boundaries.

**Common Use Cases:**
- **Agents**: Autonomous AI apps for customer support, workflow automation, data analysis
- **Tools/MCP Servers**: Transform existing APIs into agent-compatible tools
- **Agent Platforms**: Provide internal developers with governed access to enterprise services

**Pricing**: Consumption-based, no upfront commitments or minimum fees.

**Reference**: `#file:docs/AGENTCORE_PRIMITIVES.md` for detailed implementation guidance.

### 4. AgentCore Memory Architecture

**CRITICAL: AgentCore Memory ≠ Knowledge Base**

✅ **AgentCore Memory** (What we use):
- Purpose: Session context, conversation history
- Storage: AWS-managed internal (DynamoDB + S3)
- Cost: **$0 extra** (included in Runtime)
- Setup: AWS CLI + MemoryClient SDK
- Use cases: Chat agents, task workflows, multi-agent systems

❌ **Knowledge Base** (What we DON'T use):
- Purpose: RAG, document search
- Storage: Requires vector store (OpenSearch $345/month or S3 Vectors $5/month)
- Cost: $5-345/month
- Use cases: Document Q&A, semantic search

**Reference implementation:** `#file:agent/src/memory/agentcore_memory.py`

### 4. Pre-PR Checklist

**ALWAYS perform these checks before committing code:**

#### Python Code (agent/)

```bash
cd agent

# 1. Install dependencies
uv sync

# 2. Run linter
uv run ruff check src/ --fix

# 3. Run formatter
uv run ruff format src/

# 4. Run type checker (if configured)
uv run mypy src/ --ignore-missing-imports

# 5. Run tests
uv run pytest tests/ -v

# 6. Test locally if possible
uv run python src/router/agent_router.py
```

#### TypeScript Code (lambdas/, apps/)

```bash
cd lambdas/whatsapp-webhook  # or relevant directory

# 1. Install dependencies
npm install

# 2. Run linter
npm run lint

# 3. Run formatter (if configured)
npm run format

# 4. Run type checker
npm run type-check  # or npx tsc --noEmit

# 5. Run tests
npm test

# 6. Build
npm run build
```

#### Terraform (infra/terraform/)

```bash
cd infra/terraform

# 1. Format
terraform fmt -recursive

# 2. Validate
terraform validate

# 3. Plan (check for drift)
terraform plan
```

#### Documentation

- [ ] Update relevant docs in `docs/` or `docs/migracao/`
- [ ] Update README.md if adding new features
- [ ] Update CHANGELOG.md (if exists)
- [ ] Add inline code comments for complex logic

### 5. Common Pitfalls to Avoid

❌ **DON'T:**
- Suggest OpenSearch Serverless for Memory (costs $345/month, not needed!)
- Mix up AgentCore Memory (sessions) with Knowledge Base (RAG)
- Use outdated Bedrock Agent APIs (use AgentCore Runtime instead)
- Hardcode AWS credentials (use IAM roles and environment variables)
- Deploy without cost analysis (check AWS Pricing first)
- Skip tests before committing
- Use deprecated libraries without checking Context7

✅ **DO:**
- Use AgentCore Memory SDK (`bedrock_agentcore.memory.MemoryClient`)
- Verify library APIs with Context7 before suggesting code
- Check AWS Documentation MCP for service capabilities
- Run linters and tests before every commit
- Consider cost implications of every AWS service
- Use IaC (Terraform) for all infrastructure
- Follow serverless best practices (Lambda layers, environment variables)

## Project Structure

```
/n-agent-core
├── agent/                      # Python agent code (Strands + Bedrock)
│   ├── src/
│   │   ├── main.py            # AgentCore Runtime entrypoint
│   │   ├── router/            # RouterAgent (Nova Micro classifier)
│   │   └── memory/            # AgentCore Memory wrapper
│   ├── tests/                 # Pytest tests
│   ├── pyproject.toml         # Python dependencies (UV)
│   └── .bedrock_agentcore.yaml # AgentCore deployment config
│
├── lambdas/                   # Node.js Lambda functions
│   ├── whatsapp-webhook/      # WhatsApp Business API handler
│   ├── bff/                   # Backend for Frontend
│   └── doc-generator/         # HTML/PDF document generator
│
├── infra/terraform/           # Infrastructure as Code
│   ├── modules/
│   │   ├── agentcore/         # Runtime deployment (NO OpenSearch!)
│   │   ├── whatsapp-lambda/   # Webhook Lambda + SNS
│   │   ├── secrets/           # Secrets Manager
│   │   ├── iam/               # IAM roles and policies
│   │   └── storage/           # S3 + DynamoDB
│   ├── environments/
│   │   ├── dev/               # Dev environment
│   │   └── prod/              # Production environment
│   └── bootstrap/             # One-time S3 + DynamoDB for Terraform state
│
├── apps/                      # Frontend applications
│   ├── web-client/            # React + Vite (user dashboard)
│   └── admin-panel/           # React (admin interface)
│
├── packages/                  # Shared libraries (monorepo)
│   ├── core-types/            # TypeScript interfaces
│   └── ui-lib/                # Design System (Material M3)
│
├── docs/                      # Documentation
│   ├── AGENTCORE_PRIMITIVES.md # AgentCore capabilities guide
│   ├── MEMORY_OPTIONS.md       # Memory architecture decision
│   ├── COST_ANALYSIS.md        # Cost breakdown by phase
│   ├── TERRAFORM_SETUP.md      # Infrastructure setup guide
│   └── migracao/               # Migration phases (Fase 0-5)
│
└── .github/
    ├── workflows/ci.yml        # CI/CD pipeline (lint, test, deploy)
    └── copilot-instructions.md # This file
```

## Cost Guidelines

### Budget Constraints

| Phase | Monthly Cost Target | Notes |
|-------|---------------------|-------|
| MVP (Fase 0-1) | ≤ $5/month | Avoid OpenSearch at all costs! |
| Beta (Fase 2-3) | ≤ $50/month | Add Gateway, Code Interpreter if needed |
| Production | ≤ $200/month for 1000 users | Scale with usage |

### Cost-Conscious Service Selection

**Prefer:**
- ✅ DynamoDB on-demand (pay-per-request)
- ✅ Lambda (serverless, pay-per-invocation)
- ✅ S3 Standard (cheap storage)
- ✅ AgentCore Memory (included in Runtime)
- ✅ Nova models (10-100x cheaper than Claude)

**Avoid (unless justified):**
- ❌ OpenSearch Serverless ($345/month minimum!)
- ❌ RDS (prefer DynamoDB)
- ❌ NAT Gateway ($32/month minimum)
- ❌ ALB ($16/month minimum, use API Gateway)
- ❌ Claude 3 Opus (use Nova Pro or Claude 3.5 Sonnet only when needed)

### Multi-Model Strategy (Cost Optimization)

| Query Type | Model | Cost per 1M tokens | Use Case |
|------------|-------|-------------------|----------|
| Routing | Nova Micro | $0.035 input | Classify query complexity |
| Simple chat | Nova Lite | $0.06 input | 60-85% of queries |
| Complex planning | Nova Pro | $0.80 input | Itinerary generation |
| Vision/OCR | Claude 3.5 Sonnet | $3.00 input | Document analysis |

**Rule:** Route 80% of queries to Nova Lite/Micro to keep costs low.

## Integration Guidelines

### MCP Context7 Usage Pattern

```python
# Step 1: Resolve library ID
resolved = await context7.resolve_library_id("bedrock-agentcore")
# Result: /websites/aws_amazon_bedrock-agentcore_devguide

# Step 2: Get documentation
docs = await context7.get_library_docs(
    context7CompatibleLibraryID="/websites/aws_amazon_bedrock-agentcore_devguide",
    topic="memory session management",
    mode="code"  # or "info" for conceptual docs
)

# Step 3: Implement based on actual API
```

### MCP AWS Documentation Pattern

```python
# Step 1: Search for relevant docs
search_results = await aws_docs.search_documentation(
    search_phrase="Bedrock AgentCore Memory API",
    search_intent="Understand Memory SDK usage",
    limit=10
)

# Step 2: Read specific documentation
content = await aws_docs.read_documentation(
    url="https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory.html",
    max_length=5000
)

# Step 3: Implement based on official docs
```

### MCP AWS Pricing Pattern

```python
# Step 1: Find service codes
services = await aws_pricing.get_pricing_service_codes(filter="bedrock")
# Result: ["AmazonBedrock", "AmazonBedrockAgentCore", ...]

# Step 2: Get pricing attributes
attributes = await aws_pricing.get_pricing_service_attributes("AWSLambda")
# Result: ["instanceType", "location", "memory", ...]

# Step 3: Get actual pricing
pricing = await aws_pricing.get_pricing(
    service_code="AWSLambda",
    region="us-east-1",
    filters=[
        {"Field": "memory", "Value": "1024", "Type": "EQUALS"}
    ]
)
```

## Development Workflow

### Starting a New Feature

1. **Read relevant docs:**
   - Check `#file:docs/migracao/` for phase-specific requirements
   - Review `#file:.promtps_iniciais/proposta_técnica.md` for architecture decisions

2. **Verify libraries:**
   - Use MCP Context7 to get up-to-date API documentation
   - Use MCP AWS Documentation for AWS service capabilities

3. **Check costs:**
   - Use MCP AWS Pricing to estimate new service costs
   - Ensure total monthly cost stays within budget

4. **Implement with tests:**
   - Write tests first (TDD when possible)
   - Follow pre-PR checklist before committing

5. **Update documentation:**
   - Update relevant docs in `docs/`
   - Add inline comments for complex logic

### CI/CD Best Practices for Monorepo

**Our Pipeline Optimizations:**

✅ **Path Filtering** - Avoid unnecessary builds:
```yaml
on:
  push:
    paths-ignore:
      - 'docs/**'
      - '**.md'
```

✅ **Dependency Caching** - Speed up CI:
```yaml
- name: Cache UV dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.cache/uv
      agent/.venv
    key: ${{ runner.os }}-uv-${{ hashFiles('agent/pyproject.toml') }}
```

✅ **Conditional Execution** - Run jobs only for affected code:
```yaml
if: contains(github.event.head_commit.modified, 'agent/') || github.event_name == 'pull_request'
```

✅ **Reproducible Builds** - Use `npm ci` instead of `npm install`

✅ **Parallel Jobs** - Lint and Test run simultaneously

**Reference**: Based on [Turborepo CI/CD best practices](https://turborepo.com/docs/crafting-your-repository/constructing-ci)

### Code Review Guidelines

**When reviewing code, check:**
- [ ] No OpenSearch usage (unless explicitly justified for Knowledge Base)
- [ ] AgentCore Memory used correctly (MemoryClient SDK, not custom implementation)
- [ ] Tests pass (`uv run pytest` or `npm test`)
- [ ] Linters pass (`uv run ruff` or `npm run lint`)
- [ ] Cost implications documented
- [ ] Documentation updated
- [ ] No hardcoded credentials
- [ ] Error handling implemented
- [ ] Logging added for debugging

## Useful Commands

### Agent Development

```bash
# Test RouterAgent locally
cd agent
uv run python src/router/agent_router.py

# Run all tests
uv run pytest tests/ -v

# Deploy to AgentCore Runtime
agentcore launch --wait

# Check deployed agent status
agentcore status

# Invoke deployed agent
agentcore invoke '{"prompt": "Olá!"}'
```

### Infrastructure Management

```bash
# Bootstrap Terraform backend (one-time)
cd infra/terraform/bootstrap
terraform init && terraform apply

# Deploy dev environment
cd infra/terraform/environments/dev
terraform init && terraform plan && terraform apply

# Check resources
aws dynamodb list-tables
aws s3 ls
aws bedrock-agentcore-control list-memories --region us-east-1
```

### CI/CD

```bash
# Run CI locally (simulates GitHub Actions)
cd agent
uv run ruff check src/
uv run pytest tests/

cd lambdas/whatsapp-webhook
npm run lint
npm test
npm run build
```

## Emergency Contacts & Resources

**AWS Documentation:**
- [AgentCore Developer Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)
- [Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

**MCP Servers:**
- Context7: Library documentation
- AWS Documentation: Official AWS docs
- AWS Pricing: Cost analysis

**Key Learnings (Don't Repeat These Mistakes):**
1. ❌ We initially included OpenSearch ($345/month) thinking it was required for Memory
   - ✅ Lesson: AgentCore Memory uses AWS-managed storage at $0 extra cost
   
2. ❌ We tried to implement custom DynamoDB-based memory
   - ✅ Lesson: Use MemoryClient SDK, AWS handles storage internally
   
3. ❌ We mixed up Knowledge Base (RAG) with AgentCore Memory (sessions)
   - ✅ Lesson: Memory = conversations, Knowledge Base = document search

## Final Reminder

**Before EVERY suggestion:**
1. ✅ Check MCP Context7 for library APIs
2. ✅ Check MCP AWS Docs for service capabilities
3. ✅ Check MCP AWS Pricing for cost implications
4. ✅ Review proposta_inicial.md and proposta_técnica.md
5. ✅ Run pre-PR checklist (lint, test, format)
6. ✅ Verify no OpenSearch usage (unless explicitly for Knowledge Base RAG)

**Cost awareness is not optional—it's critical to the project's viability!**

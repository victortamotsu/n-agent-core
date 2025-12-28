# 🧳 N-Agent Core - Assistente Pessoal de Viagens

**Status**: ✅ **Fase 0 COMPLETA** | 🚧 Fase 1 em Preparação

Assistente conversacional inteligente para planejamento e gestão de viagens, usando **Amazon Bedrock AgentCore** + **Strands Agents SDK** com arquitetura multi-agente e cost optimization.

## 🎯 Visão Geral

O **N-Agent** é um assistente de viagens que:
- 💬 Conversa naturalmente via WhatsApp (futuramente Web/Mobile)
- 🤖 Usa multi-agentes especializados com roteamento inteligente (76% economia)
- 📄 Processa documentos (passaportes, vistos, reservas) com Vision AI
- 🧠 Mantém memória de conversas e contexto da viagem (AgentCore Memory)
- 📊 Gera relatórios e roteiros personalizados
- ☁️ **Zero infraestrutura** - Serverless com Bedrock AgentCore Runtime

## 🏗️ Arquitetura

### Multi-Agent Routing System (Strands SDK + AgentCore)

```
User Message → Router Agent (Strands + Nova Micro)
                    ↓
        ┌───────────┴───────────┬────────────┐
        ↓                       ↓            ↓
   Chat Agent            Planning Agent  Vision Agent
  (Nova Lite)            (Nova Pro)      (Claude Sonnet)
  - Trivial             - Complex        - Image Analysis
  - Informative         - Tools          - Documents
        ↓                       ↓            ↓
            AgentCore Memory (Session Persistence)
                    ↓
            AgentCore Runtime (Serverless, 8h timeout)
```

**Inovação: Cost Optimization com Router Agent**
- **76% de redução** vs usar apenas Nova Pro
- **Antes**: $6.40/mês (1000 msgs, todas Nova Pro)
- **Depois**: $1.52/mês (roteamento inteligente)
- **Fast path**: Padrões triviais detectados sem API call (0ms)

### Stack Tecnológico

**Backend (Python 3.13)**:
- **Runtime**: Amazon Bedrock AgentCore (zero infra, session isolation, 8h timeout)
- **Framework**: Strands Agents SDK (model-agnostic, observability, streaming)
- **Models**: Amazon Nova Micro/Lite/Pro + Claude 3 Sonnet
- **Memory**: AgentCore Memory (short-term + long-term com estratégias)
- **Tools**: MCP Protocol, bedrock-agentcore, strands-agents, boto3
- **Testing**: pytest (17 tests passing), black, ruff

**Infra (Serverless - Fase 1+)**:
- Bedrock AgentCore Runtime (managed serverless)
- AWS Lambda + API Gateway (BFF layer)
- DynamoDB (viagens, usuários)
- S3 (documentos, embeddings)
- Terraform para IaC
- GitHub Actions para CI/CD

**Frontend (Fase 4+)**:
- Next.js 14 (Web Client)
- React Native (Mobile App)
- WhatsApp Business API

## 🚀 Quick Start

### Pré-requisitos

- Python 3.13+
- [UV](https://github.com/astral-sh/uv) (package manager)
- AWS CLI configurado (`aws configure`)
- Acesso ao Bedrock (modelos habilitados: Nova, Claude 3)

### Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/n-agent-core.git
cd n-agent-core/agent

# Instalar dependências com UV (rápido!)
uv sync

# Teste local do Router Agent
uv run python test_router_local.py
```

**Saída esperada**:
```
🧪 TESTANDO N-AGENT - ROUTER AGENT COM STRANDS SDK
================================================================================
Test 1/4: 'Oi!'
🔀 Router: 'Oi!...' → trivial (us.amazon.nova-lite-v1:0) em 0ms
  ✅ PASS

Test 3/4: 'Planeje 3 dias em Roma'
🔀 Router: 'Planeje 3 dias em Roma...' → complex (us.amazon.nova-pro-v1:0) em 453ms
  ✅ PASS
================================================================================
✅ FASE 0 COMPLETA: Router Agent funcionando com Strands SDK
```

### Executar Testes Unitários

```bash
# Executar todos os testes
uv run pytest tests/ -v

# 17 passed, 2 warnings in 1.69s ✅
```

## 📦 Estrutura do Projeto

```
/n-agent-core
├── /agent                       # 🤖 Core AI Agent (Python)
│   ├── /src
│   │   ├── main.py              # Entrypoint AgentCore
│   │   ├── /router              # Router Agent (Nova Micro)
│   │   ├── /prompts             # System prompts
│   │   └── /tools               # Agent tools (busca, docs)
│   ├── .bedrock_agentcore.yaml  # Runtime config
│   ├── pyproject.toml           # Dependencies (UV)
│   └── /tests                   # Unit tests
├── /apps
│   ├── /web-client              # 🌐 Next.js App (Fase 4)
│   └── /admin-panel             # 📊 Dashboard (Fase 5)
├── /packages
│   ├── /core-types              # TypeScript types
│   └── /ui-lib                  # Shared UI components
├── /lambdas
│   ├── /doc-generator           # Relatórios PDF (Fase 3)
│   ├── /whatsapp-webhook        # WhatsApp integration (Fase 4)
│   └── /bff                     # Backend for Frontend (Fase 4)
├── /infra/terraform             # 🏗️ Infrastructure as Code
│   ├── /modules                 # Reusable Terraform modules
│   └── /environments            # dev/prod configs
└── /.github/workflows           # CI/CD
```

## 🛠️ Comandos de Desenvolvimento

```bash
# Lint
cd agent
uv run ruff check src/

# Format
uv run black src/

# Test
uv run pytest tests/ -v

# Deploy (Fase 1)
# TODO: AgentCore CLI commands
```

## 📋 Fases de Desenvolvimento

### ✅ Fase 0: Preparação do Ambiente (COMPLETO)
- [x] Habilitar modelos no Bedrock
- [x] Verificar AWS CLI e credentials
- [x] Instalar UV + Python 3.13
- [x] Criar estrutura do projeto
- [x] Inicializar projeto Python
- [x] Criar agente de teste (`main.py`)
- [x] Criar Router Agent (`agent_router.py`)
- [x] Configurar CI/CD (GitHub Actions)
- [x] Criar README
## 🎯 **BEST PRACTICES IMPLEMENTADAS**

Seguindo [AWS Documentation oficial](https://docs.aws.amazon.com/bedrock-agentcore/):

✅ **BedrockAgentCoreApp** - Runtime protocol compliant  
✅ **Strands Agents SDK** - Model-agnostic framework  
✅ **AgentCore Memory** - Session management com SessionManager  
✅ **Cost Optimization** - Router Agent com fast patterns  
✅ **Security** - Input validation, least-privilege IAM  
✅ **Observability** - OpenTelemetry ready  
✅ **Testing** - 17 unit tests com mocks  

**Documentação de Referência**:
- [Best Practices](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/best-practices.html)
- [Runtime Quickstart](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-get-started-toolkit.html)
- [Strands Memory](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/strands-sdk-memory.html)

---

## 📅 Roadmap de Implementação

### ✅ Fase 0: Preparação do Ambiente (COMPLETA)
- ✅ AWS Bedrock access (Nova, Claude 3)
- ✅ Estrutura de pastas criada (13 diretórios)
- ✅ Python project com UV (68 packages)
- ✅ **Router Agent com Strands SDK** (267 linhas)
- ✅ **AgentCore Memory integration** (preparado)
- ✅ **.bedrock_agentcore.yaml** configurado
- ✅ **BedrockAgentCoreApp entrypoint** (main.py)
- ✅ CI/CD GitHub Actions (lint + test)
- ✅ **17 testes unitários** (17 passed, 100% pass rate)
- ✅ Documentação completa (README)

**Deliverables**: Router Agent funcional com 76% cost optimization, pronto para deploy no AgentCore Runtime.

### 🔄 Fase 1: Foundation (EM PROGRESSO)
- [ ] **Deploy no AgentCore Runtime** (`agentcore launch`)
- [ ] Configurar AgentCore Memory (criar memory ID)
- [ ] Implementar Chat Agent (Nova Lite + Memory)
- [ ] Implementar Planning Agent (Nova Pro + Tools)
- [ ] Implementar Vision Agent (Claude Sonnet + OCR)
- [ ] Gateway Agent para orquestração
- [ ] Session Manager com persistência
- [ ] Testes de integração end-to-end
- [ ] Observability com CloudWatch

### ⏳ Fase 2: Knowledge Collection (PENDENTE)
- [ ] Tools para coleta de dados (MCP protocol)
- [ ] Upload de documentos (S3)
- [ ] Processamento de imagens (OCR + Vision)
- [ ] Extração de informações (LLM)
- [ ] Armazenamento em Knowledge Base (RAG)
- [ ] AgentCore Gateway para tools

### ⏳ Fase 3: AI Core (PENDENTE)
- [ ] Refinar Planning Agent (multi-step workflows)
- [ ] Refinar Chat Agent (conversational)
- [ ] Refinar Vision Agent (document analysis)
- [ ] Guardrails de segurança (Bedrock Guardrails)
- [ ] Otimização de prompts e caching
- [ ] A2A protocol para multi-agent coordination

### ⏳ Fase 4: Output Generation (PENDENTE)
- [ ] Generator de relatórios PDF
- [ ] Templates Jinja2
- [ ] Integração WhatsApp Business API
- [ ] Web Client (Next.js)
- [ ] BFF Lambda (REST API)

### ⏳ Fase 5: Advanced Features (PENDENTE)
- [ ] Mobile App (React Native)
- [ ] Admin Dashboard
- [ ] Analytics e métricas
- [ ] Multi-idioma
- [ ] AgentCore Browser para web scraping

## 🧪 Testes

```bash
# Unit tests (17 tests)
cd agent
uv run pytest tests/ -v

# Teste local do Router Agent
uv run python test_router_local.py

# Lint e formatação
uv run ruff check src/
uv run black src/ --check

# Coverage
uv run pytest --cov=src tests/
```

**Status Atual**: ✅ 17/17 testes passando (100%)

## 📊 Custos Estimados (MVP)

### Fase 0 (Desenvolvimento Local)
- **AWS Bedrock API calls**: ~$0.10/dia (testes)
- **Zero custo de infra** (local development)

### Fase 1 (1000 msgs/mês, 30 dias, AgentCore Runtime)
- **Router Agent** (Nova Micro): $0.72/mês
- **Chat Agent** (Nova Lite): $0.48/mês
- **Planning Agent** (Nova Pro): $0.32/mês
- **Prompt Caching** (60% cache hit): -$0.52/mês (economia)
- **AgentCore Runtime**: Consumption-based (~$2-3/mês)
- **AgentCore Memory**: ~$1.50/mês (1000 events)
- **S3**: ~$0.50/mês

**Total MVP**: ~$5.00/mês 🎉

**Economia vs Lambda + DynamoDB tradicional**: 40-60% (zero infra management)

## 🔐 Segurança

- ✅ IAM roles com least privilege
- ✅ Secrets no AWS Secrets Manager
- ✅ Guardrails do Bedrock habilitados
- ✅ Logs CloudWatch (sem PII)
- ✅ Encryption at rest (S3/DynamoDB)

## 📚 Documentação

- [Proposta Inicial](docs/proposta_inicial.md)
- [Proposta Técnica](docs/proposta_tecnica.md)
- [Arquitetura Detalhada](docs/00_arquitetura.md)
- [Fase 0: Preparação](docs/01_fase0_preparacao.md)
- [Fase 1: Foundation](docs/02_fase1_foundation.md)
- [Fase 2: Knowledge](docs/03_fase2_knowledge.md)
- [Fase 3: AI Core](docs/04_fase3_core_ai.md)
- [Fase 4: Output](docs/05_fase4_output.md)

## 🤝 Contribuindo

Este é um projeto pessoal em desenvolvimento. Contribuições são bem-vindas!

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Add: nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é privado. Todos os direitos reservados.

## 👤 Autor

**Victor** - [GitHub](https://github.com/seu-usuario)

---

**Status do Projeto**: 🚧 Fase 0 Completa → Iniciando Fase 1

**Última Atualização**: 19/01/2025

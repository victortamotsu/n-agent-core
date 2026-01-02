# ✅ Checklist Fase 1 - Fundação (ATUALIZADO)

> **Documento de referência**: [02_fase1_fundacao.md](./02_fase1_fundacao.md)  
> **Atualização de escopo**: [MVP_SCOPE_UPDATE.md](./MVP_SCOPE_UPDATE.md)

---

## 📋 Pré-requisitos (Fase 0 - COMPLETO ✅)

- [x] Ambiente Python 3.13 + UV configurado
- [x] AWS CLI configurado com credenciais
- [x] Modelos Bedrock habilitados (Nova Micro/Lite/Pro, Claude Sonnet)
- [x] Router Agent implementado e testado
- [x] CI/CD pipeline funcionando (GitHub Actions)
- [x] Terraform modules prontos (secrets, iam, storage, agentcore)

---

## 🎯 Semana 1: AgentCore Deploy + Memory

### Dia 1-2: Deploy do Router Agent

- [x] Verificar `.bedrock_agentcore.yaml` está correto ✅
  - Corrigido para formato multi-agent com `default_agent: nagent`
  - Workaround `main.py` criado para bug do toolkit v0.2.5
  - AWS account ID adicionado (`944938120078`)
  - `memory_name` e `memory_id` configurados
- [x] **Configuração WSL 2 para Deploy** ✅
  - [x] WSL 2 Ubuntu instalado
  - [x] Python 3.11 (downgrade de 3.12 por compatibilidade)
  - [x] uv, AWS CLI configurados
  - [x] Projeto permanece em `C:\Users\victo\Projetos\n-agent-core\` (Windows)
  - [x] Venv criado via WSL em `/mnt/c/` path
  - [x] Dependências instaladas (SEM pywin32 ✓)
  - [x] Todos os 29 testes passando (via WSL)
  - [x] Mover `bedrock-agentcore-starter-toolkit` para `[dependency-groups] dev`
  - [x] Gerar `requirements.txt` SEM dev deps: `uv pip compile pyproject.toml`
  - [x] Instalar CLI como tool: `uv tool install bedrock-agentcore-starter-toolkit`
  - ✅ **Workflow**: Dev no Windows, Deploy via WSL
- [x] **Deploy Concluído!** ✅
  - [x] `wsl bash -lc "cd /mnt/c/.../agent && agentcore launch"`
  - [x] Agent ARN: `arn:aws:bedrock-agentcore:us-east-1:944938120078:runtime/nagent-GcrnJb6DU5`
  - [x] Package size: 73.99 MB
  - [x] Observability habilitada (CloudWatch + X-Ray)
  - ⚠️ **Erro 502 no invoke** - Investigar logs CloudWatch
- [ ] Testar endpoint funcionando
- [ ] Verificar logs e corrigir erro 502

### Dia 3-4: Configurar AgentCore Memory

- [x] Criar Memory ID via AWS CLI ✅
  - Memory ID: `nAgentMemory-jXyHuA6yrO` (ACTIVE)
  - Region: us-east-1
- [x] Atualizar `BEDROCK_AGENTCORE_MEMORY_ID` no `.bedrock_agentcore.yaml` ✅
- [x] Testar persistência de sessão ✅
  - Testado em dev mode: agente lembra nome, destino, datas
- [x] Verificar retrieval de contexto ✅
  - `get_last_k_turns()` funcionando corretamente

### Dia 5: Integração Memory no Agente

- [x] Atualizar `agent/src/main.py` com MemoryClient ✅
  - Integrado via `AgentCoreMemory` wrapper
  - Usando `create_event()` (API oficial documentada)
- [x] Testar ciclo completo: prompt → response → memory → retrieval ✅
  - 29 testes passando
  - Memória persistindo entre requests com mesmo session_id
- [x] **Deploy para Runtime** ✅ **CONCLUÍDO!**
  - Agent ARN: `arn:aws:bedrock-agentcore:us-east-1:944938120078:runtime/nagent-GcrnJb6DU5`
  - Deploy size: 73.99 MB
  - Observability habilitada (CloudWatch + X-Ray)
  - ⚠️ **Erro 502 no invoke** - Investigar logs CloudWatch

#### Solução do Deploy (ruamel-yaml-clibz issue)

**Problema**: `ruamel-yaml-clibz` (C extension) sem wheels ARM64  
**Solução aplicada**:
1. Mover `bedrock-agentcore-starter-toolkit` para `[dependency-groups] dev`
2. Gerar `requirements.txt` sem dev: `uv pip compile pyproject.toml`
3. Instalar CLI como tool: `uv tool install bedrock-agentcore-starter-toolkit`
4. Deploy: `wsl bash -lc "cd /mnt/c/.../agent && agentcore launch"`

---

## 📋 Terraform + CI/CD para AgentCore

**Status**: ✅ **CI/CD Implementado**

### Workflow de Desenvolvimento

1. **Desenvolvimento Local** (Windows):
   ```powershell
   cd agent
   $env:BEDROCK_AGENTCORE_MEMORY_ID="nAgentMemory-jXyHuA6yrO"
   uv run agentcore dev
   ```

2. **Deploy Manual** (WSL 2 quando necessário):
   ```powershell
   .\deploy.ps1              # Deploy completo
   .\deploy.ps1 -SkipTests   # Deploy sem testes
   ```

3. **Deploy Automático** (GitHub Actions):
   - Push para `main` → Deploy automático
   - Valida: Python 3.11, requirements.txt, testes, linter
   - Deploy: agentcore launch
   - Smoke test: agentcore invoke

### Scripts Criados

- ✅ `deploy.ps1` - Deploy manual com validação completa
- ✅ `scripts/validate-pre-deploy.ps1` - Validação pré-deploy
- ✅ `.github/workflows/deploy-agent.yml` - Pipeline CI/CD
- ✅ `.github/SECRETS.md` - Documentação de secrets

### Imagem Docker para CI/CD

**Escolhida**: `ghcr.io/astral-sh/uv:latest`

**Vantagens**:
- ✅ uv pré-instalado (fast dependency resolution)
- ✅ Python 3.11+ suportado
- ✅ Base Ubuntu com apt-get
- ✅ Mantido oficialmente pelo time do uv (Astral)
- ✅ Multi-arch (amd64 + arm64)

**Alternativas consideradas**:
- ❌ `python:3.11-slim` - requer instalar uv
- ❌ `ubuntu:latest` - requer instalar Python + uv
- ❌ Container customizado - overhead de manutenção

### GitHub Secrets Necessários

1. `AWS_DEPLOY_ROLE_ARN` - IAM Role para OIDC
2. `BEDROCK_AGENTCORE_MEMORY_ID` - Memory ID (nAgentMemory-jXyHuA6yrO)

Ver [.github/SECRETS.md](.github/SECRETS.md) para setup completo.

### Próximos Passos CI/CD

- [ ] Configurar OIDC Provider no AWS
- [ ] Criar IAM Role `GitHubActionsDeployRole`
- [ ] Adicionar secrets no GitHub
- [ ] Testar pipeline com push para branch `test`
- [ ] Merge para `main` após validação

---

## 🎯 Semana 2: DynamoDB + Cognito

### Dia 1-2: Tabelas DynamoDB

- [ ] Aplicar Terraform: `terraform apply` (module storage já configurado)
- [ ] Verificar tabela `n-agent-core` criada
- [ ] Testar operações CRUD básicas

### Dia 3-4: Cognito User Pool

- [ ] Criar User Pool no Console ou Terraform
- [ ] Configurar OAuth providers:
  - [ ] Email/Password (nativo)
  - [ ] Microsoft OAuth (opcional MVP)
  - [ ] Google OAuth (opcional MVP)
- [ ] Testar fluxo de sign-up/sign-in
- [ ] Integrar tokens JWT no BFF

### Dia 5: API Gateway + BFF Lambda

- [ ] Criar BFF Lambda estrutura básica
- [ ] Configurar API Gateway com Cognito Authorizer
- [ ] Endpoints mínimos:
  - [ ] `POST /chat` - Enviar mensagem ao agente
  - [ ] `GET /trips` - Listar viagens do usuário
  - [ ] `GET /health` - Health check

---

## 🎯 Semana 3: Sub-Agentes + Web Client Base

### Dia 1-2: Chat Agent (Nova Lite)

- [ ] Implementar `agent/src/agents/chat_agent.py`
- [ ] Configurar system prompt para conversação
- [ ] Testar respostas simples e informativas
- [ ] Integrar com Memory para contexto

### Dia 3: Planning Agent (Nova Pro)

- [ ] Implementar `agent/src/agents/planning_agent.py`
- [ ] Configurar system prompt para planejamento
- [ ] Testar geração de itinerários simples
- [ ] Preparar estrutura para tool calling

### Dia 4-5: Web Client Setup 🆕

> **NOVA PRIORIDADE**: Web Chat é interface principal do MVP!

- [ ] Criar projeto React + Vite em `apps/web-client/`
- [ ] Instalar dependências (MUI, React Query, React Router)
- [ ] Configurar tema Material Design M3
- [ ] Criar estrutura de pastas (components/, pages/, hooks/)
- [ ] Implementar `ChatWindow.tsx` básico

---

## 📊 Critérios de Sucesso Fase 1

### Funcional
- [x] Agente responde via AgentCore Runtime (dev mode) ✅
- [x] Memory persiste contexto entre sessões ✅
- [ ] DynamoDB armazena dados de viagem ⏳ Semana 2
- [ ] Cognito autentica usuários ⏳ Semana 2
- [ ] BFF Lambda expõe API REST ⏳ Semana 2
- [ ] **Web Client base funcionando** 🆕 ⏳ Semana 3

### Não-Funcional
- [x] Latência < 2s para respostas simples ✅ (testado em dev)
- [x] 100% de cobertura de testes críticos ✅ (29 testes passando)
- [ ] CI/CD deploy automático funcionando ⏳ Próximo
- [ ] Logs estruturados no CloudWatch ⏳ Após deploy

---

## 🌐 GCP + Gemini Integration (COMPLETADO ✅)

### Status
- [x] Projeto GCP criado: `n-agent-482519`
- [x] Vertex AI API habilitada
- [x] Service Account criada com permissões `Vertex AI User`
- [x] Credenciais JSON geradas e armazenadas em AWS Secrets Manager
- [x] Google Gen AI SDK instalado e testado
- [x] `agent/test_gemini.py` validado com sucesso
- [x] 14 modelos Gemini disponíveis (gemini-2.5-flash recomendado)
- [x] Documentação migrada para `docs/gcp/`

**Referência**: [docs/gcp/README.md](../../../../docs/gcp/README.md) | [docs/gcp/SETUP_GCP.md](../../../../docs/gcp/SETUP_GCP.md)

---

## ⚠️ O Que NÃO Fazer na Fase 1

- ❌ **NÃO** configurar webhook WhatsApp (Meta não aprovou)
- ❌ **NÃO** implementar Cache/Redis (AgentCore já tem)
- ❌ **NÃO** integrar Google Maps/Gemini no Router (esperar Fase 2)
- ❌ **NÃO** implementar Vision Agent completo (Fase 3)
- ❌ **NÃO** criar gerador de PDFs (Fase 4)

---

## 🔗 Próximos Passos (Fase 2)

Após completar Fase 1:
1. ✅ ~~Executar `SETUP_GCP.md` para configurar Gemini~~ (Completo!)
2. Integrar Gemini no Router Agent como modelo alternativo
3. Implementar fallback: Bedrock → Gemini
4. Implementar Google Maps tool
5. Implementar Gemini + Search Grounding
6. Adicionar tools ao Planning Agent

---

**Duração Estimada**: 3 semanas  
**Última atualização**: Junho 2025

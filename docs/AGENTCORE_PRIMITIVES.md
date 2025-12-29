# Primitivas do Amazon Bedrock AgentCore

## Documentação Completa

Este documento resume as primitivas disponíveis no AgentCore e quando usá-las em cada fase do projeto.

## Primitivas Disponíveis

### 1. **Runtime** (ESSENCIAL - Fase 0)
**O que é**: Ambiente serverless para hospedar agents e tools

**Características**:
- Framework agnostic (funciona com LangGraph, Strands, CrewAI, custom)
- Qualquer LLM (Bedrock, OpenAI, Anthropic, Google Gemini)
- Session isolation (microVM por usuário)
- Extended execution (até 8 horas)
- Consumption-based pricing (paga apenas pelo uso real)
- Built-in authentication
- 100MB payload support
- Bidirectional streaming (WebSocket)

**Quando usar**: Fase 0/1 - Deploy inicial do agente
**Implementação**: `agentcore launch` via CLI
**Custo**: Variável, ~$0.10/1000 invocações

---

### 2. **Memory** (ESSENCIAL - Fase 1)
**O que é**: Sistema gerenciado de memória para agents

**Características**:
- **Fully managed** - AWS gerencia storage internamente (DynamoDB + S3)
- Short-term memory (conversas dentro da sessão)
- Long-term memory (fatos persistentes entre sessões)
- Automatic fact extraction (AI extrai insights)
- Namespace-based organization
- Integração com LangGraph, LangChain, Strands, LlamaIndex

**Quando usar**: Fase 1 - Fundação
**Implementação**: 
```python
from bedrock_agentcore.memory import MemoryClient

memory = MemoryClient(region_name="us-east-1")
memory.create_event(memory_id=id, messages=[...])
memories = memory.retrieve_memories(memory_id=id, query="...")
```
**Custo**: **$0 extra** (incluído no Runtime pricing)
**NÃO requer**: OpenSearch, S3 Vectors, Aurora, DynamoDB custom

---

### 3. **Gateway** (IMPORTANTE - Fase 2)
**O que é**: Converte APIs/Lambda em ferramentas MCP-compatible

**Características**:
- Transforma OpenAPI/Smithy/Lambda em MCP tools
- Inbound auth (verifica identidade do agent)
- Outbound auth (conecta a third-party services via OAuth)
- Semantic tool search (agent descobre tools relevantes)
- 1-click integrations: Salesforce, Slack, Jira, Asana, Zendesk
- Serverless, fully managed

**Quando usar**: Fase 2 - Integrações
**Implementação**: 
1. Criar Gateway via Console/CLI
2. Adicionar targets (APIs, Lambda functions)
3. Configurar OAuth (se necessário)
4. Agent descobre tools automaticamente via MCP

**Custo**: Consumption-based, ~$0.05/1000 tool calls

---

### 4. **Identity** (ESSENCIAL - Fase 1)
**O que é**: Identity and credential management para agents

**Características**:
- Workload identities para agents
- Integração com IdPs (Cognito, Okta, Microsoft Entra ID, Auth0)
- Inbound auth (end users → agent)
- Outbound auth (agent → third-party services)
- OAuth flow management
- Secure credential storage
- Audit trails

**Quando usar**: Fase 1 - Fundação (junto com Cognito)
**Implementação**: Configuração via Console + IAM roles
**Custo**: Incluído no Runtime

---

### 5. **Built-in Tools** (OPCIONAL - Fase 3/4)
**O que são**: Ferramentas gerenciadas pela AWS

#### 5.1 Code Interpreter
- Sandbox isolado para executar código (Python, JavaScript, TypeScript)
- Útil para cálculos complexos, data analysis
- **Quando usar**: Fase 3 - se precisar análise de dados

#### 5.2 Browser Tool
- Ambiente de browser cloud-based
- Web scraping, form filling, navegação
- Suporta Playwright, BrowserUse
- **Quando usar**: Fase 5 - Concierge (buscar informações em tempo real)

**Implementação**: Ativar via configuração do agent
**Custo**: Consumption-based, ~$0.10/minuto de execução

---

### 6. **Observability** (RECOMENDADO - Fase 1)
**O que é**: Trace, debug e monitor agents em produção

**Características**:
- OpenTelemetry (OTEL) compatible
- Trace agent reasoning steps
- Tool invocations visualization
- Model interactions logging
- CloudWatch integration

**Quando usar**: Fase 1 - Fundação (desde o início)
**Implementação**: Automática via SDK
**Custo**: CloudWatch Logs pricing (~$0.50/GB)

---

### 7. **Evaluations** (OPCIONAL - Fase 4)
**O que é**: Avaliação automatizada de qualidade dos agents

**Características**:
- Automated testing
- Quality metrics
- Edge case handling
- Output reliability
- Integração com Observability

**Quando usar**: Fase 4 - Frontend (antes de produção)
**Implementação**: Via Strands/LangGraph frameworks
**Custo**: Consumption-based, ~$0.01/evaluation

---

### 8. **Policy** (IMPORTANTE - Fase 2/3)
**O que é**: Controle determinístico de ações dos agents

**Características**:
- Define regras usando natural language ou Cedar
- Intercepta tool calls antes da execução
- Fine-grained access control
- Business rules enforcement
- Integração com Gateway

**Quando usar**: Fase 2/3 - quando agents começam a usar tools
**Implementação**:
```
# Cedar policy example
permit(
  principal == Agent::"n-agent",
  action == Action::"invoke_tool",
  resource == Tool::"booking_api"
)
when {
  context.trip_budget < 10000
};
```
**Custo**: Incluído no Gateway

---

## Resumo: O que usar em cada fase

### Fase 0 - Preparação
- ✅ **Runtime** (deploy básico)
- ❌ Nenhuma outra primitiva ainda

### Fase 1 - Fundação
- ✅ **Runtime** (deploy completo)
- ✅ **Memory** (session management)
- ✅ **Identity** (autenticação com Cognito)
- ✅ **Observability** (logging desde o início)

### Fase 2 - Integrações
- ✅ **Gateway** (APIs de viagem, Google Maps)
- ✅ **Policy** (controles de acesso às ferramentas)
- ❌ Built-in Tools ainda não (mais tarde)

### Fase 3 - Core AI
- ✅ Todas as primitivas da Fase 1 e 2
- ✅ **Code Interpreter** (se precisar cálculos complexos)
- ❌ Browser Tool ainda não

### Fase 4 - Frontend
- ✅ **Evaluations** (testes antes de produção)
- ✅ Todas as outras primitivas operacionais

### Fase 5 - Concierge
- ✅ **Browser Tool** (buscar informações em tempo real)
- ✅ Todas as primitivas em produção

---

## Custos Estimados (1000 usuários/mês)

| Primitiva | Custo Mensal | Nota |
|-----------|--------------|------|
| Runtime | $10-20 | Consumption-based |
| Memory | **$0** | Incluído no Runtime |
| Gateway | $5-10 | Consumption-based |
| Identity | $0 | Incluído |
| Built-in Tools | $5-15 | Se usado |
| Observability | $5 | CloudWatch Logs |
| Evaluations | $2 | Pre-prod apenas |
| Policy | $0 | Incluído no Gateway |
| **TOTAL** | **$27-52/mês** | vs $375 com OpenSearch ❌ |

---

## Diferença Critical: Memory vs Knowledge Base

### AgentCore Memory
- **Propósito**: Session context, conversational history
- **Storage**: AWS-managed interno (DynamoDB + S3)
- **Custo**: $0 extra
- **Use cases**: Chat agents, task-oriented workflows, multi-agent systems
- **Setup**: CLI + MemoryClient SDK

### Knowledge Base (RAG)
- **Propósito**: Document search, RAG applications
- **Storage**: Requer vector store (OpenSearch $345/mês, S3 Vectors $5-10/mês)
- **Custo**: $5-345/mês dependendo do backend
- **Use cases**: Document Q&A, semantic search in large corpuses
- **Setup**: Terraform + data ingestion pipeline

**Para nosso projeto**: Usamos **AgentCore Memory** (session context), NÃO Knowledge Base (RAG).
**Custo**: $0 vs $345/mês com OpenSearch ✅

---

## Referencias

- [AgentCore Overview](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html)
- [AgentCore Memory](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory.html)
- [AgentCore Runtime](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agents-tools-runtime.html)
- [AgentCore Gateway](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html)
- [AgentCore Identity](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity.html)

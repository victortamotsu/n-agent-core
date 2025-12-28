# 🔄 Comparativo: Bedrock Agents vs. Bedrock AgentCore

## Resumo Executivo

| Aspecto | Bedrock Agents (atual) | Bedrock AgentCore (proposto) | Veredito |
|---------|------------------------|------------------------------|----------|
| **Complexidade** | Alta (muitos componentes) | Média (plataforma integrada) | ✅ AgentCore |
| **Custo Dev** | ~480h (12 semanas) | ~360h (9 semanas) | ✅ AgentCore |
| **Custo Operacional** | ~$300/mês | ~$255/mês | ✅ AgentCore |
| **Manutenção** | Alta | Baixa | ✅ AgentCore |
| **Flexibilidade** | Alta | Média | 🔄 Depende |
| **Maturidade** | GA (estável) | Novo (2024) | ⚠️ Agents |

---

## O que é cada um?

### Amazon Bedrock Agents

É o serviço **original** da AWS para criar agentes de IA. Você:
- Cria o Agent no console ou via Terraform
- Define Action Groups com OpenAPI schemas
- Implementa Lambdas para cada Action Group
- Gerencia memória e sessão manualmente (DynamoDB)
- Configura permissões IAM complexas

**Arquitetura atual do n-agent:**
```
WhatsApp → Lambda → EventBridge → Lambda Orchestrator → Bedrock Agent
                                         ↓
                                  Lambda Action Groups
                                         ↓
                                  DynamoDB (manual)
```

### Amazon Bedrock AgentCore

É a **evolução** lançada em 2024 que oferece uma plataforma completa:
- Runtime gerenciado (não precisa de Lambda)
- Memória built-in (STM para sessão, LTM para persistência)
- Gateway para integrações com OAuth nativo
- SDK Python (Strands) para definir agentes
- Deploy com um comando (`agentcore launch`)

**Arquitetura proposta:**
```
WhatsApp → Lambda Ingestion → AgentCore Runtime
                                    ↓
                              AgentCore Memory (STM + LTM)
                                    ↓
                              AgentCore Gateway → APIs externas
```

---

## Comparativo Detalhado

### 1. 🧠 Memória e Contexto

| Feature | Bedrock Agents | Bedrock AgentCore |
|---------|----------------|-------------------|
| Sessão (curto prazo) | DynamoDB manual | STM automático |
| Persistência (longo prazo) | DynamoDB manual | LTM com strategies |
| Busca semântica | Implementar | Built-in |
| Resumo de conversa | Implementar | SummaryStrategy |
| Perfil de usuário | DynamoDB manual | SemanticStrategy |

**Exemplo de código:**

```python
# BEDROCK AGENTS (atual) - você precisa implementar tudo
async def get_trip_context(trip_id: str):
    response = await dynamodb.get_item(
        TableName="NAgentCore",
        Key={"PK": f"TRIP#{trip_id}", "SK": "METADATA"}
    )
    # Buscar histórico...
    # Montar contexto...
    # Gerenciar tamanho...
    return context

# BEDROCK AGENTCORE (proposto) - built-in
trip_context = memory_client.retrieve_records(
    namespace=f"/trips/{trip_id}/facts",
    limit=50,
    semantic_search=True  # Busca semântica automática!
)
```

### 2. 🔧 Tools e Integrações

| Feature | Bedrock Agents | Bedrock AgentCore |
|---------|----------------|-------------------|
| Definição de tools | OpenAPI + Lambda | Python decorators |
| Deploy de tools | SAM/Terraform | Junto com runtime |
| OAuth para APIs | Lambda custom | Gateway nativo |
| Rate limiting | API Gateway manual | Gateway built-in |
| Circuit breaker | Implementar | Configurável |

**Exemplo de código:**

```python
# BEDROCK AGENTS (atual)
# 1. Criar OpenAPI schema
# 2. Criar Lambda
# 3. Configurar IAM
# 4. Deploy via SAM
# 5. Associar ao Agent

# BEDROCK AGENTCORE (proposto)
@tool
def search_hotels(city: str, checkin: str, checkout: str) -> dict:
    """Busca hotéis disponíveis"""
    return gateway.call("booking-api", "/hotels", {
        "city": city,
        "checkin": checkin,
        "checkout": checkout
    })
# Deploy: agentcore launch (inclui tudo)
```

### 3. 🚀 Deploy e Operações

| Feature | Bedrock Agents | Bedrock AgentCore |
|---------|----------------|-------------------|
| Deploy | Terraform + SAM | `agentcore launch` |
| Scaling | Lambda limits | Auto-managed |
| Versioning | Manual | Built-in |
| Rollback | Manual | One command |
| Logs | CloudWatch custom | X-Ray integrated |
| Tracing | Implementar | Automatic |

### 4. 💰 Custos Comparados (MVP)

**Bedrock Agents (atual):**
```
Lambda Orchestrator:     $5/mês
Lambda Action Groups:    $3/mês
Lambda WhatsApp:         $2/mês
DynamoDB (25 WCU/RCU):  $15/mês
S3 (docs):              $1/mês
API Gateway:            $5/mês
Bedrock (Claude):       $150/mês
Gemini (Vertex):        $50/mês
CloudWatch:             $10/mês
-----------------------------------
TOTAL:                  ~$241/mês + desenvolvimento
```

**Bedrock AgentCore (proposto):**
```
AgentCore Runtime:      $10/mês (inclui compute)
AgentCore Memory:       $55/mês (STM + LTM)
AgentCore Gateway:      $20/mês (inclui rate limiting)
Lambda Ingestion:       $2/mês (apenas WhatsApp)
Bedrock (Claude):       $150/mês
Gemini (Vertex):        $20/mês
-----------------------------------
TOTAL:                  ~$257/mês (mais features por preço similar)
```

---

## Mapeamento de Migração

### Código a ser migrado:

| Atual | AgentCore | Esforço |
|-------|-----------|---------|
| `services/ai-orchestrator/` | AgentCore Runtime | Alto (reescrever) |
| `services/action-groups/` | Tools no Runtime | Médio (adaptar) |
| `infra/prod/bedrock.tf` | CLI + Terraform | Médio |
| DynamoDB tables | AgentCore Memory | Baixo (configuração) |
| `services/whatsapp-bot/` | Manter + adaptar | Baixo |

### Código que permanece:

- ✅ `apps/web-client/` - Frontend React
- ✅ `apps/api-bff/` - BFF para web
- ✅ `packages/core-types/` - Tipos TypeScript
- ✅ `packages/logger/` - Logger
- ✅ `packages/utils/` - Utilidades

---

## Recomendação Final

### Para o n-agent, recomendo: **✅ Migrar para AgentCore**

**Porque:**

1. **Memória é crítica** para o fluxo de planejamento de viagem
   - AgentCore oferece memória semântica que vai economizar semanas de desenvolvimento
   
2. **Multi-fase é complexo** (Conhecimento → Planejamento → Contratação → Concierge)
   - AgentCore Memory permite transições suaves com contexto preservado

3. **Integrações externas são muitas** (Maps, Booking, Airbnb, etc)
   - AgentCore Gateway simplifica OAuth e rate limiting

4. **Observabilidade é essencial** para debugging de IA
   - X-Ray + Transaction Search são game changers

5. **Custo similar** com menos código para manter

### Quando NÃO usar AgentCore:

- Se precisar de controle total sobre cada componente
- Se tiver requisitos de compliance muito específicos
- Se o orçamento for extremamente limitado (free tier de Lambda)
- Se a equipe já dominar a arquitetura atual

---

## Próximos Passos

Se decidir por AgentCore:

1. **Semana 1**: Prova de conceito com Memory + Tool simples
2. **Semana 2**: Validar integração com WhatsApp existente
3. **Semana 3**: Migração progressiva começando pela fase de Conhecimento
4. **Semana 4-12**: Seguir plano em `PLANO_BEDROCK_AGENTCORE.md`

Se decidir manter Bedrock Agents:

1. Continuar com a implementação atual
2. Considerar usar apenas o AgentCore Memory como add-on
3. Implementar caching e observabilidade manualmente

# 🚀 Plano de Migração para Amazon Bedrock AgentCore

## Visão Geral

Este documento detalha o plano completo de implementação do n-agent usando **Amazon Bedrock AgentCore**, o serviço mais avançado da AWS para construção de agentes de IA.

---

## Por que AgentCore em vez de Bedrock Agents simples?

### Comparativo de Funcionalidades

| Necessidade do n-agent | Bedrock Agents | Bedrock AgentCore |
|------------------------|----------------|-------------------|
| Memória da viagem | ❌ DynamoDB manual | ✅ LTM Semântico built-in |
| Histórico de chat | ❌ Implementar | ✅ STM automático |
| OAuth (Google Maps, Booking) | ❌ Lambda custom | ✅ Workload Identity nativo |
| Múltiplos modelos (Claude + Gemini) | ❌ Código custom | ✅ Gateway multi-backend |
| Observabilidade | ❌ Logs custom | ✅ X-Ray + Transaction Search |
| Deploy | ❌ SAM/Terraform | ✅ `agentcore launch` |
| Multi-agent (futuro) | ❌ Arquitetura custom | ✅ A2A Protocol |

### Ganhos Estimados

- **Tempo de desenvolvimento**: -40% (não precisa construir memória e auth)
- **Custo operacional**: -30% (runtime gerenciado vs Lambdas)
- **Manutenção**: -50% (menos código custom)

---

## Arquitetura com AgentCore

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ENTRADA                                        │
├──────────────────┬───────────────────────────────────────────────────────────
│   WhatsApp       │   Web Chat        │   API BFF                           │
│   (Meta Webhook) │   (WebSocket)     │   (REST)                            │
└────────┬─────────┴────────┬──────────┴──────────┬───────────────────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    API Gateway + Lambda Ingestion                           │
│                    (Normaliza mensagens de todas as fontes)                 │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AMAZON BEDROCK AGENTCORE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         AGENTCORE RUNTIME                              │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐ │ │
│  │  │  n-agent Core   │  │  Memory Manager │  │  Observability          │ │ │
│  │  │  (Strands SDK)  │  │  STM + LTM      │  │  X-Ray + CloudWatch     │ │ │
│  │  └────────┬────────┘  └────────┬────────┘  └─────────────────────────┘ │ │
│  │           │                    │                                       │ │
│  │           ▼                    ▼                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │                     MEMORY SERVICE                              │   │ │
│  │  │  ┌─────────────┐  ┌──────────────────┐  ┌───────────────────┐   │   │ │
│  │  │  │ Semantic    │  │ Summary          │  │ User Profile      │   │   │ │
│  │  │  │ /trips/{id} │  │ /sessions/{sid}  │  │ /users/{uid}      │   │   │ │
│  │  │  └─────────────┘  └──────────────────┘  └───────────────────┘   │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        AGENTCORE GATEWAY                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │ │
│  │  │ MCP Server  │  │ OpenAPI     │  │ OAuth 2.0   │  │ Rate        │    │ │
│  │  │ Protocol    │  │ Targets     │  │ Manager     │  │ Limiting    │    │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────────────┘    │ │
│  └─────────┼────────────────┼────────────────┼────────────────────────────┘ │
└────────────┼────────────────┼────────────────┼──────────────────────────────┘
             │                │                │
             ▼                ▼                ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                         INTEGRAÇÕES EXTERNAS                               │
├─────────────────┬─────────────────┬─────────────────┬──────────────────────┤
│  Google Maps    │  Booking.com    │  Airbnb         │  OpenWeather         │
│  Places API     │  Affiliate API  │  Scraper/API    │  Weather API         │
├─────────────────┼─────────────────┼─────────────────┼──────────────────────┤
│  Vertex AI      │  AviationStack  │  DynamoDB       │  S3 Documents        │
│  Gemini Search  │  Flights API    │  Data Store     │  PDFs/HTML           │
└─────────────────┴─────────────────┴─────────────────┴──────────────────────┘
```

---

## Fases de Implementação

### Fase 1: Fundação AgentCore (Semanas 1-4)

#### Semana 1: Setup de Infraestrutura Base

**Tarefas:**
- [ ] Configurar conta AWS com permissões AgentCore
- [ ] Criar estrutura IaC base (Terraform ou CDK)
- [ ] Setup do monorepo com dependências AgentCore
- [ ] Configurar CI/CD com GitHub Actions
- [ ] Criar ambiente de desenvolvimento local

**Dependências Python (AgentCore SDK):**
```bash
# requirements.txt
strands-agents>=0.1.0
bedrock-agentcore>=0.1.0
boto3>=1.34.0
```

**Estrutura de Pastas:**
```
/services
  /agentcore-runtime         # Código do agente (Python)
    /src
      agent.py               # Definição do agente principal
      tools/                 # MCP Tools
        trip_context.py
        save_info.py
        search_places.py
      memory/
        strategies.py
    requirements.txt
    Dockerfile
  /ingestion                 # Lambda Node.js (WhatsApp/Web)
  /gateway                   # API Gateway handlers
```

#### Semana 2: Setup AgentCore Memory

**Tarefas:**
- [ ] Criar Memory com estratégias STM + LTM
- [ ] Configurar namespaces para trips, users, sessions
- [ ] Implementar estratégia semântica para facts
- [ ] Implementar estratégia de sumário para conversas
- [ ] Testar persistência e recuperação

**Código: Setup de Memory:**
```python
# services/agentcore-runtime/src/memory/setup_memory.py
from bedrock_agentcore_starter_toolkit.operations.memory.manager import MemoryManager
from bedrock_agentcore_starter_toolkit.operations.memory.models.strategies import (
    SemanticStrategy,
    SummaryStrategy
)

def create_n_agent_memory():
    """Cria e configura a memória do n-agent"""
    manager = MemoryManager(region_name="us-east-1")
    
    memory = manager.get_or_create_memory(
        name="n-agent-travel-memory",
        strategies=[
            # Memória semântica para fatos da viagem
            SemanticStrategy(
                name="TripFacts",
                description="Armazena fatos sobre viagens: destinos, datas, orçamento, preferências",
                namespaces=[
                    "/trips/{tripId}/facts",
                    "/users/{userId}/preferences",
                    "/trips/{tripId}/travelers/{travelerId}"
                ]
            ),
            # Resumo de conversas
            SummaryStrategy(
                name="ConversationSummary",
                description="Mantém resumo contextual das conversas",
                namespaces=[
                    "/sessions/{sessionId}/summary"
                ]
            ),
            # Histórico de ações
            SemanticStrategy(
                name="ActionHistory",
                description="Registro de ações e decisões tomadas",
                namespaces=[
                    "/trips/{tripId}/actions"
                ]
            )
        ]
    )
    
    return memory
```

#### Semana 3: Autenticação e WhatsApp

**Tarefas:**
- [ ] Configurar Cognito User Pool
- [ ] Implementar Lambda de webhook WhatsApp
- [ ] Configurar Meta Business API
- [ ] Criar normalização de mensagens
- [ ] Testar fluxo WhatsApp → AgentCore

**Arquitetura do Webhook:**
```python
# services/ingestion/whatsapp_handler.py
async def handle_whatsapp_message(event):
    """Recebe mensagem do WhatsApp e encaminha para AgentCore"""
    
    # 1. Extrair mensagem
    message = normalize_whatsapp_message(event)
    
    # 2. Identificar usuário
    user_id = message['from']
    session_id = get_or_create_session(user_id)
    
    # 3. Invocar AgentCore Runtime
    response = await invoke_agentcore(
        agent_endpoint=AGENTCORE_ENDPOINT,
        session_id=session_id,
        user_id=user_id,
        message=message['text'],
        memory_id=MEMORY_ID
    )
    
    # 4. Enviar resposta via WhatsApp
    await send_whatsapp_response(user_id, response)
```

#### Semana 4: Agente Base com Strands SDK

**Tarefas:**
- [ ] Implementar agente com Strands SDK
- [ ] Definir prompt base do n-agent
- [ ] Criar estrutura de tools básicos
- [ ] Configurar deploy com `agentcore launch`
- [ ] Testar conversa básica

**Código: Definição do Agente:**
```python
# services/agentcore-runtime/src/agent.py
from strands import Agent, tool
from bedrock_agentcore.memory import MemoryClient

SYSTEM_PROMPT = """
Você é o n-agent, um assistente pessoal especializado em planejamento de viagens.

## Sua Persona
- Nome: n-agent (pronuncia-se "ene-agent")
- Personalidade: Amigável, proativo, organizado e empático
- Tom: Informal mas profissional, use emojis com moderação

## Fases de Trabalho
1. **Conhecimento**: Coletar informações sobre a viagem
2. **Planejamento**: Criar roteiros e calcular custos
3. **Contratação**: Indicar melhores ofertas
4. **Concierge**: Acompanhar a viagem em tempo real

## Regras
- Pergunte uma coisa de cada vez
- Confirme informações importantes
- Use ferramentas para salvar dados coletados
- Nunca invente preços ou disponibilidade
- Mensagens curtas (máx 500 chars para WhatsApp)
"""

# Inicializa cliente de memória
memory_client = MemoryClient(memory_id=os.environ["MEMORY_ID"])

@tool
def get_trip_context(trip_id: str) -> dict:
    """Busca contexto completo de uma viagem"""
    records = memory_client.retrieve_records(
        namespace=f"/trips/{trip_id}/facts",
        limit=50
    )
    return {"trip_id": trip_id, "context": records}

@tool
def save_trip_info(trip_id: str, category: str, info: dict) -> dict:
    """Salva informação coletada sobre a viagem"""
    memory_client.create_event(
        namespace=f"/trips/{trip_id}/facts",
        payload={
            "category": category,
            "data": info,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    return {"status": "saved", "category": category}

# Criar agente
agent = Agent(
    model="anthropic.claude-3-5-sonnet-20241022-v2:0",
    system_prompt=SYSTEM_PROMPT,
    tools=[get_trip_context, save_trip_info],
    memory=memory_client
)

# Entrypoint para AgentCore Runtime
def handler(event, context):
    return agent.invoke(event)
```

---

### Fase 2: Core AI e Tools (Semanas 5-7)

#### Semana 5: Tools de Integração

**Tarefas:**
- [ ] Tool: `search_places` - Google Maps Places API
- [ ] Tool: `search_weather` - OpenWeather API
- [ ] Tool: `search_hotels` - Booking Affiliate API
- [ ] Configurar Gateway com OpenAPI specs
- [ ] Testar cada tool individualmente

**Código: Tool de Busca de Lugares:**
```python
# services/agentcore-runtime/src/tools/search_places.py
from strands import tool
import httpx

GOOGLE_MAPS_API_KEY = os.environ["GOOGLE_MAPS_API_KEY"]

@tool
def search_places(
    query: str,
    location: str,
    type: str = "tourist_attraction",
    max_results: int = 5
) -> dict:
    """
    Busca lugares usando Google Maps Places API.
    
    Args:
        query: Termo de busca (ex: "restaurantes italianos")
        location: Cidade ou coordenadas (ex: "Paris, France")
        type: Tipo de lugar (tourist_attraction, restaurant, hotel, etc)
        max_results: Número máximo de resultados
    
    Returns:
        Lista de lugares com nome, endereço, rating e fotos
    """
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params={
            "query": f"{query} in {location}",
            "type": type,
            "key": GOOGLE_MAPS_API_KEY
        })
        
        data = response.json()
        
        places = []
        for place in data.get("results", [])[:max_results]:
            places.append({
                "name": place["name"],
                "address": place.get("formatted_address"),
                "rating": place.get("rating"),
                "total_ratings": place.get("user_ratings_total"),
                "place_id": place["place_id"],
                "types": place.get("types", [])
            })
        
        return {
            "query": query,
            "location": location,
            "results": places,
            "total_found": len(places)
        }
```

#### Semana 6: Fluxo de Conhecimento

**Tarefas:**
- [ ] Implementar máquina de estados das fases
- [ ] Criar prompt específico para fase de conhecimento
- [ ] Implementar coleta estruturada de dados
- [ ] Criar score de completude do conhecimento
- [ ] Transição automática para planejamento

**Código: Gerenciador de Fases:**
```python
# services/agentcore-runtime/src/phases/manager.py
from enum import Enum
from dataclasses import dataclass

class TripPhase(Enum):
    KNOWLEDGE = "knowledge"      # Coletando informações
    PLANNING = "planning"        # Criando roteiro
    BOOKING = "booking"          # Contratando serviços
    CONCIERGE = "concierge"      # Acompanhando viagem
    MEMORIES = "memories"        # Pós-viagem

@dataclass
class KnowledgeProgress:
    """Tracks what information has been collected"""
    has_destination: bool = False
    has_dates: bool = False
    has_travelers: bool = False
    has_budget: bool = False
    has_preferences: bool = False
    
    @property
    def score(self) -> float:
        """Returns completion percentage (0-100)"""
        fields = [
            self.has_destination,
            self.has_dates, 
            self.has_travelers,
            self.has_budget,
            self.has_preferences
        ]
        return (sum(fields) / len(fields)) * 100
    
    @property
    def can_proceed_to_planning(self) -> bool:
        """Minimum requirements to start planning"""
        return self.has_destination and self.has_dates and self.has_travelers

KNOWLEDGE_PHASE_PROMPT = """
## Fase Atual: CONHECIMENTO

Você está coletando informações sobre a viagem. Pergunte sobre:

1. **Destino(s)**: Países, cidades ou regiões que deseja visitar
2. **Datas**: Período da viagem (flexível ou fixo?)
3. **Viajantes**: Quantos? Adultos, crianças? Restrições?
4. **Orçamento**: Valor total ou por pessoa?
5. **Preferências**: Tipo de hospedagem, ritmo, interesses

### Regras desta fase:
- Pergunte UMA informação por vez
- Confirme antes de salvar
- Use a tool `save_trip_info` para cada dado coletado
- Quando tiver destino + datas + viajantes, pergunte se quer começar o planejamento

### Progresso atual:
{progress_summary}
"""
```

#### Semana 7: Integração Gemini + Search

**Tarefas:**
- [ ] Configurar Vertex AI no Gateway
- [ ] Implementar tool de busca web com Gemini
- [ ] Criar fallback Claude ↔ Gemini
- [ ] Implementar cache de buscas
- [ ] Testar buscas de recomendações

**Código: Tool Gemini Search:**
```python
# services/agentcore-runtime/src/tools/web_search.py
from strands import tool
from google.cloud import aiplatform
from vertexai.preview.generative_models import GenerativeModel

@tool
def search_travel_recommendations(
    query: str,
    context: str = "",
    search_type: str = "general"
) -> dict:
    """
    Busca recomendações de viagem usando Gemini + Google Search.
    
    Args:
        query: Pergunta ou termo de busca
        context: Contexto adicional sobre a viagem
        search_type: Tipo de busca (hotels, restaurants, attractions, tips)
    
    Returns:
        Recomendações com fontes e links
    """
    model = GenerativeModel(
        "gemini-2.0-flash-exp",
        tools=[{"google_search_retrieval": {}}]
    )
    
    full_query = f"""
    Contexto da viagem: {context}
    
    Busque informações atualizadas sobre: {query}
    
    Foque em:
    - Informações de {search_type}
    - Preços atualizados quando disponível
    - Reviews recentes
    - Dicas práticas
    
    Retorne as fontes das informações.
    """
    
    response = model.generate_content(full_query)
    
    return {
        "query": query,
        "recommendations": response.text,
        "sources": extract_sources(response.grounding_metadata),
        "search_type": search_type
    }
```

---

### Fase 3: Integrações Externas (Semanas 8-9)

#### Semana 8: APIs de Viagem

**Tarefas:**
- [ ] Integrar Booking.com Affiliate API
- [ ] Integrar Airbnb (scraper ético ou API)
- [ ] Integrar AviationStack (voos)
- [ ] Configurar OAuth no Gateway
- [ ] Implementar cache agressivo

**OpenAPI Spec para Gateway:**
```yaml
# services/agentcore-runtime/schemas/booking-api.yaml
openapi: 3.0.0
info:
  title: Booking.com Integration
  version: 1.0.0
  
servers:
  - url: https://distribution-xml.booking.com/2.0
    description: Booking.com Affiliate API

paths:
  /json/hotelAvailability:
    get:
      operationId: searchHotels
      summary: Search available hotels
      parameters:
        - name: city_ids
          in: query
          required: true
          schema:
            type: string
        - name: checkin
          in: query
          required: true
          schema:
            type: string
            format: date
        - name: checkout
          in: query
          required: true
          schema:
            type: string
            format: date
        - name: guest_qty
          in: query
          schema:
            type: integer
            default: 2
      responses:
        '200':
          description: List of available hotels
```

#### Semana 9: Gateway e Rate Limiting

**Tarefas:**
- [ ] Configurar AgentCore Gateway com todas APIs
- [ ] Implementar rate limiting por usuário
- [ ] Configurar circuit breaker
- [ ] Implementar fallbacks
- [ ] Testar carga e limites

**Terraform Gateway:**
```hcl
# infra/agentcore/gateway.tf
resource "aws_bedrockagentcore_gateway" "n_agent_gateway" {
  name = "n-agent-gateway"
  
  # Configuração de targets
  targets {
    name = "google-maps"
    type = "OPENAPI"
    openapi_spec_s3_uri = "s3://${aws_s3_bucket.schemas.id}/google-maps-api.yaml"
    
    outbound_auth {
      type = "API_KEY"
      api_key_secret_arn = aws_secretsmanager_secret.google_maps_key.arn
    }
  }
  
  targets {
    name = "booking-affiliate"
    type = "OPENAPI"
    openapi_spec_s3_uri = "s3://${aws_s3_bucket.schemas.id}/booking-api.yaml"
    
    outbound_auth {
      type = "BASIC"
      credentials_secret_arn = aws_secretsmanager_secret.booking_creds.arn
    }
  }
  
  targets {
    name = "vertex-ai-gemini"
    type = "OPENAPI"
    openapi_spec_s3_uri = "s3://${aws_s3_bucket.schemas.id}/vertex-ai.yaml"
    
    outbound_auth {
      type = "OAUTH2"
      oauth_config {
        token_endpoint = "https://oauth2.googleapis.com/token"
        client_credentials_secret_arn = aws_secretsmanager_secret.gcp_oauth.arn
      }
    }
  }
  
  # Rate limiting
  throttling_config {
    rate_limit = 100
    burst_limit = 200
  }
}
```

---

### Fase 4: Produto Frontend (Semanas 10-11)

#### Semana 10: Painel Web

**Tarefas:**
- [ ] Dashboard de viagens (React)
- [ ] Chat web com WebSocket
- [ ] Visualização de roteiro
- [ ] Timeline interativa
- [ ] Responsivo mobile-first

**Arquitetura Frontend:**
```typescript
// apps/web-client/src/services/agentcore.ts
import { useCallback, useEffect, useState } from 'react';

interface AgentCoreClient {
  sessionId: string;
  sendMessage: (message: string) => Promise<AgentResponse>;
  onMessage: (callback: (msg: AgentResponse) => void) => void;
}

export function useAgentCore(userId: string): AgentCoreClient {
  const [sessionId, setSessionId] = useState<string>();
  const [ws, setWs] = useState<WebSocket>();
  
  useEffect(() => {
    // Conectar WebSocket ao AgentCore
    const socket = new WebSocket(
      `wss://api.n-agent.com/ws?userId=${userId}`
    );
    
    socket.onopen = () => {
      // Iniciar sessão
      socket.send(JSON.stringify({
        type: 'session.start',
        userId
      }));
    };
    
    socket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'session.created') {
        setSessionId(data.sessionId);
      }
    };
    
    setWs(socket);
    return () => socket.close();
  }, [userId]);
  
  const sendMessage = useCallback(async (message: string) => {
    return new Promise((resolve) => {
      ws?.send(JSON.stringify({
        type: 'message',
        sessionId,
        content: message
      }));
      // Handle response via onMessage callback
    });
  }, [ws, sessionId]);
  
  return { sessionId, sendMessage, onMessage: () => {} };
}
```

#### Semana 11: Documentos Ricos

**Tarefas:**
- [ ] Gerador de PDF de roteiro
- [ ] Exportação para Google Calendar
- [ ] Mapas interativos
- [ ] Compartilhamento de viagem
- [ ] Push notifications

---

### Fase 5: Lançamento (Semana 12)

#### Tarefas Finais

- [ ] Testes de carga (100 usuários simultâneos)
- [ ] Testes de segurança (OWASP)
- [ ] Documentação API
- [ ] Setup de monitoramento (alarms)
- [ ] Deploy produção
- [ ] Beta testers (10-20 usuários)

---

## Migração do Código Atual

### O que aproveitar:

1. **Estrutura do monorepo** → Mantém
2. **packages/core-types** → Mantém, expande
3. **packages/logger** → Mantém
4. **services/whatsapp-bot** → Adaptar para invocar AgentCore
5. **apps/web-client** → Mantém, conecta ao AgentCore
6. **infra/terraform** → Migrar para AgentCore resources

### O que substituir:

1. **services/ai-orchestrator** → AgentCore Runtime
2. **Bedrock Agent (bedrock.tf)** → AgentCore Agent
3. **DynamoDB custom tables** → AgentCore Memory
4. **services/action-groups** → AgentCore Tools

### Mapeamento de Resources:

| Recurso Atual | Recurso AgentCore |
|---------------|-------------------|
| `aws_bedrockagent_agent` | `AgentCore Runtime` (deploy via CLI) |
| `aws_bedrockagent_agent_action_group` | `AgentCore Tools` (Python decorators) |
| DynamoDB `NAgentCore` | `AgentCore Memory` (STM + LTM) |
| Lambda `ai-orchestrator` | `AgentCore Runtime` (managed) |
| Lambda `action-groups` | Integrado no Runtime |

---

## Estimativa de Custos AgentCore

### Componentes de Custo

| Componente | Preço | Uso Estimado MVP | Custo/mês |
|------------|-------|------------------|-----------|
| AgentCore Runtime | $0.001/invocação | 10k invocações | $10 |
| AgentCore Memory (STM) | $0.0001/operação | 50k ops | $5 |
| AgentCore Memory (LTM) | $0.01/1k records | 5k records | $50 |
| AgentCore Gateway | $0.001/request | 20k requests | $20 |
| Claude 3.5 Sonnet | $0.003/1k input tokens | 500k tokens | $150 |
| Gemini 2.0 Flash | $0.0001/1k tokens | 200k tokens | $20 |

**Total Estimado: ~$255/mês** para MVP (vs ~$300 com arquitetura atual)

---

## Timeline Resumida

```
Semana 1-2:  [████████░░░░░░░░░░░░] Fundação + Memory
Semana 3-4:  [████████████░░░░░░░░] Auth + Agent Base
Semana 5-6:  [████████████████░░░░] Tools + Conhecimento
Semana 7:    [██████████████████░░] Gemini Search
Semana 8-9:  [████████████████████] APIs Viagem + Gateway
Semana 10-11:[████████████████████] Frontend + Docs
Semana 12:   [████████████████████] Testes + Launch
```

---

## Decisão Recomendada

### ✅ **USAR BEDROCK AGENTCORE**

**Motivos:**

1. **Memória nativa** elimina ~40% do código de persistência
2. **Runtime gerenciado** reduz custo operacional
3. **Gateway MCP** facilita integrações futuras
4. **Observabilidade built-in** acelera debugging
5. **Multi-agent ready** para expansão futura

**Riscos:**

1. Serviço mais novo (menos documentação/exemplos)
2. Vendor lock-in maior com AWS
3. Curva de aprendizado do Strands SDK

**Mitigação:**

1. Manter camada de abstração para tools
2. Documentar bem as integrações
3. Prototipagem antes de comprometer

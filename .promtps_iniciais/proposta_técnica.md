# 1. Arquitetura de Solução (AWS Serverless)

A arquitetura será baseada no padrão **Event-Driven** (Orientada a Eventos). O chat não deve esperar a IA "pensar" e consultar 5 APIs de viagem. O chat recebe a mensagem, avisa que recebeu, e o processamento ocorre em segundo plano, notificando o usuário quando pronto.

## Diagrama Conceitual dos Serviços

### Camada de Entrada (Edge & API)

- **Amazon CloudFront**: CDN para o site React e assets estáticos.
- **Amazon API Gateway**: Porta de entrada para todas as requisições (Web e Webhooks do WhatsApp).
- **AWS WAF**: Firewall para proteger contra ataques.

### Camada de Orquestração (O "Cérebro")

- **AWS Lambda (BFF - Backend for Frontend)**: Resolve as requisições do site.
- **Amazon Bedrock AgentCore Runtime**: Onde a solução multi-agent é hospedada. O Router Agent decide qual agente especializado chamar.
- **Sistema Multi-Agent**: Arquitetura com agentes especializados (Router, Profile, Planner, Search, Concierge, Document, Vision) otimizados para suas tarefas específicas.
- **Amazon EventBridge**: O "carteiro". Quando o usuário manda uma mensagem, um evento é disparado. Quando o Booking confirma um hotel, outro evento é disparado. Isso desacopla os serviços.

### Domínios de Serviços (Microsserviços via Lambda)

- **Core - Auth Service**: Cognito para autenticação.
- **Core - Chat Ingestion**: Recebe Webhooks do WhatsApp (Meta) e WebSocket (Web). Normaliza a mensagem e joga no EventBridge.
- **Domain - Trip Planner**: Lógica de criação de roteiros e persistência do estado da viagem.
- **Domain - Integrator**: O serviço que sabe "falar" com APIs externas (Google Maps, Skyscanner, Booking). Ele traduz o pedido da IA para a API do parceiro.
- **Domain - Concierge**: Monitora datas e dispara alertas (cron jobs via EventBridge Scheduler).
- **Domain - Doc Generator**: Gera os HTMLs/PDFs ricos para o painel.

### Camada de Dados

**DynamoDB:**
- Tabela `Users` - Contas de usuário e pessoas
- Tabela `Trips` (Single Table Design sugerido para relacionar Viagem ↔ Itens ↔ Membros)
- Tabela `ChatHistory` - Logs de conversa
- Tabela `Profiles` - Perfis de pessoa e viagem (dados extraídos pelo agente)
- Tabela `AgentConfig` - Prompts dos agentes e configurações de integrações

**S3:** Armazenamento de fotos, documentos PDF gerados e assets do site.

# 2. Organização dos Repositórios

Para um MVP com uma equipe ágil e tecnologias compartilhadas (TypeScript no Front e Back), a melhor abordagem é um **Monorepo**.

## Por que Monorepo?

Você compartilha os "Tipos" (Interfaces TypeScript) entre o Backend e o Frontend. Se você mudar o formato do objeto `Viagem` no backend, o frontend "quebra" na hora da compilação, evitando bugs em produção.

## Sugestão de Estrutura de Pastas

Usando **Turborepo** ou **Nx**:

```
/n-agent-monorepo
│
├── /apps
│   ├── /web-client       (React + Vite + Material UI)
│   ├── /admin-panel      (React - Painel de administração)
│   └── /api-bff          (Node.js - Lambdas que atendem o front)
│
├── /agent                (Python - AgentCore Runtime)
│   ├── /src
│   │   ├── /router       (Router Agent)
│   │   ├── /profile      (Profile Agent)
│   │   ├── /planner      (Planner Agent)
│   │   ├── /search       (Search Agent)
│   │   ├── /concierge    (Concierge Agent)
│   │   ├── /document     (Document Agent)
│   │   ├── /vision       (Vision Agent)
│   │   ├── /memory       (AgentCore Memory wrapper)
│   │   ├── /tools        (Ferramentas compartilhadas)
│   │   └── /prompts      (Templates de prompts)
│   └── /tests
│
├── /packages             (Bibliotecas compartilhadas)
│   ├── /ui-lib           (Seus componentes de Design System M3)
│   ├── /core-types       (Interfaces TS: IUser, ITrip, IBooking, IPerson, IProfile)
│   ├── /utils            (Formatadores de data, validações)
│   └── /logger           (Padronização de logs para CloudWatch)
│
├── /services             (Microsserviços de Backend - Lógica Pesada)
│   ├── /trip-planner     (Lambda functions)
│   ├── /integrations     (Lambda functions para APIs externas)
│   ├── /concierge        (Lambda functions para alertas)
│   └── /whatsapp-bot     (Webhook handler)
│
└── /infra                (IaC - Infrastructure as Code)
    ├── /terraform        (ou CDK/Serverless Framework)
    └── /environments     (dev, staging, prod)
```
# 3. Detalhes das Integrações

Aqui detalho o funcionamento, custos e complexidade de cada "gigante" que você vai conectar.

## A. Google Maps Platform

Essencial para "Grounding" (dar realidade) aos locais.

### APIs Necessárias

- **Places API (New)**: Para buscar "Restaurantes em Roma" ou validar se um hotel existe.
- **Maps JavaScript API**: Para exibir o mapa no painel do usuário.
- **Directions API**: Para calcular tempo de rota e distância.

### Integração

REST API simples. O Bedrock Agent pode chamar uma Lambda que consulta o Places API.

### Custo

O Google dá **$200 USD** de crédito mensal recorrente.

- **Places**: ~$17 a cada 1.000 requisições (caro, use cache!)
- **Maps**: ~$7 a cada 1.000 carregamentos
## B. Meta (WhatsApp Business API)

A interface principal do usuário.

### Como funciona

Você usará a **WhatsApp Cloud API** (hospedada pela Meta, não precisa de servidor próprio).

### Integração

1. Você configura um **Webhook** (uma URL da sua API Gateway) no painel do Facebook Developers.
2. Toda mensagem que o usuário manda chega nesse Webhook.
3. Para responder, você manda um POST para a API do WhatsApp.

### Custos (Modelo de Conversas de 24h)

- **Service** (Iniciado pelo usuário): Aprox. $0.03 USD (no Brasil é mais barato que nos EUA/Europa)
- **Utility** (Lembrete de check-in): Aprox. $0.03 USD
- **Marketing** (Ofertas): Mais caro

**Bônus**: As primeiras 1.000 conversas de serviço por mês são **grátis**.

### Tempo de Integração


Marketing (Ofertas): Mais caro.

Bônus: As primeiras 1.000 conversas de serviço por mês são grátis.

Tempo de Integração: Médio (1 semana). A validação da conta Business no Facebook pode ser burocrática.
## C. Gemini 2.0 Flash com Google Search (Grounding)

⚠️ **Decisão de Arquitetura**: Vamos usar o Gemini 2.0 Flash com **Grounding with Google Search** como IA principal para recomendações e pesquisas.

### Por que Gemini + Search?

1. **Dados Atualizados**: Busca informações em tempo real (preços, eventos, reviews)
2. **Citações**: Retorna links das fontes para credibilidade
3. **Custo-Benefício**: Gemini 2.0 Flash é mais barato que Claude para tarefas de busca
4. **Latência**: ~2-3s vs 5-7s de Claude + Serper

### Arquitetura Híbrida (Escolhida)

```mermaid
graph LR
    A[AWS Lambda<br/>Orquestrador] --> B[Vertex AI API<br/>Google Cloud]
    B --> C[Gemini 2.0<br/>+ Search]
    
    style A fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style B fill:#4285F4,stroke:#1a73e8,stroke-width:2px,color:#fff
    style C fill:#34A853,stroke:#0d652d,stroke-width:2px,color:#fff
```

### Quando usar Gemini vs Bedrock?

| Tarefa | IA Utilizada | Motivo |
|--------|--------------|--------|
| Buscar hotéis na moda | Gemini + Search | Precisa de dados web recentes |
| Recomendar restaurantes | Gemini + Search | Reviews e rankings atualizados |
| Extrair dados de passaporte (OCR) | Bedrock (Claude 3.5 Sonnet) | Melhor para visão computacional |
| Gerar documento de roteiro | Bedrock (Claude 3.5 Sonnet) | Melhor para textos longos estruturados |
| Conversa casual | Bedrock (AWS Nova Lite) | Mais barato, latência baixa |

### Integração

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: 'n-agent-project',
  location: 'us-central1'
});

const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-2.0-flash-exp',
  generationConfig: {
    temperature: 0.7,
    maxOutputTokens: 2048,
  },
  tools: [{ googleSearchRetrieval: {} }]  // ✨ Ativa o Search!
});

const result = await model.generateContent({
  contents: [{
    role: 'user',
    parts: [{ text: 'Quais são os melhores restaurantes em Roma próximos ao Coliseu em 2027?' }]
  }]
});

// Resposta inclui: texto + groundingMetadata com links
```

### Custo

- **Gemini 2.0 Flash**: ~$0.10 por 1M tokens (input) + ~$0.30 por 1M tokens (output)
- **Grounding**: ~$35 USD por 1.000 queries de Search
- **Estimativa MVP**: ~$50-80/mês para 1.000 usuários

### Alternativa 100% AWS (Não Escolhida)

Poderíamos usar Claude 3.5 Sonnet no Bedrock + **Serper.dev** ou **Tavily**, mas:
- ❌ Custo maior (~2x)
- ❌ Latência maior (2 chamadas de API)
- ✅ Porém, mantém tudo na fatura AWS

**Decisão**: Usar Gemini para MVP e reavaliar na Fase 2.

## D. Booking.com / Skyscanner (Agregadores de Viagem)

Esta é a integração mais difícil (**"Hard"**).

### Como funciona

Grandes players não dão API aberta de transação (reserva) para startups logo de cara.

### Caminho do MVP: Programa de Afiliados

**Booking Affiliate Partner:**

1. Você usa a API deles para ler disponibilidade e preços (Search Availability).
2. Para fechar a compra, você gera um **"Deep Link"** com seu ID de afiliado. 
3. O usuário clica, vai pro site do Booking e paga lá.

### Custo

**Zero** (você ganha comissão).

### 💡 Dica

Considere usar a API do **Amadeus for Developers** para voos e hotéis no início. É muito amigável para desenvolvedores e tem sandbox gratuita.

## E. Airbnb (Hospedagem Alternativa)

### Como funciona

O Airbnb não possui API pública oficial para parceiros. Duas abordagens:

### Opção 1: Web Scraping Ético (MVP)

- Usar serviços como **Bright Data** ou **ScraperAPI** que respeitam robots.txt
- Extrair apenas dados públicos: preços, disponibilidade, fotos, avaliações
- **Custo**: ~$50-100/mês para 10K requests
- **Limitação**: Não permite reserva direta, apenas deep link para o site

### Opção 2: Parceria Oficial (Pós-MVP)

- Aplicar ao **Airbnb Affiliate Program** (comissão de ~3%)
- Acesso limitado a dados via **Affiliate API**
- Processo de aprovação: 2-4 semanas

### Integração no MVP

```typescript
interface AirbnbListing {
  id: string;
  title: string;
  location: { lat: number; lng: number; city: string };
  pricePerNight: number;
  currency: string;
  rating: number;
  reviewsCount: number;
  maxGuests: number;
  bedrooms: number;
  bathrooms: number;
  amenities: string[];  // ['WiFi', 'Kitchen', 'Parking']
  photos: string[];     // URLs das fotos
  deepLink: string;     // Link para reserva no site
}
```

### Tempo de Integração

Médio (1-2 semanas para setup e testes)

## F. AviationStack (Dados de Aeroportos e Voos)

### Por que é essencial?

Para a fase de **Concierge**, precisamos:
- Status de voos em tempo real (atrasos, cancelamentos)
- Mudanças de portão de embarque
- Informações de aeroportos (terminais, lounges, serviços)

### API Utilizada

**AviationStack** - Alternativa ao FlightAware, mais acessível

### Features Necessárias

```typescript
interface FlightStatus {
  flightNumber: string;        // "BA247"
  airline: string;             // "British Airways"
  departure: {
    airport: string;           // "GRU"
    terminal: string;          // "3"
    gate: string;              // "12"
    scheduledTime: string;
    actualTime: string;        // Pode diferir se atrasado
    delay: number;             // minutos
  };
  arrival: {
    airport: string;           // "LHR"
    terminal: string;
    gate: string;              // Atualizado em tempo real!
    scheduledTime: string;
    estimatedTime: string;
  };
  status: 'scheduled' | 'active' | 'landed' | 'cancelled' | 'diverted';
}
```

### Integração

REST API simples com polling a cada 30 minutos para voos nas próximas 24h.

### Custo

- **Plano Starter**: $49/mês para 10K requests
- ~500 requests/dia no MVP (suporta 100 viagens simultâneas)

### Tempo de Integração

Rápido (2-3 dias)

---

# 4. Roadmap Técnico Sugerido

## Fase 1: Fundação (Semanas 1-4)

| Semana | Entrega | Critério de Sucesso |
|--------|---------|---------------------|
| 1 | Setup Monorepo + CI/CD | Deploy automático de Lambda "Hello World" |
| 2 | Infraestrutura base (Terraform/CDK) | DynamoDB + S3 + API Gateway funcionando |
| 3 | Auth (Cognito) + BFF básico | Login funcional no frontend |
| 4 | Módulo WhatsApp | Bot responde "Oi" via Webhook |

## Fase 2: Core AI (Semanas 5-8)

| Semana | Entrega | Critério de Sucesso |
|--------|---------|---------------------|
| 5 | Bedrock Agent configurado | Agente responde perguntas simples |
| 6 | Tool: Consulta clima | IA retorna previsão do tempo |
| 7 | Tool: Google Maps Places | IA busca e retorna locais |
| 8 | Persistência de contexto | IA lembra dados da viagem |

## Fase 3: Produto (Semanas 9-12)

| Semana | Entrega | Critério de Sucesso |
|--------|---------|---------------------|
| 9 | Painel Web (Dashboard) | Visualização da viagem |
| 10 | Geração de documentos | PDF de roteiro gerado |
| 11 | Integração Booking | Busca de hotéis funcionando |
| 12 | Notificações + Alertas | Lembretes via WhatsApp |

## Marco: MVP Pronto para Beta Testers (Semana 12)

---

# 4.1. Arquitetura Multi-Agent

## Visão Geral do Sistema Multi-Agent

O n-agent utiliza uma arquitetura multi-agent onde cada agente é especializado em uma tarefa específica, otimizando custos e performance.

```mermaid
graph TD
    USER[User Input] --> ROUTER[ROUTER AGENT<br/>Nova Micro<br/>Classifica intenção]
    
    ROUTER --> PROFILE[PROFILE AGENT<br/>Nova Lite]
    ROUTER --> PLANNER[PLANNER AGENT<br/>Nova Pro]
    ROUTER --> SEARCH[SEARCH AGENT<br/>Gemini + Search]
    ROUTER --> CONCIERGE[CONCIERGE AGENT<br/>Nova Lite]
    ROUTER --> DOCUMENT[DOCUMENT AGENT<br/>Claude 3.5 Sonnet]
    ROUTER --> VISION[VISION AGENT<br/>Claude 3.5 Sonnet]
    
    PROFILE --> TOOLS[SHARED TOOLS & MEMORY<br/>AgentCore Memory | DynamoDB | Ferramentas de Perfil]
    PLANNER --> TOOLS
    SEARCH --> TOOLS
    CONCIERGE --> TOOLS
    DOCUMENT --> TOOLS
    VISION --> TOOLS
    
    style USER fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style ROUTER fill:#fff176,stroke:#f57f17,stroke-width:3px
    style PROFILE fill:#a5d6a7,stroke:#2e7d32,stroke-width:2px
    style PLANNER fill:#90caf9,stroke:#1565c0,stroke-width:2px
    style SEARCH fill:#ce93d8,stroke:#6a1b9a,stroke-width:2px
    style CONCIERGE fill:#ffab91,stroke:#bf360c,stroke-width:2px
    style DOCUMENT fill:#80deea,stroke:#006064,stroke-width:2px
    style VISION fill:#f48fb1,stroke:#880e4f,stroke-width:2px
    style TOOLS fill:#e0e0e0,stroke:#424242,stroke-width:2px
```

## Agentes Especializados

### 1. Router Agent (Classificador)

**Modelo:** Nova Micro (mais barato, latência baixa)  
**Responsabilidade:** Classificar a intenção do usuário e rotear para o agente apropriado.

```python
# Categorias de roteamento
ROUTING_CATEGORIES = {
    "PROFILE": "Extração/atualização de informações de perfil",
    "PLANNING": "Criação ou modificação de roteiros",
    "SEARCH": "Busca de hospedagens, voos, atrações",
    "CONCIERGE": "Alertas, lembretes, suporte durante viagem",
    "DOCUMENT": "Geração de documentos ricos",
    "VISION": "Análise de imagens (OCR, validação)",
    "CHAT": "Conversa casual ou dúvidas gerais"
}
```

### 2. Profile Agent (Extrator de Perfis)

**Modelo:** Nova Lite  
**Responsabilidade:** Analisar mensagens e extrair/persistir informações de perfil.

**Ferramentas disponíveis:**
- `get_person_profile` / `update_person_profile`
- `get_trip_profile` / `update_trip_profile`
- `add_preference` / `add_restriction`
- `link_person_to_trip`

**Fluxo de extração:**
1. Recebe mensagem do usuário
2. Identifica entidades mencionadas (pessoas, lugares, datas)
3. Classifica informações (preferência, restrição, objetivo)
4. Valida permissão do informante
5. Persiste usando ferramentas apropriadas
6. Confirma ao usuário

### 3. Planner Agent (Planejador de Roteiros)

**Modelo:** Nova Pro / Gemini (para tarefas complexas)  
**Responsabilidade:** Criar e otimizar roteiros de viagem.

**Ferramentas disponíveis:**
- `get_trip_profile_details`
- `get_all_participants_profiles`
- `create_itinerary`
- `optimize_route`
- `estimate_costs`
- `compare_versions`

### 4. Search Agent (Buscador)

**Modelo:** Gemini 2.0 Flash + Google Search Grounding  
**Responsabilidade:** Buscar informações em tempo real.

**Ferramentas disponíveis:**
- `search_hotels` (Booking, Airbnb)
- `search_flights` (AviationStack)
- `search_attractions` (Google Places)
- `get_weather_forecast`
- `get_exchange_rates`

### 5. Concierge Agent (Assistente de Viagem)

**Modelo:** Nova Lite  
**Responsabilidade:** Monitorar viagens ativas e fornecer suporte.

**Ferramentas disponíveis:**
- `get_flight_status`
- `check_weather_alerts`
- `send_reminder`
- `get_emergency_contacts`
- `translate_text`

### 6. Document Agent (Gerador de Documentos)

**Modelo:** Claude 3.5 Sonnet (melhor para textos estruturados)  
**Responsabilidade:** Gerar documentos ricos.

**Ferramentas disponíveis:**
- `generate_itinerary_html`
- `generate_itinerary_pdf`
- `generate_checklist`
- `generate_voucher`
- `generate_financial_report`

### 7. Vision Agent (Processamento de Imagens)

**Modelo:** Claude 3.5 Sonnet (melhor para visão)  
**Responsabilidade:** Processar e analisar imagens.

**Ferramentas disponíveis:**
- `extract_passport_data` (OCR)
- `extract_ticket_data`
- `validate_document_photo`
- `translate_menu_photo`

## Fluxo de Comunicação Inter-Agentes

```typescript
interface AgentMessage {
  fromAgent: string;
  toAgent: string;
  tripId: string;
  userId: string;
  sessionId: string;
  payload: {
    intent: string;
    context: object;
    data: any;
  };
  metadata: {
    traceId: string;
    timestamp: string;
  };
}
```

## Otimização de Custos

| Agente | % Chamadas (estimado) | Custo/1M tokens | Impacto no Custo Total |
|--------|----------------------|-----------------|------------------------|
| Router | 100% | $0.035 (Nova Micro) | Baixo |
| Profile | 30% | $0.06 (Nova Lite) | Baixo |
| Search | 25% | $0.10 (Gemini Flash) | Médio |
| Planner | 15% | $0.80 (Nova Pro) | Médio |
| Concierge | 20% | $0.06 (Nova Lite) | Baixo |
| Document | 5% | $3.00 (Claude) | Baixo (poucas chamadas) |
| Vision | 5% | $3.00 (Claude) | Baixo (poucas chamadas) |

**Resultado esperado:** ~76% de redução de custo comparado a usar apenas um modelo (ex: Claude) para todas as tarefas.

---

## Parte 1: Modelagem do DynamoDB (NoSQL)

Para a AWS e arquitetura Serverless, a melhor prática é usar o **Single Table Design** (ou uma variação híbrida) para a tabela principal de dados, otimizando a leitura rápida do painel, e uma tabela separada para o Histórico de Chat (devido ao alto volume de escrita).

### Tabela 1: NAgentCore (Dados Mestres)

Esta tabela guarda Usuários, Viagens, Itinerário e Reservas.

- **Partition Key (PK):** String
- **Sort Key (SK):** String
- **Global Secondary Index 1 (GSI1):** Inverte a busca (ex: buscar todas as viagens de um usuário)
  - **GSI1PK:** String
  - **GSI1SK:** String

#### Padrões de Acesso e Entidades

- **Usuário**
  - PK: `USER#<email>`
  - SK: `PROFILE`
  - Atributos: `nome`, `whatsapp_id`, `preferences` (JSON), `docs_status`

- **Viagem (Trip)**
  - PK: `TRIP#<uuid>`
  - SK: `META#USER#<email>#DATE#<inicio>`
  - Atributos: `nome_viagem`, `status` (PLANNING/CONCIERGE), `budget_total`, `moeda`

- **Participante**
  - PK: `TRIP#<uuid>`
  - SK: `MEMBER#<email>`
  - GSI1PK: `USER#<email>`
  - GSI1SK: `TRIP#<uuid>`
  - Atributos: `role` (ADMIN/VIEWER), `passaporte_validade`, `restricoes_alimentares`

- **Dia do Roteiro**
  - PK: `TRIP#<uuid>`
  - SK: `DAY#YYYY-MM-DD` (ex: `DAY#2027-08-01`)
  - Atributos: `resumo_dia`, `clima_previsto`, `cidade_foco`

- **Evento / Reserva**
  - PK: `TRIP#<uuid>`
  - SK: `EVENT#<timestamp>`
  - GSI1PK: `TYPE#<tipo>` (opcional)
  - Atributos: `tipo` (FLIGHT/HOTEL/TOUR), `provider` (Booking), `custo`, `status_pagamento`, `file_url` (S3)

#### Por que assim?

Para carregar o painel da viagem, o backend faz uma única query: `Query(PK="TRIP#123")`. O DynamoDB retorna o cabeçalho da viagem, os participantes, os dias e os eventos em uma única chamada de rede, resultando em baixa latência.

### Tabela 2: NAgentProfiles (Perfis de Pessoa e Viagem)

Esta tabela guarda os perfis extraídos pelo agente durante as conversas.

- **Partition Key (PK):** String
- **Sort Key (SK):** String

#### Entidades de Perfil

- **Perfil de Pessoa**
  - PK: `PERSON#<personId>`
  - SK: `PROFILE#GENERAL`
  - Atributos: `nome`, `idade`, `preferencias` (JSON), `restricoes` (JSON), `documentos_status`, `updatedAt`, `updatedBy`

- **Preferências de Pessoa por Viagem**
  - PK: `PERSON#<personId>`
  - SK: `TRIP#<tripId>#PREFS`
  - Atributos: `atividades_desejadas` (array), `locais_interesse` (array), `restricoes_locais` (array)

- **Perfil da Viagem**
  - PK: `TRIP#<tripId>`
  - SK: `PROFILE#GENERAL`
  - Atributos: `objetivos` (JSON), `budget`, `estilo_viagem`, `preferencias_hospedagem`, `preferencias_transporte`

- **Contexto Extraído da Viagem**
  - PK: `TRIP#<tripId>`
  - SK: `CONTEXT#<timestamp>`
  - Atributos: `tipo` (DESTINATION/ACTIVITY/PREFERENCE), `valor`, `fonte_mensagem_id`, `confianca`

#### Exemplo de Perfil de Pessoa

```json
{
  "PK": "PERSON#person-456",
  "SK": "PROFILE#GENERAL",
  "nome": "Fabiola",
  "idade": 42,
  "preferencias": {
    "tipos_atracao": ["cultural", "historico", "gastronomia"],
    "ritmo_viagem": "moderado",
    "horario_preferido": "manha"
  },
  "restricoes": {
    "alimentares": ["vegetariana"],
    "mobilidade": null,
    "fobias": ["altura"]
  },
  "updatedAt": "2025-01-15T10:00:00Z",
  "updatedBy": "USER#victor@email.com"
}
```

#### Exemplo de Perfil de Viagem

```json
{
  "PK": "TRIP#trip-123",
  "SK": "PROFILE#GENERAL",
  "objetivos": {
    "principais": ["conhecer capitais europeias", "experiencias culturais"],
    "secundarios": ["compras", "gastronomia local"]
  },
  "budget": {
    "total": 15000,
    "moeda": "EUR",
    "flexibilidade": "media"
  },
  "estilo_viagem": "familia_com_criancas",
  "preferencias_hospedagem": {
    "tipo": ["airbnb", "hotel"],
    "requisitos": ["2+ banheiros", "proximo_metro"],
    "evitar": ["hostels"]
  },
  "preferencias_transporte": {
    "principal": "transporte_publico",
    "entre_cidades": ["trem", "aviao_curta_distancia"],
    "local": ["metro", "uber"]
  }
}
```

### Tabela 3: NAgentConfig (Configurações e Prompts)

Esta tabela guarda os prompts dos agentes e configurações de integrações, parametrizáveis via portal de administração.

- **Partition Key (PK):** String
- **Sort Key (SK):** String
- **Global Secondary Index 1 (GSI1):** Para buscar por tipo e status
  - **GSI1PK:** String
  - **GSI1SK:** String

#### Entidades de Configuração

- **Prompt de Agente**
  - PK: `PROMPT#<agentType>`
  - SK: `VERSION#<version>`
  - GSI1PK: `PROMPT#<agentType>`
  - GSI1SK: `ACTIVE#<isActive>` (ex: `ACTIVE#true`)
  - Atributos: `content`, `variables`, `createdBy`, `createdAt`, `changelog`

- **Configuração de Integração**
  - PK: `INTEGRATION#<integrationName>`
  - SK: `CONFIG`
  - Atributos: `apiKey` (encrypted reference to Secrets Manager), `endpoint`, `rateLimits`, `cacheTTL`, `enabled`

- **Administrador da Plataforma**
  - PK: `ADMIN#<email>`
  - SK: `PROFILE`
  - Atributos: `nome`, `permissions`, `createdAt`, `lastLogin`

#### Exemplo de Prompt Versionado

```json
{
  "PK": "PROMPT#ROUTER",
  "SK": "VERSION#3",
  "GSI1PK": "PROMPT#ROUTER",
  "GSI1SK": "ACTIVE#true",
  "agentType": "ROUTER",
  "version": 3,
  "content": "Você é o Router Agent do n-agent, um assistente de viagens...\n\nClassifique a mensagem do usuário em uma das categorias:\n- PROFILE: extração de informações pessoais ou da viagem\n- PLANNING: criação ou modificação de roteiros\n- SEARCH: busca de hospedagens, voos, atrações\n- CONCIERGE: alertas, lembretes, suporte durante viagem\n- DOCUMENT: geração de documentos\n- VISION: análise de imagens\n- CHAT: conversa casual\n\nContexto da viagem: {{tripContext}}\nPerfil do usuário: {{userProfile}}",
  "variables": ["tripContext", "userProfile"],
  "isActive": true,
  "createdBy": "admin@n-agent.com",
  "createdAt": "2025-01-15T10:00:00Z",
  "changelog": "Adicionada categoria VISION para OCR de documentos"
}
```

#### Exemplo de Configuração de Integração

```json
{
  "PK": "INTEGRATION#GOOGLE_MAPS",
  "SK": "CONFIG",
  "name": "Google Maps Platform",
  "apiKeyRef": "arn:aws:secretsmanager:us-east-1:123:secret:google-maps-api-key",
  "endpoints": {
    "places": "https://maps.googleapis.com/maps/api/place",
    "directions": "https://maps.googleapis.com/maps/api/directions"
  },
  "rateLimits": {
    "requestsPerSecond": 10,
    "requestsPerDay": 5000
  },
  "cacheTTL": {
    "places": 86400,
    "directions": 3600
  },
  "enabled": true,
  "updatedAt": "2025-01-15T10:00:00Z",
  "updatedBy": "admin@n-agent.com"
}
```

### Tabela 4: NAgentChatHistory (Logs de Conversa)

Separada para permitir arquivamento (TTL) e escalabilidade independente.

- **Partition Key (PK):** `TRIP#<uuid>` (Agrupa o chat por viagem)
- **Sort Key (SK):** `MSG#<timestamp_iso>` (Ordena cronologicamente)

Exemplo de item:

```json
{
  "PK": "TRIP#123",
  "SK": "MSG#2025-01-01T10:00:00Z",
  "sender": "USER",
  "content": "Olá, confirmei o voo.",
  "attachments": ["s3://bucket/e-ticket.pdf"],
  "metadata": { "tokens": 45 }
}
```

## Parte 2: Contrato de API (JSON Specification)

Este é o contrato que o seu Front-end (React) vai consumir. O BFF (Backend for Frontend) montará esses JSONs consultando o DynamoDB.

### 1. Endpoint: Obter Detalhes da Viagem (Dashboard)

GET `/api/v1/trips/{tripId}/dashboard`

Este JSON alimenta a tela principal do usuário, desenhando a timeline e os cards.

```json
{
  "tripId": "TRIP-8823-XYZ",
  "title": "Eurotrip Família 2027",
  "status": "PLANNING",
  "dates": {
    "start": "2027-08-01",
    "end": "2027-08-22",
    "totalDays": 21
  },
  "budget": {
    "currency": "EUR",
    "totalLimit": 15000,
    "currentSpent": 4520,
    "alerts": ["Gastos com hotel acima do previsto em 10%"]
  },
  "members": [
    {
      "name": "Você",
      "role": "OWNER",
      "avatarUrl": "https://s3.../avatar1.jpg",
      "pendingTasks": 0
    },
    {
      "name": "Sobrinho (João)",
      "role": "MEMBER",
      "status": "WARNING",
      "pendingTasks": 1,
      "alertMessage": "Passaporte vence em 3 meses"
    }
  ],
  "timeline": [
    {
      "date": "2027-08-02",
      "dayNumber": 1,
      "city": "Londres, UK",
      "weatherForecast": { "temp": 18, "condition": "Cloudy" },
      "events": [
        {
          "id": "EVT-001",
          "type": "FLIGHT",
          "time": "14:30",
          "title": "Voo GRU -> LHR",
          "details": "Voo BA247 - Terminal 3",
          "status": "CONFIRMED",
          "documents": [{ "name": "E-Ticket", "url": "https://..." }]
        },
        {
          "id": "EVT-002",
          "type": "CHECKIN",
          "time": "16:00",
          "title": "Check-in Airbnb Kensington",
          "details": "Senha da porta: 1234",
          "location": { "lat": 51.50, "lng": -0.12, "mapsUrl": "https://goo.gl/maps/..." },
          "status": "PENDING_PAYMENT"
        }
      ]
    }
  ]
}
```

### 2. Endpoint: Histórico de Chat com "Conteúdo Rico"

GET `/api/v1/chat/{tripId}/history`

Aqui o chat pode retornar mensagens de texto e também widgets ricos (`trip_proposal`, `hotel_card`) que o front renderizará como componentes visuais.

```json
{
  "messages": [
    {
      "id": "msg_001",
      "sender": "USER",
      "timestamp": "2025-10-12T10:00:00Z",
      "type": "text",
      "content": "Quero opções de hotéis em Roma perto do Coliseu."
    },
    {
      "id": "msg_002",
      "sender": "AGENT",
      "timestamp": "2025-10-12T10:00:05Z",
      "type": "text",
      "content": "Encontrei 3 opções excelentes para o seu grupo de 7 pessoas."
    },
    {
      "id": "msg_003",
      "sender": "AGENT",
      "timestamp": "2025-10-12T10:00:06Z",
      "type": "rich_card_carousel",
      "payload": {
        "title": "Hospedagem em Roma (05/08 - 09/08)",
        "cards": [
          {
            "id": "opt_1",
            "title": "Hotel Monti Palace",
            "imageUrl": "https://booking.com/images/...",
            "price": "€ 1.200",
            "rating": 4.8,
            "highlight": "5 min a pé do Coliseu",
            "actionLink": "https://n-agent.com/approve/opt_1"
          },
          {
            "id": "opt_2",
            "title": "Airbnb Via Cavour",
            "imageUrl": "https://airbnb.com/images/...",
            "price": "€ 950",
            "rating": 4.5,
            "highlight": "Melhor custo-benefício",
            "actionLink": "https://n-agent.com/approve/opt_2"
          }
        ]
      }
    }
  ]
}
```

### 3. Webhook de Entrada (Payload do WhatsApp)

POST `/webhooks/whatsapp`

Formato padrão enviado pelo Meta para o backend. O serviço de ingestion deve normalizar esse payload e persistir/encaminhar conforme necessário.

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "WHATSAPP_BUSINESS_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": { "display_phone_number": "15550050", "phone_number_id": "123456" },
            "contacts": [ { "profile": { "name": "Cliente" }, "wa_id": "5511999999999" } ],
            "messages": [
              {
                "from": "5511999999999",
                "id": "wamid.HBgLM...",
                "timestamp": "1699999999",
                "type": "text",
                "text": { "body": "Aqui está a confirmação do voo." },
                "document": {
                  "filename": "e-ticket.pdf",
                  "mime_type": "application/pdf",
                  "id": "media_id_123"
                }
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

---

# 5. Sistema de Documentos Ricos

## Visão Geral

O sistema de documentos é um diferencial do produto. Não vamos criar um "Google Drive interno", mas sim um **sistema de documentos gerados sob demanda** com visualização rica.

## Arquitetura de Documentos

```mermaid
graph LR
    A[Bedrock Agent<br/>decide gerar] --> B[Doc Generator<br/>Lambda + React SSR]
    B --> C[S3 Bucket<br/>HTML/PDF]
    C --> D[CloudFront<br/>URL assinada]
    
    style A fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style B fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style C fill:#569A31,stroke:#3c6e26,stroke-width:2px,color:#fff
    style D fill:#8C4FFF,stroke:#5c2d91,stroke-width:2px,color:#fff
```

## Tipos de Documentos

| Tipo | Formato | Uso |
|------|---------|-----|
| **Roteiro Resumido** | HTML interativo | Compartilhar via link |
| **Roteiro Completo** | PDF | Download/impressão |
| **Checklist** | JSON + React | Painel interativo |
| **Voucher/Ingresso** | PDF com QRCode | Envio via WhatsApp |
| **Relatório Financeiro** | HTML + gráficos | Dashboard de gastos |
| **Mapa de Viagem** | HTML + Google Maps embed | Visualização geográfica |

## Estrutura de Storage (S3)

```
s3://n-agent-documents/
├── users/
│   └── {userId}/
│       └── avatar.jpg
├── trips/
│   └── {tripId}/
│       ├── docs/
│       │   ├── roteiro-v1.html
│       │   ├── roteiro-v1.pdf
│       │   ├── roteiro-v2.html      # Versionamento!
│       │   └── checklist.json
│       ├── vouchers/
│       │   ├── flight-evt001.pdf
│       │   └── hotel-evt002.pdf
│       └── attachments/
│           ├── passaporte-joao.jpg   # Criptografado!
│           └── seguro-viagem.pdf
└── templates/
    ├── roteiro-template.html
    └── voucher-template.html
```

## Geração de Documentos (Lambda Doc Generator)

### Fluxo de Geração

1. **Trigger**: Bedrock Agent decide que precisa gerar documento
2. **Coleta**: Lambda busca dados da viagem no DynamoDB
3. **Renderização**: 
   - HTML: React Server-Side Rendering (Next.js API Route ou @react-pdf/renderer)
   - PDF: Puppeteer headless ou `@react-pdf/renderer`
4. **Upload**: Documento salvo no S3 com metadados
5. **URL**: Gera URL assinada (expira em 7 dias) ou URL pública para docs não-sensíveis
6. **Notificação**: Envia link para usuário via WhatsApp/WebSocket

### Exemplo de Metadados (DynamoDB)

```json
{
  "PK": "TRIP#123",
  "SK": "DOC#roteiro-v2",
  "type": "ITINERARY",
  "version": 2,
  "format": "html",
  "s3Key": "trips/123/docs/roteiro-v2.html",
  "createdAt": "2025-01-15T10:00:00Z",
  "expiresAt": "2025-02-15T10:00:00Z",
  "isPublic": false,
  "sharedWith": ["member@email.com"]
}
```

## Versionamento de Roteiros

Cada alteração significativa no roteiro gera uma nova versão:

```typescript
interface TripVersion {
  tripId: string;
  version: number;
  label: string;           // "Versão Econômica", "Versão Conforto"
  snapshot: TripSnapshot;  // Estado completo do roteiro
  createdAt: string;
  createdBy: string;       // userId que fez a alteração
  diff?: TripDiff;         // O que mudou da versão anterior
}
```

### Comparação Lado a Lado (Fase 2)

O frontend terá um componente de "diff visual" para comparar versões:
- Preço total: R$ 12.000 → R$ 15.000 (+25%)
- Hospedagem: Airbnb Centro → Hotel 4 estrelas
- Dias em Paris: 4 → 5

---

# 6. Autenticação e Autorização

## Fluxo de Autenticação

### Usuários com Conta (Owner/Admin)

```mermaid
graph TD
    A[Login Web] --> B[Cognito User Pool]
    B --> C[JWT Token<br/>1h expiry]
    
    B --> D[Email + Senha]
    B --> E[OAuth<br/>Google/Microsoft]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style B fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style C fill:#4caf50,stroke:#2e7d32,stroke-width:2px,color:#fff
    style D fill:#90caf9,stroke:#1565c0,stroke-width:2px
    style E fill:#ce93d8,stroke:#6a1b9a,stroke-width:2px
```

### Membros Convidados (Viewer/Editor)

Para membros que não querem criar conta completa:

```mermaid
graph LR
    A[Link com Token] --> B[Lambda Validator]
    B --> C[Session Temporária]
    
    style A fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style B fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style C fill:#4caf50,stroke:#2e7d32,stroke-width:2px,color:#fff
```

- Token único gerado pelo Owner ao convidar
- Válido por 7 dias ou até aceite
- Acesso limitado apenas à viagem específica
- Pode fazer upgrade para conta completa a qualquer momento

## Políticas de Autorização (IAM-like)

```typescript
const permissions = {
  'OWNER': ['trip:*', 'member:*', 'billing:*', 'doc:*'],
  'ADMIN': ['trip:read', 'trip:write', 'member:invite', 'doc:*'],
  'EDITOR': ['trip:read', 'trip:suggest', 'doc:read'],
  'VIEWER': ['trip:read', 'doc:read']
};
```

---

# 7. Sistema de Notificações

## Canais de Notificação

| Canal | Uso | Serviço AWS |
|-------|-----|-------------|
| **WhatsApp** | Alertas críticos, lembretes | Meta Cloud API |
| **Email** | Confirmações, relatórios | Amazon SES |
| **Web Push** | Alertas em tempo real no painel | Lambda + WebSocket |
| **In-App** | Badge de notificações | DynamoDB + polling |

## Tipos de Notificações

```typescript
enum NotificationType {
  // Urgentes (WhatsApp + Push)
  FLIGHT_GATE_CHANGE = 'flight_gate_change',
  BOOKING_CANCELLED = 'booking_cancelled',
  MEMBER_EMERGENCY = 'member_emergency',
  
  // Importantes (WhatsApp)
  CHECKIN_REMINDER = 'checkin_reminder',      // 24h antes
  DOCUMENT_EXPIRING = 'document_expiring',    // 30 dias antes
  PAYMENT_DUE = 'payment_due',
  
  // Informativas (Email + In-App)
  ITINERARY_UPDATED = 'itinerary_updated',
  NEW_RECOMMENDATION = 'new_recommendation',
  TRIP_SUMMARY = 'trip_summary'               // Semanal
}
```

## Agendamento (EventBridge Scheduler)

```json
{
  "Name": "checkin-reminder-EVT002",
  "ScheduleExpression": "at(2027-08-01T14:00:00)",
  "Target": {
    "Arn": "arn:aws:lambda:us-east-1:123:function:send-notification",
    "Input": {
      "type": "CHECKIN_REMINDER",
      "tripId": "TRIP#123",
      "eventId": "EVT-002",
      "channels": ["whatsapp", "push"]
    }
  }
}
```

---

# 8. Rate Limiting e Proteção de Custos

## Problema

APIs externas são caras. Um usuário mal-intencionado (ou bug) pode gerar milhares de chamadas.

## Solução: Camadas de Proteção

### 1. WAF Rate Limiting (Camada Edge)

```yaml
# Regra WAF
RateLimit:
  Limit: 100          # requests
  Period: 300         # 5 minutos
  Action: BLOCK
  Scope: IP
```

### 2. API Gateway Throttling

```yaml
# Por usuário autenticado
UsagePlan:
  Quota:
    Limit: 1000       # requests/dia
    Period: DAY
  Throttle:
    BurstLimit: 50    # requests simultâneos
    RateLimit: 10     # requests/segundo
```

### 3. Circuit Breaker (Lambdas)

```typescript
// Usando biblioteca como 'opossum'
const circuitBreaker = new CircuitBreaker(callBookingAPI, {
  timeout: 5000,           // 5s timeout
  errorThresholdPercentage: 50,
  resetTimeout: 30000      // 30s antes de tentar novamente
});
```

### 4. Cache Agressivo (ElastiCache Redis)

```typescript
// Estratégia de cache
const cacheStrategy = {
  'places_search': { ttl: '24h', key: 'places:{query}:{location}' },
  'hotel_prices': { ttl: '1h', key: 'hotel:{id}:{dates}' },
  'flight_prices': { ttl: '15m', key: 'flight:{origin}:{dest}:{date}' },
  'weather': { ttl: '3h', key: 'weather:{city}:{date}' }
};
```

### 5. Orçamento por Usuário

```typescript
interface UserBudget {
  monthlyApiCredits: number;    // Ex: 1000 créditos
  usedCredits: number;
  resetDate: string;
}

// Custo por operação
const operationCosts = {
  'search_hotels': 5,
  'search_flights': 10,
  'generate_itinerary': 20,
  'ai_chat_message': 1
};
```

---

# 9. Observabilidade e Monitoramento

## Stack de Observabilidade

```mermaid
graph TD
    CW[CloudWatch]
    CW --> LOGS[Logs]
    CW --> METRICS[Metrics]
    CW --> ALARMS[Alarms]
    
    LOGS --> XRAY[X-Ray<br/>Traces]
    METRICS --> DASH[Dashboard<br/>Grafana]
    ALARMS --> SNS[SNS<br/>Alertas]
    
    style CW fill:#FF9900,stroke:#232F3E,stroke-width:3px,color:#fff
    style LOGS fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style METRICS fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style ALARMS fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style XRAY fill:#945DF2,stroke:#5c2d91,stroke-width:2px,color:#fff
    style DASH fill:#4caf50,stroke:#2e7d32,stroke-width:2px,color:#fff
    style SNS fill:#d13212,stroke:#8b0000,stroke-width:2px,color:#fff
```

## Métricas Críticas

| Métrica | Threshold | Ação |
|---------|-----------|------|
| Lambda Error Rate | > 5% | Alerta Slack |
| API Latency P99 | > 3s | Investigar |
| DynamoDB Throttling | > 0 | Aumentar capacidade |
| WhatsApp Delivery Rate | < 95% | Verificar templates |
| Bedrock Token Usage | > 80% budget | Alerta + rate limit |

## Logs Estruturados

```typescript
// Formato padronizado de log
const log = {
  timestamp: '2025-01-15T10:00:00Z',
  level: 'INFO',
  service: 'trip-planner',
  traceId: 'abc-123',
  userId: 'user-456',
  tripId: 'trip-789',
  action: 'generate_itinerary',
  duration: 1500,
  metadata: {
    citiesCount: 4,
    daysCount: 21,
    modelUsed: 'claude-3-sonnet'
  }
};
```

---

# 10. Segurança e Compliance (LGPD/GDPR)

## Dados Sensíveis

| Dado | Classificação | Tratamento |
|------|---------------|------------|
| Passaporte (foto) | **PII Crítico** | Criptografia S3 SSE-KMS, acesso auditado |
| WhatsApp ID | PII | Hash para analytics, original só para operação |
| Histórico de chat | PII | TTL de 2 anos, exportável pelo usuário |
| Dados de pagamento | **PCI** | Não armazenamos - Stripe/gateway externo |
| Localização | PII | Opt-in explícito, granularidade reduzida |

## Criptografia

```yaml
# S3 Bucket Policy
Encryption:
  - ServerSideEncryptionByDefault:
      SSEAlgorithm: aws:kms
      KMSMasterKeyID: alias/n-agent-documents

# DynamoDB
Encryption:
  - SSESpecification:
      SSEEnabled: true
      SSEType: KMS
```

## Direitos do Titular (LGPD Art. 18)

| Direito | Implementação |
|---------|---------------|
| **Acesso** | Endpoint GET /api/v1/me/data (export JSON) |
| **Correção** | Edição no painel + chat com IA |
| **Exclusão** | DELETE /api/v1/me + job de limpeza em 30 dias |
| **Portabilidade** | Export em formato padrão (JSON/CSV) |
| **Revogação** | Toggle de consentimentos no painel |

## Auditoria

```typescript
interface AuditLog {
  timestamp: string;
  actor: string;          // userId ou 'system'
  action: string;         // 'read_passport', 'delete_trip'
  resource: string;       // 'user:123', 'trip:456'
  ip: string;
  userAgent: string;
  result: 'success' | 'denied' | 'error';
}
```

---

# 11. Disaster Recovery e Backup

## Estratégia de Backup

| Recurso | Frequência | Retenção | Destino |
|---------|------------|----------|---------|
| DynamoDB | Contínuo (PITR) | 35 dias | Mesma região |
| DynamoDB | Diário (snapshot) | 90 dias | S3 cross-region |
| S3 Documentos | Versionamento | 30 versões | Replicação us-east-1 → eu-west-1 |
| Secrets | Automático | N/A | Secrets Manager |

## RPO e RTO

| Cenário | RPO | RTO |
|---------|-----|-----|
| Falha de Lambda | 0 | < 1min (retry automático) |
| Falha de região | < 1h | < 4h (failover manual) |
| Corrupção de dados | < 5min (PITR) | < 1h |
| Ataque/Breach | N/A | < 24h (investigação) |

## Backup Cross-Region

**Não implementaremos multi-region ativo/ativo ou ativo/standby no MVP.** Apenas backup automático em outra região.

```mermaid
graph TD
    subgraph PROD["us-east-1 (Production)"]
        DB[(DynamoDB)]
    end
    
    subgraph BACKUP["sa-east-1 (Backup Only)"]
        S3[S3 Backup]
    end
    
    DB -->|Daily Snapshot<br/>Automated| S3
    
    style PROD fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    style BACKUP fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style DB fill:#2962ff,stroke:#0d47a1,stroke-width:2px,color:#fff
    style S3 fill:#569A31,stroke:#3c6e26,stroke-width:2px,color:#fff
```

**Vantagens desta abordagem:**
- ✅ Custo reduzido (não duplica infraestrutura)
- ✅ Compliance com LGPD (backup em território nacional - sa-east-1)
- ✅ Recuperação possível em caso de desastre
- ❌ RTO maior (~4-8h para restaurar manualmente)

---

# 13. Painel de Administração

## Visão Geral

O painel de administração é uma interface web para gestão do ambiente n-agent, com acesso restrito aos administradores da plataforma.

## Arquitetura

```mermaid
graph TD
    A[Admin Panel<br/>React App] --> B[BFF Lambda<br/>Auth + API]
    B --> C[(DynamoDB<br/>AgentConfig)]
    B --> D[Secrets Manager<br/>API Keys]
    A --> E[CloudFront<br/>IP whitelist/VPN]
    
    style A fill:#61dafb,stroke:#20232a,stroke-width:2px
    style B fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style C fill:#2962ff,stroke:#0d47a1,stroke-width:2px,color:#fff
    style D fill:#d13212,stroke:#8b0000,stroke-width:2px,color:#fff
    style E fill:#8C4FFF,stroke:#5c2d91,stroke-width:2px,color:#fff
```

## Funcionalidades

### 1. Gestão de Prompts (MVP)

Interface para criar, editar e versionar prompts dos agentes.

```typescript
interface PromptEditorState {
  selectedAgent: AgentType;
  versions: PromptVersion[];
  activeVersion: PromptVersion;
  draftContent: string;
  variables: Variable[];
  diffView: boolean;
}
```

**Tela de Prompts:**
- Lista de agentes com indicador de versão ativa
- Editor de texto com syntax highlighting
- Painel de variáveis disponíveis (ex: `{{tripContext}}`)
- Histórico de versões com diff visual
- Botões: "Salvar Rascunho", "Publicar Versão", "Rollback"

### 2. Configuração de Integrações (MVP)

Interface para configurar parâmetros das integrações externas.

```typescript
interface IntegrationConfig {
  name: string;
  icon: string;
  enabled: boolean;
  parameters: {
    apiKeyRef?: string;        // Referência ao Secrets Manager
    endpoint?: string;
    rateLimits?: RateLimitConfig;
    cacheTTL?: Record<string, number>;
    customFields?: Record<string, any>;
  };
  healthStatus: 'healthy' | 'degraded' | 'down';
  lastChecked: string;
}
```

**Tela de Integrações:**
- Cards para cada integração (Google Maps, Gemini, WhatsApp, etc.)
- Indicador de status (verde/amarelo/vermelho)
- Formulário de configuração por integração
- Botão de "Test Connection"
- Logs de uso e erros recentes

### 3. Gestão de Administradores (MVP)

Capacidade de adicionar e remover administradores da plataforma.

```typescript
interface AdminUser {
  email: string;
  name: string;
  role: 'SUPER_ADMIN' | 'ADMIN' | 'VIEWER';
  permissions: Permission[];
  createdAt: string;
  lastLogin: string;
  status: 'active' | 'invited' | 'disabled';
}

enum Permission {
  PROMPTS_READ = 'prompts:read',
  PROMPTS_WRITE = 'prompts:write',
  INTEGRATIONS_READ = 'integrations:read',
  INTEGRATIONS_WRITE = 'integrations:write',
  USERS_READ = 'users:read',
  USERS_WRITE = 'users:write',
  ANALYTICS_READ = 'analytics:read'
}
```

**Tela de Administradores:**
- Lista de admins com papel e status
- Convite por email
- Gestão de permissões granulares
- Logs de ações por admin

### 4. Dashboard de Monitoramento (MVP)

Métricas de uso, custos e saúde do sistema.

**Métricas exibidas:**
- Usuários ativos (diário/mensal)
- Viagens ativas por fase
- Uso de tokens por agente
- Custos AWS (estimado)
- Taxa de erro por serviço
- Latência P50/P95/P99

### 5. Logs de Auditoria (MVP)

Histórico de alterações em configurações e prompts.

```typescript
interface AuditEntry {
  id: string;
  timestamp: string;
  actor: string;           // email do admin
  action: AuditAction;
  resource: string;        // ex: "PROMPT#ROUTER#VERSION#3"
  previousValue?: any;
  newValue?: any;
  ip: string;
  userAgent: string;
}

enum AuditAction {
  PROMPT_CREATED = 'prompt.created',
  PROMPT_UPDATED = 'prompt.updated',
  PROMPT_ACTIVATED = 'prompt.activated',
  PROMPT_ROLLBACK = 'prompt.rollback',
  INTEGRATION_UPDATED = 'integration.updated',
  INTEGRATION_ENABLED = 'integration.enabled',
  INTEGRATION_DISABLED = 'integration.disabled',
  ADMIN_INVITED = 'admin.invited',
  ADMIN_REMOVED = 'admin.removed',
  ADMIN_PERMISSION_CHANGED = 'admin.permission_changed'
}
```

## Segurança do Painel Admin

| Controle | Implementação |
|----------|---------------|
| **Autenticação** | Cognito com MFA obrigatório |
| **Autorização** | Roles e permissions granulares |
| **Acesso à rede** | CloudFront + WAF (IP whitelist ou VPN) |
| **Auditoria** | Log de todas as ações administrativas |
| **Secrets** | Chaves de API armazenadas no Secrets Manager, nunca expostas no frontend |

---

# 14. Estimativa de Custos AWS (MVP)

## Cenário: 1.000 usuários ativos, 100 viagens/mês

| Serviço | Uso Estimado | Custo/mês |
|---------|--------------|-----------|
| **Lambda** | 500K invocações | ~$5 |
| **API Gateway** | 1M requests | ~$3.50 |
| **DynamoDB** | 10GB + 5M reads | ~$15 |
| **S3** | 50GB storage | ~$1.15 |
| **CloudFront** | 100GB transfer | ~$8.50 |
| **Bedrock (Multi-Agent)** | 10M tokens (mix) | ~$20 |
| **Cognito** | 1K MAU | Free |
| **EventBridge** | 100K eventos | ~$1 |
| **SES** | 10K emails | ~$1 |
| **CloudWatch** | Logs + métricas | ~$10 |
| **AgentCore Runtime** | Incluído | ~$0 |
| **Secrets Manager** | 10 secrets | ~$4 |

### **Total Estimado: ~$70/mês**

## APIs Externas

| API | Uso Estimado | Custo/mês |
|-----|--------------|-----------|
| Google Maps | 5K requests | ~$0 (crédito $200) |
| Gemini 2.0 + Search | 2K queries | ~$70 |
| WhatsApp | 1K conversas | ~$0 (free tier) |
| Booking Affiliate | N/A | $0 (comissão) |
| Airbnb (scraping) | 3K requests | ~$50 |
| AviationStack | 5K requests | ~$49 |
| OpenWeather | 10K calls | ~$0 (free tier) |

### **Total Infra + APIs: ~$240-290/mês no MVP**

**Nota**: Com a arquitetura multi-agent, houve redução de ~$30/mês em custos de LLM devido à otimização de modelos por tarefa. Com 100 viagens pagas/mês a R$ 149 (Concierge), receita bruta = R$ 14.900 (~$3.000). **Margem operacional saudável de ~90%.**
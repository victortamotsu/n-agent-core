# 1. Arquitetura de Solução (AWS Serverless)

A arquitetura será baseada no padrão **Event-Driven** (Orientada a Eventos). O chat não deve esperar a IA "pensar" e consultar 5 APIs de viagem. O chat recebe a mensagem, avisa que recebeu, e o processamento ocorre em segundo plano, notificando o usuário quando pronto.

## Diagrama Conceitual dos Serviços

### Camada de Entrada (Edge & API)

- **Amazon CloudFront**: CDN para o site React e assets estáticos.
- **Amazon API Gateway**: Porta de entrada para todas as requisições (Web e Webhooks do WhatsApp).
- **AWS WAF**: Firewall para proteger contra ataques.

### Camada de Orquestração (O "Cérebro")

- **AWS Lambda (BFF - Backend for Frontend)**: Resolve as requisições do site.
- **Amazon Bedrock Agents**: Onde o fluxo da conversa é gerenciado. O Agente decide qual ferramenta (Tool) chamar.
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
- Tabela `Users`
- Tabela `Trips` (Single Table Design sugerido para relacionar Viagem ↔ Itens ↔ Membros)
- Tabela `ChatHistory`

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
│   ├── /admin-panel      (React - Painel interno)
│   └── /api-bff          (Node.js - Lambdas que atendem o front)
│
├── /packages             (Bibliotecas compartilhadas)
│   ├── /ui-lib           (Seus componentes de Design System M3)
│   ├── /core-types       (Interfaces TS: IUser, ITrip, IBooking)
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
## C. Gemini com Google Search (Grounding)

⚠️ **Atenção**: Como sua infra é AWS, o Gemini não é "nativo" (o nativo é o Amazon Titan/Nova ou Anthropic Claude). Para usar o Gemini com Search, você tem duas opções:

### Opção 1: Híbrida (Recomendada para MVP)

Sua Lambda na AWS chama a API da **Vertex AI** (Google Cloud).

**Feature**: "Grounding with Google Search". Você envia o prompt para o Gemini Pro e ativa a flag de Search. A resposta já vem com os dados atualizados da web e links (citações).

**Custo:**
- **Gemini 1.5 Flash**: Muito barato
- **Grounding**: ~$35 USD por 1.000 queries de Search (preço estimado, varia por volume)

### Opção 2: 100% AWS (Alternativa)

Usar o modelo **Claude 3.5 Sonnet** no Bedrock + Ferramenta de Busca.

- Você usaria uma API de busca como **Serper.dev** ou **Tavily** (feitas para IA).
- O Claude decide "preciso buscar no Google", chama a ferramenta Serper, recebe o JSON com resultados e formula a resposta.

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
# 4. Roadmap Técnico Sugerido

1. **Setup do Monorepo e CI/CD**: Garantir que o "Hello World" da Lambda chegue na AWS.
2. **Módulo WhatsApp**: Fazer o bot responder "Oi" via Webhook.
3. **Cérebro (Bedrock)**: Configurar o Agente e criar a primeira "Tool" simples (ex: consultar clima).
4. **BFF e Painel Web**: Criar o login e a visualização básica do chat.
5. **Integração de Mapas**: Permitir que o bot gere um link de mapa.
6. **Integração de Voos/Hotéis**
4. Roadmap Técnico Sugerido
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

### Tabela 2: NAgentChatHistory (Logs de Conversa)

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

Próximo passo que posso fazer por você: Quer que eu escreva um Prompt de Sistema (System Prompt) inicial para o Amazon Bedrock Agent? Posso criar as instruções que definem a **personalidade** do agente e as regras estritas de como ele deve usar essas ferramentas JSON que definimos acima.
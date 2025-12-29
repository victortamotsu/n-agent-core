# Fase 1 - Fundação

## Objetivo
Construir a base da plataforma: deploy do agente no AgentCore Runtime, configuração de memória, banco de dados e autenticação.

## Entradas
- Ambiente preparado (Fase 0 completa)
- AWS CLI configurado
- Código do agente básico funcionando localmente

## Saídas
- Agente deployado no AgentCore Runtime
- AgentCore Memory configurado
- Tabelas DynamoDB criadas
- Cognito User Pool configurado
- API Gateway básico funcionando

## Duração Estimada: 2 semanas

---

## 🚨 Mudanças Arquiteturais Importantes

Esta fase foi atualizada para refletir decisões do arquivo [00_arquitetura.md](./00_arquitetura.md):

1. **OAuth Microsoft (Azure AD)**: Adicionado Passo 1.8 com configuração completa:
   - Registro de aplicação no Azure AD
   - Identity Provider no Cognito via OIDC
   - Suporte a login com Microsoft, Google e Email/Senha
   - **Custo**: $0 para até 50.000 MAU (Monthly Active Users)

2. **Objetivo**: Oferecer múltiplos provedores de login para facilitar adesão do usuário

---

## Semana 1: AgentCore Runtime + Memory

### Passo 1.1: Deploy do Agente no Runtime

#### Ações de Construção

Criar o arquivo de configuração do AgentCore:

**agent/.bedrock_agentcore.yaml**
```yaml
name: n-agent
description: Assistente pessoal de viagens
region: us-east-1

runtime:
  entrypoint: src/main.py
  python_version: "3.13"
  timeout: 300
  memory: 1024

environment:
  DYNAMODB_TABLE: n-agent-core
  S3_BUCKET: n-agent-documents
  LOG_LEVEL: INFO
```

#### Comandos de Deploy

```bash
cd agent

# Login no AWS (se necessário)
aws configure

# Deploy do agente
agentcore launch --wait

# Verificar status
agentcore status
```

#### Verificação

```bash
# Invocar o agente deployado
agentcore invoke '{"prompt": "Olá, estou planejando uma viagem!"}'
```

#### Saída Esperada
```json
{
  "result": "Olá! Que ótimo que você está planejando uma viagem! ...",
  "session_id": "default"
}
```

---

### Passo 1.2: Configurar AgentCore Memory

#### IMPORTANTE: Memory é Gerenciado pela AWS

AgentCore Memory **NÃO requer** provisionar:
- ❌ OpenSearch Serverless ($345/mês)
- ❌ S3 Vectors
- ❌ Aurora PostgreSQL
- ❌ DynamoDB custom

AWS gerencia storage internamente (DynamoDB + S3) sem custo extra.

#### Criar Memory Resource via AWS CLI

```bash
# Criar Memory com estratégia de sumarização
aws bedrock-agentcore-control create-memory \
  --name "n-agent-memory" \
  --description "Session memory for n-agent travel assistant" \
  --strategies '[
    {
      "summaryMemoryStrategy": {
        "name": "TripSessionSummarizer",
        "namespaces": [
          "/summaries/{actorId}/{sessionId}",
          "/trips/{tripId}/context"
        ]
      }
    }
  ]' \
  --region us-east-1
```

#### Salvar Memory ID

```bash
# Exemplo de output:
# {
#   "id": "mem-abc123xyz",
#   "name": "n-agent-memory",
#   "status": "ACTIVE"
# }

# Adicionar ao GitHub Secrets
gh secret set BEDROCK_AGENTCORE_MEMORY_ID --body "mem-abc123xyz"

# Adicionar ao .env local
echo "BEDROCK_AGENTCORE_MEMORY_ID=mem-abc123xyz" >> agent/.env
```

#### Verificação

```bash
# Listar memories
aws bedrock-agentcore-control list-memories --region us-east-1

# Detalhes do memory
aws bedrock-agentcore-control get-memory \
  --memory-id mem-abc123xyz \
  --region us-east-1
```

---

### Passo 1.3: Integrar Memory no Agente

#### Usar MemoryClient SDK (não custom implementation)

**agent/src/memory/agentcore_memory.py** (já implementado):

```python
from bedrock_agentcore.memory import MemoryClient

class AgentCoreMemory:
    def __init__(self, memory_id: str, region_name: str = "us-east-1"):
        self.memory_id = memory_id
        self.client = MemoryClient(region_name=region_name)
    
    def add_interaction(
        self,
        actor_id: str,
        session_id: str,
        user_message: str,
        agent_response: str
    ) -> None:
        """Save interaction to Memory."""
        request = CreateEventRequest(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            messages=[
                ConversationalMessage(content=user_message, role=MessageRole.USER),
                ConversationalMessage(content=agent_response, role=MessageRole.ASSISTANT)
            ]
        )
        self.client.create_event(request)
    
    def retrieve_context(
        self,
        actor_id: str,
        session_id: str,
        query: str,
        top_k: int = 5
    ) -> List[Dict]:
        """Retrieve relevant memories."""
        request = RetrieveMemoriesRequest(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            query=query,
            max_results=top_k
        )
        
        response = self.client.retrieve_memories(request)
        return [
            {
                "content": m.content,
                "timestamp": m.timestamp,
                "role": m.role,
                "score": m.score
            }
            for m in response.memories
        ]
```

#### Atualizar agent/src/main.py

```python
from bedrock_agentcore.runtime import App
from bedrock_agentcore.memory import MemoryClient
from bedrock_agentcore.memory.types import (
    ConversationalMessage,
    MessageRole,
    CreateEventRequest,
    RetrieveMemoriesRequest
)
from strands import Agent
import os

app = App()

# ID da memória criada via AWS CLI
MEMORY_ID = os.environ.get("BEDROCK_AGENTCORE_MEMORY_ID")

@app.entrypoint
def handle_request(event: dict) -> dict:
    """Entrypoint do agente n-agent com Memory nativo."""
    
    prompt = event.get("prompt", "")
    user_id = event.get("user_id", "anonymous")
    trip_id = event.get("trip_id")
    session_id = event.get("session_id", f"session-{user_id}")
    
    # Inicializar Memory client
    memory = MemoryClient(region_name="us-east-1")
    
    # Recuperar contexto relevante
    retrieve_request = RetrieveMemoriesRequest(
        memory_id=MEMORY_ID,
        actor_id=user_id,
        session_id=session_id,
        query=prompt,
        max_results=5
    )
    
    memories = memory.retrieve_memories(retrieve_request)
    
    # Construir contexto do prompt
    context_parts = []
    if memories.memories:
        context_parts.append("## Previous Context")
        for mem in memories.memories:
            context_parts.append(f"- {mem.content} (score: {mem.score:.2f})")
    
    full_context = "\n".join(context_parts) if context_parts else ""
    
    # Executar agente
    agent = Agent(
        model="us.amazon.nova-lite-v1:0",
        system_prompt=f"""
Você é o n-agent, um assistente pessoal de viagens.
Seja simpático, prestativo e proativo.

{full_context}
"""
    )
    
    response = agent.run(prompt)
    
    # Salvar interação no Memory
    event_request = CreateEventRequest(
        memory_id=MEMORY_ID,
        actor_id=user_id,
        session_id=session_id,
        messages=[
            ConversationalMessage(content=prompt, role=MessageRole.USER),
            ConversationalMessage(content=str(response), role=MessageRole.ASSISTANT)
        ]
    )
    
    memory.create_event(event_request)
    
    return {
        "result": str(response),
        "session_id": session_id,
        "user_id": user_id,
        "trip_id": trip_id
    }
```

#### Atualizar .bedrock_agentcore.yaml

```yaml
name: n-agent
description: Assistente pessoal de viagens
region: us-east-1

runtime:
  entrypoint: src/main.py
  python_version: "3.13"
  timeout: 300
  memory: 1024

environment:
  DYNAMODB_TABLE: n-agent-core
  S3_BUCKET: n-agent-documents
  BEDROCK_AGENTCORE_MEMORY_ID: mem-xxxxx  # Substituir pelo ID real
  LOG_LEVEL: INFO

dependencies:
  - strands-agents>=0.1.0
  - boto3>=1.35.0
  - bedrock-agentcore>=1.0.0  # SDK para Memory
```

#### Re-deploy

```bash
agentcore launch --wait
```

---

## Semana 2: DynamoDB + Cognito + API Gateway

### Passo 1.4: Criar Tabelas DynamoDB

#### Ação Manual (Console) ou Terraform

**Opção A: Console AWS**

1. Acesse [DynamoDB Console](https://console.aws.amazon.com/dynamodb/)
2. Clique em **Create table**
3. Configure:
   - Table name: `n-agent-core`
   - Partition key: `PK` (String)
   - Sort key: `SK` (String)
4. Em **Settings**, selecione **Customize settings**
5. Configure GSI:
   - GSI name: `GSI1`
   - Partition key: `GSI1PK` (String)
   - Sort key: `GSI1SK` (String)
6. Clique em **Create table**

**Repetir para `n-agent-chat` (histórico de chat)**

**Opção B: Terraform (Recomendado)**

Criar arquivo **infra/terraform/modules/dynamodb/main.tf**:

```hcl
resource "aws_dynamodb_table" "core" {
  name           = "n-agent-core"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project     = "n-agent"
    Environment = "prod"
  }
}

resource "aws_dynamodb_table" "chat" {
  name           = "n-agent-chat"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = {
    Project     = "n-agent"
    Environment = "prod"
  }
}
```

```bash
cd infra/terraform
terraform init
terraform apply
```

---

### Passo 1.5: Configurar Cognito User Pool

#### Ação Manual (Console)

1. Acesse [Amazon Cognito Console](https://console.aws.amazon.com/cognito/)
2. Clique em **Create user pool**
3. Configure Sign-in:
   - ✅ Email
   - ✅ Phone number (para WhatsApp)
4. Configure Password Policy:
   - Minimum length: 8
   - Require numbers, special characters
5. Configure MFA:
   - Optional MFA
   - SMS e Authenticator app
6. Configure Sign-up:
   - ✅ Allow self-registration
   - Attributes: name, email, phone_number
7. Configure Message delivery:
   - Email: Amazon SES (configurar depois)
   - SMS: Amazon SNS
8. Configure App integration:
   - App client name: `n-agent-web`
   - ✅ ALLOW_USER_PASSWORD_AUTH
   - ✅ ALLOW_REFRESH_TOKEN_AUTH
9. Copie:
   - **User Pool ID**: `us-east-1_xxxxxxxx`
   - **App Client ID**: `xxxxxxxxxxxxxxxxxxxxxxxxxx`

#### Terraform (Alternativa)

**infra/terraform/modules/cognito/main.tf**:

```hcl
resource "aws_cognito_user_pool" "main" {
  name = "n-agent-users"

  username_attributes      = ["email", "phone_number"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  tags = {
    Project = "n-agent"
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "n-agent-web"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = false

  access_token_validity  = 1  # horas
  refresh_token_validity = 30 # dias
}

output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.web.id
}
```

---

### Passo 1.6: Criar API Gateway

#### Terraform

**infra/terraform/modules/api-gateway/main.tf**:

```hcl
resource "aws_apigatewayv2_api" "main" {
  name          = "n-agent-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["http://localhost:5173", "https://n-agent.com"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/n-agent-api"
  retention_in_days = 30
}

# Authorizer usando Cognito
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}
```

---

### Passo 1.8: Configurar OAuth Microsoft (Azure AD)

#### Pré-requisitos

1. **Registrar aplicação no Azure AD**:
   - Acesse: https://portal.azure.com → Azure Active Directory → App registrations
   - Clique em "New registration"
   - Nome: "n-agent"
   - Redirect URI: `https://<cognito-domain>.auth.us-east-1.amazoncognito.com/oauth2/idpresponse`
   - Copie: Application (client) ID e Directory (tenant) ID
   - Em "Certificates & secrets", crie um Client secret e copie o valor

2. **Configurar permissões**:
   - Em "API permissions", adicione:
     - Microsoft Graph → Delegated → `openid`
     - Microsoft Graph → Delegated → `profile`
     - Microsoft Graph → Delegated → `email`

#### Terraform

**infra/terraform/modules/cognito/oauth.tf**:

```hcl
# Identity Provider Microsoft
resource "aws_cognito_identity_provider" "microsoft" {
  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Microsoft"
  provider_type = "OIDC"

  provider_details = {
    client_id                     = var.azure_client_id
    client_secret                 = var.azure_client_secret
    authorize_scopes              = "openid profile email"
    oidc_issuer                   = "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0"
    attributes_request_method     = "GET"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
    name     = "name"
  }
}

# Adicionar Microsoft como opção de login no App Client
resource "aws_cognito_user_pool_client" "app" {
  # ... configuração existente ...
  
  supported_identity_providers = [
    "COGNITO",
    aws_cognito_identity_provider.microsoft.provider_name
  ]

  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_scopes = ["openid", "profile", "email"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls = [
    "http://localhost:5173/auth/callback",
    "https://app.n-agent.com/auth/callback"
  ]
  logout_urls = [
    "http://localhost:5173",
    "https://app.n-agent.com"
  ]
}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.us-east-1.amazoncognito.com"
}

output "microsoft_login_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.us-east-1.amazoncognito.com/oauth2/authorize?identity_provider=Microsoft&client_id=${aws_cognito_user_pool_client.app.id}&response_type=code&scope=openid+profile+email&redirect_uri=https://app.n-agent.com/auth/callback"
}
```

---

### Passo 1.7: Conectar API Gateway ao AgentCore

#### Lambda de Proxy

Criar uma Lambda que recebe requisições do API Gateway e invoca o AgentCore Runtime.

**lambdas/bff/src/handler.py**:

```python
import json
import boto3
import os

agentcore = boto3.client('bedrock-agentcore', region_name='us-east-1')

RUNTIME_ARN = os.environ['AGENTCORE_RUNTIME_ARN']

def handler(event, context):
    """Handler do BFF que invoca o AgentCore Runtime."""
    
    # Extrair dados do request
    body = json.loads(event.get('body', '{}'))
    
    # Extrair user do JWT (via Cognito authorizer)
    claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
    user_id = claims.get('sub', 'anonymous')
    
    # Invocar AgentCore Runtime
    response = agentcore.invoke_agent(
        agentRuntimeArn=RUNTIME_ARN,
        inputText=body.get('prompt', ''),
        sessionId=f"session-{user_id}",
        sessionState={
            'sessionAttributes': {
                'user_id': user_id,
                'trip_id': body.get('trip_id')
            }
        }
    )
    
    # Processar resposta streaming
    result = ""
    for event in response['completion']:
        if 'chunk' in event:
            result += event['chunk']['bytes'].decode()
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'result': result,
            'session_id': f"session-{user_id}"
        })
    }
```

---

## Checklist de Conclusão da Fase 1

- [ ] Agente deployado no AgentCore Runtime
- [ ] `agentcore invoke` funcionando
- [ ] AgentCore Memory criado com strategies
- [ ] Memória integrada no agente
- [ ] Tabela DynamoDB `n-agent-core` criada
- [ ] Tabela DynamoDB `n-agent-chat` criada
- [ ] Cognito User Pool configurado
- [ ] API Gateway HTTP criado
- [ ] Authorizer Cognito configurado
- [ ] Lambda BFF conectando API Gateway → AgentCore

---

## Testes de Validação

### Teste 1: Memória Funcionando

```bash
# Primeira mensagem
agentcore invoke '{"prompt": "Meu nome é Victor e quero viajar para Roma", "user_id": "user-123"}'

# Segunda mensagem (deve lembrar o nome)
agentcore invoke '{"prompt": "Qual era meu destino mesmo?", "user_id": "user-123"}'
```

### Teste 2: API Gateway → AgentCore

```bash
# Obter token do Cognito (usar AWS CLI ou app de teste)
TOKEN="eyJraWQ..."

curl -X POST https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Olá!"}'
```

---

## Próxima Fase

Com a fundação pronta, siga para a **[Fase 2 - Integrações](./03_fase2_integracoes.md)** onde vamos:
- Configurar AgentCore Gateway
- Integrar WhatsApp
- Conectar Google Maps API
- Configurar Booking/Airbnb

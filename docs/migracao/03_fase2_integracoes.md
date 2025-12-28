# Fase 2 - Integrações

## Objetivo
Conectar o agente com o mundo externo: WhatsApp para comunicação, Google Maps para localização, e APIs de viagem via AgentCore Gateway.

## Entradas
- Fase 1 completa (Agente funcionando com memória)
- Credenciais do Meta WhatsApp Business
- Credenciais do Google Cloud (Vertex AI + Maps)
- API keys de parceiros (Booking, AviationStack, etc.)

## Saídas
- WhatsApp integrado (envio e recebimento)
- AgentCore Gateway configurado com targets
- Ferramentas de busca de hotéis/voos funcionando
- Google Maps integrado
- Gemini com Search funcionando

## Duração Estimada: 3 semanas

---

## Semana 1: WhatsApp Integration

### Passo 2.1: Criar Webhook Handler

O WhatsApp envia mensagens via webhook. Precisamos de uma Lambda para receber.

**lambdas/whatsapp-webhook/src/handler.py**:

```python
import json
import boto3
import hashlib
import hmac
import os
from datetime import datetime

# Clients
dynamodb = boto3.resource('dynamodb')
agentcore = boto3.client('bedrock-agentcore', region_name='us-east-1')
secrets = boto3.client('secretsmanager')

# Config
VERIFY_TOKEN = os.environ.get('WHATSAPP_VERIFY_TOKEN', 'n-agent-verify-2024')
RUNTIME_ARN = os.environ['AGENTCORE_RUNTIME_ARN']
CHAT_TABLE = os.environ.get('CHAT_TABLE', 'n-agent-chat')

def get_whatsapp_credentials():
    """Recupera credenciais do Secrets Manager."""
    secret = secrets.get_secret_value(SecretId='n-agent/whatsapp-credentials')
    return json.loads(secret['SecretString'])

def verify_webhook(event):
    """Verifica o webhook do Meta (challenge)."""
    params = event.get('queryStringParameters', {}) or {}
    mode = params.get('hub.mode')
    token = params.get('hub.verify_token')
    challenge = params.get('hub.challenge')
    
    if mode == 'subscribe' and token == VERIFY_TOKEN:
        return {
            'statusCode': 200,
            'body': challenge
        }
    return {'statusCode': 403, 'body': 'Forbidden'}

def send_whatsapp_message(phone_number_id, to, message, access_token):
    """Envia mensagem via WhatsApp Cloud API."""
    import urllib.request
    
    url = f"https://graph.facebook.com/v18.0/{phone_number_id}/messages"
    
    data = json.dumps({
        "messaging_product": "whatsapp",
        "to": to,
        "type": "text",
        "text": {"body": message}
    }).encode()
    
    req = urllib.request.Request(url, data=data)
    req.add_header('Authorization', f'Bearer {access_token}')
    req.add_header('Content-Type', 'application/json')
    
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read())

def process_message(event_data):
    """Processa mensagem recebida do WhatsApp."""
    
    changes = event_data.get('entry', [{}])[0].get('changes', [{}])[0]
    value = changes.get('value', {})
    
    # Extrair metadata
    metadata = value.get('metadata', {})
    phone_number_id = metadata.get('phone_number_id')
    
    # Extrair mensagem
    messages = value.get('messages', [])
    if not messages:
        return None  # Não é uma mensagem (pode ser status update)
    
    message = messages[0]
    from_number = message.get('from')
    msg_id = message.get('id')
    msg_type = message.get('type')
    timestamp = message.get('timestamp')
    
    # Extrair conteúdo baseado no tipo
    if msg_type == 'text':
        content = message.get('text', {}).get('body', '')
    elif msg_type == 'image':
        content = "[Imagem recebida]"
        # TODO: Baixar e processar imagem
    elif msg_type == 'audio':
        content = "[Áudio recebido]"
        # TODO: Transcrever áudio
    elif msg_type == 'document':
        content = f"[Documento: {message.get('document', {}).get('filename', 'arquivo')}]"
    elif msg_type == 'location':
        loc = message.get('location', {})
        content = f"[Localização: {loc.get('latitude')}, {loc.get('longitude')}]"
    else:
        content = f"[Tipo não suportado: {msg_type}]"
    
    return {
        'phone_number_id': phone_number_id,
        'from': from_number,
        'message_id': msg_id,
        'type': msg_type,
        'content': content,
        'timestamp': timestamp
    }

def invoke_agent(user_phone, content):
    """Invoca o AgentCore Runtime com a mensagem do usuário."""
    
    response = agentcore.invoke_agent(
        agentRuntimeArn=RUNTIME_ARN,
        inputText=content,
        sessionId=f"whatsapp-{user_phone}",
        sessionState={
            'sessionAttributes': {
                'user_id': user_phone,
                'channel': 'whatsapp'
            }
        }
    )
    
    # Processar resposta streaming
    result = ""
    for event in response['completion']:
        if 'chunk' in event:
            result += event['chunk']['bytes'].decode()
    
    return result

def save_chat_history(user_phone, user_msg, agent_msg):
    """Salva histórico no DynamoDB."""
    table = dynamodb.Table(CHAT_TABLE)
    
    timestamp = datetime.utcnow().isoformat()
    
    # Salvar mensagem do usuário
    table.put_item(Item={
        'PK': f'PHONE#{user_phone}',
        'SK': f'MSG#{timestamp}#USER',
        'sender': 'USER',
        'content': user_msg,
        'timestamp': timestamp
    })
    
    # Salvar resposta do agente
    table.put_item(Item={
        'PK': f'PHONE#{user_phone}',
        'SK': f'MSG#{timestamp}#AGENT',
        'sender': 'AGENT',
        'content': agent_msg,
        'timestamp': timestamp
    })

def handler(event, context):
    """Handler principal do webhook."""
    
    # Verificação inicial do webhook (GET)
    if event.get('httpMethod') == 'GET':
        return verify_webhook(event)
    
    # Processar mensagem (POST)
    try:
        body = json.loads(event.get('body', '{}'))
        
        # Processar evento
        parsed = process_message(body)
        if not parsed:
            return {'statusCode': 200, 'body': 'OK'}
        
        # Invocar agente
        agent_response = invoke_agent(parsed['from'], parsed['content'])
        
        # Salvar histórico
        save_chat_history(parsed['from'], parsed['content'], agent_response)
        
        # Enviar resposta via WhatsApp
        creds = get_whatsapp_credentials()
        send_whatsapp_message(
            parsed['phone_number_id'],
            parsed['from'],
            agent_response,
            creds['access_token']
        )
        
        return {'statusCode': 200, 'body': 'OK'}
        
    except Exception as e:
        print(f"Error: {e}")
        return {'statusCode': 500, 'body': str(e)}
```

### Passo 2.2: Configurar Webhook no Meta

#### Ações Manuais

1. Acesse [Meta for Developers](https://developers.facebook.com/)
2. Vá para seu App → WhatsApp → Configuration
3. Configure Webhook:
   - **Callback URL**: `https://{api-gateway-id}.execute-api.us-east-1.amazonaws.com/prod/webhooks/whatsapp`
   - **Verify Token**: `n-agent-verify-2024`
4. Subscribe to fields:
   - ✅ messages
   - ✅ message_deliveries
   - ✅ message_reads
5. Clique em **Verify and Save**

#### Verificação

Envie uma mensagem para o número do WhatsApp Business e verifique se o bot responde.

---

## Semana 2: AgentCore Gateway + Google Maps

### Passo 2.3: Criar AgentCore Gateway

#### Ações Manuais (Console)

1. Acesse [Amazon Bedrock AgentCore Console](https://console.aws.amazon.com/bedrock-agentcore/)
2. Vá para **Gateway**
3. Clique em **Create gateway**
4. Configure:
   - Name: `n-agent-gateway`
   - Description: `Gateway para ferramentas do assistente de viagens`
5. Configure OAuth Authorizer (usando Cognito):
   - Authorizer type: **Cognito**
   - User Pool ID: `us-east-1_xxxxxxxx`
   - App Client ID: `xxxxxxxxxx`
6. Clique em **Create**

Copie o **Gateway ID** gerado.

### Passo 2.4: Adicionar Target - Google Maps

#### Criar Lambda para Google Maps

**lambdas/integrations/google-maps/handler.py**:

```python
import json
import os
import urllib.request
import urllib.parse

GOOGLE_MAPS_API_KEY = os.environ.get('GOOGLE_MAPS_API_KEY')

def search_places(query: str, location: str = None, radius: int = 5000):
    """Busca lugares usando Google Places API."""
    
    base_url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    
    params = {
        'query': query,
        'key': GOOGLE_MAPS_API_KEY
    }
    
    if location:
        params['location'] = location
        params['radius'] = radius
    
    url = f"{base_url}?{urllib.parse.urlencode(params)}"
    
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read())
        
    results = []
    for place in data.get('results', [])[:5]:
        results.append({
            'name': place.get('name'),
            'address': place.get('formatted_address'),
            'rating': place.get('rating'),
            'user_ratings_total': place.get('user_ratings_total'),
            'place_id': place.get('place_id'),
            'location': place.get('geometry', {}).get('location'),
            'types': place.get('types', [])
        })
    
    return results

def get_directions(origin: str, destination: str, mode: str = 'transit'):
    """Obtém direções entre dois pontos."""
    
    base_url = "https://maps.googleapis.com/maps/api/directions/json"
    
    params = {
        'origin': origin,
        'destination': destination,
        'mode': mode,
        'key': GOOGLE_MAPS_API_KEY
    }
    
    url = f"{base_url}?{urllib.parse.urlencode(params)}"
    
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read())
    
    if not data.get('routes'):
        return {'error': 'No routes found'}
    
    route = data['routes'][0]
    leg = route['legs'][0]
    
    return {
        'distance': leg.get('distance', {}).get('text'),
        'duration': leg.get('duration', {}).get('text'),
        'start_address': leg.get('start_address'),
        'end_address': leg.get('end_address'),
        'steps': [
            {
                'instruction': step.get('html_instructions', '').replace('<b>', '').replace('</b>', ''),
                'distance': step.get('distance', {}).get('text'),
                'duration': step.get('duration', {}).get('text')
            }
            for step in leg.get('steps', [])[:10]
        ]
    }

def handler(event, context):
    """Handler Lambda para Google Maps."""
    
    action = event.get('action')
    params = event.get('params', {})
    
    if action == 'search_places':
        result = search_places(
            query=params.get('query'),
            location=params.get('location'),
            radius=params.get('radius', 5000)
        )
    elif action == 'get_directions':
        result = get_directions(
            origin=params.get('origin'),
            destination=params.get('destination'),
            mode=params.get('mode', 'transit')
        )
    else:
        result = {'error': f'Unknown action: {action}'}
    
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
```

#### Adicionar Target no Gateway (Console)

1. No Gateway `n-agent-gateway`, clique em **Add target**
2. Configure:
   - Target type: **Lambda**
   - Name: `google-maps`
   - Lambda ARN: `arn:aws:lambda:us-east-1:xxx:function:n-agent-google-maps`
3. Defina as Tools:
   ```json
   {
     "tools": [
       {
         "name": "search_places",
         "description": "Busca lugares no Google Maps. Use para encontrar restaurantes, hotéis, atrações turísticas, etc.",
         "inputSchema": {
           "type": "object",
           "properties": {
             "query": {
               "type": "string",
               "description": "O que buscar (ex: 'restaurantes em Roma')"
             },
             "location": {
               "type": "string",
               "description": "Coordenadas lat,lng (opcional)"
             }
           },
           "required": ["query"]
         }
       },
       {
         "name": "get_directions",
         "description": "Obtém direções entre dois pontos. Use para calcular rotas e tempo de deslocamento.",
         "inputSchema": {
           "type": "object",
           "properties": {
             "origin": {
               "type": "string",
               "description": "Ponto de partida"
             },
             "destination": {
               "type": "string",
               "description": "Destino"
             },
             "mode": {
               "type": "string",
               "enum": ["driving", "walking", "transit"],
               "description": "Modo de transporte"
             }
           },
           "required": ["origin", "destination"]
         }
       }
     ]
   }
   ```
4. Clique em **Create target**

---

### Passo 2.5: Adicionar Target - Booking (Affiliate API)

#### Criar Lambda para Booking

**lambdas/integrations/booking/handler.py**:

```python
import json
import os
import urllib.request
import urllib.parse
from datetime import datetime

BOOKING_AFFILIATE_ID = os.environ.get('BOOKING_AFFILIATE_ID')

def search_hotels(city: str, checkin: str, checkout: str, guests: int = 2):
    """Busca hotéis via Booking.com Affiliate API."""
    
    # Nota: A API real do Booking requer aprovação.
    # Para MVP, podemos usar dados mockados ou Amadeus
    
    # Exemplo de resposta estruturada
    mock_results = [
        {
            "id": "hotel-001",
            "name": "Hotel Monti Palace",
            "city": city,
            "rating": 4.8,
            "reviews_count": 2340,
            "price_per_night": 180,
            "currency": "EUR",
            "total_price": calculate_total(180, checkin, checkout),
            "amenities": ["WiFi", "Café da manhã", "Ar condicionado"],
            "distance_to_center": "500m",
            "image_url": "https://example.com/hotel1.jpg",
            "deep_link": f"https://www.booking.com/hotel/it/monti-palace.html?aid={BOOKING_AFFILIATE_ID}"
        },
        {
            "id": "hotel-002",
            "name": "Rome Central Suites",
            "city": city,
            "rating": 4.5,
            "reviews_count": 1890,
            "price_per_night": 145,
            "currency": "EUR",
            "total_price": calculate_total(145, checkin, checkout),
            "amenities": ["WiFi", "Cozinha", "Lavanderia"],
            "distance_to_center": "800m",
            "image_url": "https://example.com/hotel2.jpg",
            "deep_link": f"https://www.booking.com/hotel/it/rome-central-suites.html?aid={BOOKING_AFFILIATE_ID}"
        }
    ]
    
    return mock_results

def calculate_total(price_per_night, checkin, checkout):
    """Calcula preço total baseado nas datas."""
    try:
        checkin_date = datetime.strptime(checkin, "%Y-%m-%d")
        checkout_date = datetime.strptime(checkout, "%Y-%m-%d")
        nights = (checkout_date - checkin_date).days
        return price_per_night * nights
    except:
        return price_per_night * 3  # Default 3 noites

def handler(event, context):
    """Handler Lambda para Booking."""
    
    action = event.get('action')
    params = event.get('params', {})
    
    if action == 'search_hotels':
        result = search_hotels(
            city=params.get('city'),
            checkin=params.get('checkin'),
            checkout=params.get('checkout'),
            guests=params.get('guests', 2)
        )
    else:
        result = {'error': f'Unknown action: {action}'}
    
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
```

---

## Semana 3: Gemini + Flight Status

### Passo 2.6: Integrar Gemini 2.0 Flash com Search

#### Criar Lambda para Gemini

**lambdas/integrations/gemini/handler.py**:

```python
import json
import os
import boto3
from google.cloud import aiplatform
from vertexai.generative_models import GenerativeModel, Tool, grounding

# Inicializar Vertex AI
def get_google_credentials():
    """Recupera credenciais do Secrets Manager."""
    secrets = boto3.client('secretsmanager')
    secret = secrets.get_secret_value(SecretId='n-agent/google-cloud-credentials')
    return json.loads(secret['SecretString'])

def search_with_gemini(query: str, context: str = ""):
    """Usa Gemini 2.0 Flash com Google Search para buscar informações atualizadas."""
    
    # Configurar credenciais
    creds = get_google_credentials()
    os.environ['GOOGLE_APPLICATION_CREDENTIALS_JSON'] = json.dumps(creds)
    
    aiplatform.init(
        project=creds.get('project_id', 'n-agent-project'),
        location='us-central1'
    )
    
    model = GenerativeModel(
        "gemini-2.0-flash-exp",
        tools=[Tool.from_google_search_retrieval(grounding.GoogleSearchRetrieval())]
    )
    
    prompt = f"""
{context}

Pergunta do usuário: {query}

Responda de forma útil e cite as fontes quando possível.
"""
    
    response = model.generate_content(prompt)
    
    # Extrair texto e fontes
    result = {
        'answer': response.text,
        'sources': []
    }
    
    # Extrair grounding metadata se disponível
    if hasattr(response, 'candidates') and response.candidates:
        candidate = response.candidates[0]
        if hasattr(candidate, 'grounding_metadata'):
            for chunk in candidate.grounding_metadata.grounding_chunks:
                if hasattr(chunk, 'web'):
                    result['sources'].append({
                        'title': chunk.web.title,
                        'url': chunk.web.uri
                    })
    
    return result

def handler(event, context):
    """Handler Lambda para Gemini."""
    
    action = event.get('action')
    params = event.get('params', {})
    
    if action == 'search':
        result = search_with_gemini(
            query=params.get('query'),
            context=params.get('context', '')
        )
    else:
        result = {'error': f'Unknown action: {action}'}
    
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
```

### Passo 2.7: Integrar AviationStack (Status de Voos)

**lambdas/integrations/flights/handler.py**:

```python
import json
import os
import urllib.request
import urllib.parse

AVIATIONSTACK_API_KEY = os.environ.get('AVIATIONSTACK_API_KEY')

def get_flight_status(flight_number: str, date: str = None):
    """Obtém status de um voo específico."""
    
    base_url = "http://api.aviationstack.com/v1/flights"
    
    params = {
        'access_key': AVIATIONSTACK_API_KEY,
        'flight_iata': flight_number
    }
    
    if date:
        params['flight_date'] = date
    
    url = f"{base_url}?{urllib.parse.urlencode(params)}"
    
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read())
    
    flights = data.get('data', [])
    if not flights:
        return {'error': 'Flight not found'}
    
    flight = flights[0]
    
    return {
        'flight_number': flight.get('flight', {}).get('iata'),
        'airline': flight.get('airline', {}).get('name'),
        'status': flight.get('flight_status'),
        'departure': {
            'airport': flight.get('departure', {}).get('airport'),
            'iata': flight.get('departure', {}).get('iata'),
            'terminal': flight.get('departure', {}).get('terminal'),
            'gate': flight.get('departure', {}).get('gate'),
            'scheduled': flight.get('departure', {}).get('scheduled'),
            'estimated': flight.get('departure', {}).get('estimated'),
            'delay': flight.get('departure', {}).get('delay')
        },
        'arrival': {
            'airport': flight.get('arrival', {}).get('airport'),
            'iata': flight.get('arrival', {}).get('iata'),
            'terminal': flight.get('arrival', {}).get('terminal'),
            'gate': flight.get('arrival', {}).get('gate'),
            'scheduled': flight.get('arrival', {}).get('scheduled'),
            'estimated': flight.get('arrival', {}).get('estimated')
        }
    }

def search_flights(origin: str, destination: str, date: str):
    """Busca voos disponíveis (usando dados mockados para MVP)."""
    
    # Para MVP, retornar dados estruturados
    # Na produção, integrar com Amadeus ou Skyscanner
    
    return [
        {
            'flight_number': 'BA247',
            'airline': 'British Airways',
            'origin': origin,
            'destination': destination,
            'departure_time': f'{date}T10:30:00',
            'arrival_time': f'{date}T14:45:00',
            'duration': '4h15m',
            'price': 850,
            'currency': 'EUR',
            'stops': 0,
            'deep_link': 'https://www.google.com/flights'
        },
        {
            'flight_number': 'LH1234',
            'airline': 'Lufthansa',
            'origin': origin,
            'destination': destination,
            'departure_time': f'{date}T14:00:00',
            'arrival_time': f'{date}T19:30:00',
            'duration': '5h30m',
            'price': 720,
            'currency': 'EUR',
            'stops': 1,
            'stop_cities': ['Frankfurt'],
            'deep_link': 'https://www.google.com/flights'
        }
    ]

def handler(event, context):
    """Handler Lambda para voos."""
    
    action = event.get('action')
    params = event.get('params', {})
    
    if action == 'get_status':
        result = get_flight_status(
            flight_number=params.get('flight_number'),
            date=params.get('date')
        )
    elif action == 'search':
        result = search_flights(
            origin=params.get('origin'),
            destination=params.get('destination'),
            date=params.get('date')
        )
    else:
        result = {'error': f'Unknown action: {action}'}
    
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
```

---

### Passo 2.8: Conectar Gateway ao Agente

Atualizar o agente para usar as ferramentas do Gateway.

**agent/src/main.py** (atualizado):

```python
from bedrock_agentcore.runtime import App
from bedrock_agentcore.memory.session import MemorySessionManager
from bedrock_agentcore.memory.constants import ConversationalMessage, MessageRole
from strands import Agent, tool
import boto3
import os

app = App()

MEMORY_ID = os.environ.get("AGENTCORE_MEMORY_ID")
GATEWAY_ID = os.environ.get("AGENTCORE_GATEWAY_ID")

# Cliente do Gateway
gateway = boto3.client('bedrock-agentcore', region_name='us-east-1')

# Definir ferramentas que chamam o Gateway
@tool
def search_places(query: str, location: str = None) -> dict:
    """Busca lugares no Google Maps. Use para encontrar restaurantes, hotéis, atrações."""
    response = gateway.invoke_gateway_tool(
        gatewayId=GATEWAY_ID,
        targetName='google-maps',
        toolName='search_places',
        input={'query': query, 'location': location}
    )
    return response['output']

@tool
def get_directions(origin: str, destination: str, mode: str = 'transit') -> dict:
    """Obtém direções entre dois pontos."""
    response = gateway.invoke_gateway_tool(
        gatewayId=GATEWAY_ID,
        targetName='google-maps',
        toolName='get_directions',
        input={'origin': origin, 'destination': destination, 'mode': mode}
    )
    return response['output']

@tool
def search_hotels(city: str, checkin: str, checkout: str, guests: int = 2) -> list:
    """Busca hotéis disponíveis. Datas no formato YYYY-MM-DD."""
    response = gateway.invoke_gateway_tool(
        gatewayId=GATEWAY_ID,
        targetName='booking',
        toolName='search_hotels',
        input={'city': city, 'checkin': checkin, 'checkout': checkout, 'guests': guests}
    )
    return response['output']

@tool
def search_web(query: str, context: str = "") -> dict:
    """Busca informações atualizadas na web usando Gemini + Google Search."""
    response = gateway.invoke_gateway_tool(
        gatewayId=GATEWAY_ID,
        targetName='gemini',
        toolName='search',
        input={'query': query, 'context': context}
    )
    return response['output']

@tool
def get_flight_status(flight_number: str, date: str = None) -> dict:
    """Verifica status de um voo específico."""
    response = gateway.invoke_gateway_tool(
        gatewayId=GATEWAY_ID,
        targetName='flights',
        toolName='get_status',
        input={'flight_number': flight_number, 'date': date}
    )
    return response['output']

@app.entrypoint
def handle_request(event: dict) -> dict:
    """Entrypoint do agente n-agent com ferramentas."""
    
    prompt = event.get("prompt", "")
    user_id = event.get("user_id", "anonymous")
    trip_id = event.get("trip_id")
    session_id = event.get("session_id", f"session-{user_id}")
    
    # Configurar memória...
    # (mesmo código da Fase 1)
    
    # Executar agente com ferramentas
    agent = Agent(
        model="us.amazon.nova-pro-v1:0",  # Modelo mais capaz para tool use
        tools=[
            search_places,
            get_directions,
            search_hotels,
            search_web,
            get_flight_status
        ],
        system_prompt="""
Você é o n-agent, um assistente pessoal de viagens experiente e proativo.

Suas capacidades:
- Buscar lugares, restaurantes, atrações usando Google Maps
- Calcular rotas e tempo de deslocamento
- Buscar hotéis disponíveis com preços
- Pesquisar informações atualizadas sobre destinos
- Verificar status de voos

Diretrizes:
- Seja amigável e use emojis ocasionalmente
- Sempre pergunte detalhes antes de fazer buscas (datas, quantidade de pessoas, preferências)
- Apresente opções de forma organizada
- Inclua links quando disponíveis
- Considere o orçamento e preferências do usuário
"""
    )
    
    response = agent.run(prompt)
    
    return {
        "result": str(response),
        "session_id": session_id
    }
```

---

## Checklist de Conclusão da Fase 2

- [ ] Lambda whatsapp-webhook deployada
- [ ] Webhook configurado no Meta
- [ ] Bot respondendo mensagens no WhatsApp
- [ ] AgentCore Gateway criado
- [ ] Target Google Maps funcionando
- [ ] Target Booking funcionando
- [ ] Target Gemini + Search funcionando
- [ ] Target AviationStack funcionando
- [ ] Agente usando ferramentas do Gateway

---

## Testes de Validação

### Teste WhatsApp
Envie via WhatsApp: "Quero hotéis em Roma para 7 pessoas em agosto"

### Teste Ferramentas

```bash
agentcore invoke '{
  "prompt": "Busque restaurantes perto do Coliseu em Roma",
  "user_id": "test-user"
}'
```

Resposta esperada deve incluir resultados do Google Maps.

---

## Próxima Fase

Com as integrações funcionando, siga para a **[Fase 3 - Core AI](./04_fase3_core_ai.md)** onde vamos:
- Implementar fluxo de conhecimento
- Implementar fluxo de planejamento
- Criar lógica de persistência de viagens
- Implementar geração de documentos ricos

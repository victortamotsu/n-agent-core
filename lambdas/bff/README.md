# Lambda BFF (Backend-for-Frontend)

Lambda function que atua como proxy entre API Gateway e AgentCore Runtime.

## Responsabilidades

1. ✅ Receber requisições do API Gateway
2. ✅ Extrair user info do JWT token (Cognito)
3. ✅ Invocar AgentCore Runtime via Bedrock Agent Runtime API
4. ✅ Retornar resposta formatada

## Variáveis de Ambiente

- `AGENTCORE_AGENT_ID`: ID do agent no AgentCore Runtime
- `AGENTCORE_AGENT_ALIAS_ID`: Alias do agent (default: TSTALIASID)
- `AWS_REGION`: Região AWS (default: us-east-1)

## Estrutura da Requisição

```json
{
  "prompt": "Quero viajar para Roma",
  "trip_id": "trip-123",
  "session_id": "session-456",
  "has_image": false
}
```

## Estrutura da Resposta

```json
{
  "response": "Que ótimo! Roma é uma cidade incrível...",
  "session_id": "session-456",
  "user_id": "user-789",
  "trip_id": "trip-123"
}
```

## Deploy

Deployado via Terraform (`infra/terraform/modules/lambda-bff/`).

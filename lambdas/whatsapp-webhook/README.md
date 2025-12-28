# WhatsApp Webhook Lambda

## Descrição
Lambda function que recebe webhooks do WhatsApp Business API e publica mensagens no SNS para processamento assíncrono pelo n-agent.

## Status
- **Fase 0**: ✅ Estrutura implementada (código pronto mas não conectado)
- **Fase 4**: 🔄 Ativação da integração completa

## Arquitetura

```
WhatsApp Business API
        ↓
    API Gateway
        ↓
  Lambda Webhook (esta função)
        ↓
      SNS Topic
        ↓
Lambda Processor → AgentCore Runtime
        ↓
  Resposta ao usuário
```

## Variáveis de Ambiente

```bash
AWS_REGION=us-east-1
WHATSAPP_SECRET_NAME=n-agent/whatsapp-credentials
WEBHOOK_VERIFY_TOKEN=seu-token-aleatorio-seguro
AGENT_SNS_TOPIC_ARN=arn:aws:sns:us-east-1:944938120078:n-agent-messages
```

## Credenciais WhatsApp (Secrets Manager)

```json
{
  "phone_number_id": "123456789",
  "waba_id": "987654321",
  "access_token": "EAAxxxxxxxxxxxxx",
  "app_secret": "abc123def456"
}
```

## Deploy

```bash
# Instalar dependências
npm install

# Build
npm run build

# Deploy via Terraform (Fase 1+)
npm run deploy
```

## Testes Locais

```bash
# Instalar SAM CLI
choco install aws-sam-cli

# Testar localmente
sam local invoke WhatsAppWebhook -e test-events/message.json
```

### Evento de Teste (test-events/message.json)

```json
{
  "httpMethod": "POST",
  "headers": {
    "x-hub-signature-256": "sha256=..."
  },
  "body": "{\"object\":\"whatsapp_business_account\",\"entry\":[{\"id\":\"123\",\"changes\":[{\"value\":{\"messaging_product\":\"whatsapp\",\"metadata\":{\"display_phone_number\":\"5511999999999\",\"phone_number_id\":\"123456789\"},\"messages\":[{\"from\":\"5511888888888\",\"id\":\"wamid.xxx\",\"timestamp\":\"1703779200\",\"text\":{\"body\":\"Olá! Quero planejar uma viagem para Roma.\"},\"type\":\"text\"}]},\"field\":\"messages\"}]}]}"
}
```

## Tipos de Mensagem Suportados

- ✅ **text**: Mensagens de texto simples
- ✅ **image**: Fotos e imagens
- ✅ **document**: PDFs, documentos
- ✅ **audio**: Mensagens de voz
- ✅ **video**: Vídeos
- ⏸️ **location**: Localização (Fase 2)
- ⏸️ **contacts**: Contatos (Fase 3)

## Segurança

- ✅ Verificação de assinatura HMAC-SHA256
- ✅ Credenciais no Secrets Manager
- ✅ Webhook verify token
- ✅ Rate limiting (via API Gateway)
- ✅ Least-privilege IAM role

## Monitoramento

- CloudWatch Logs: `/aws/lambda/whatsapp-webhook`
- CloudWatch Metrics: Invocations, Errors, Duration
- X-Ray: Tracing habilitado
- Alarmes: Error rate > 5%

## Custos Estimados

- Lambda: ~$0.20/mês (1000 mensagens)
- API Gateway: ~$3.50/mês (1000 requests)
- SNS: ~$0.50/mês (1000 publishes)
- Secrets Manager: $0.40/mês (1 secret)

**Total**: ~$4.60/mês para 1000 mensagens

## Links

- [WhatsApp Business API Docs](https://developers.facebook.com/docs/whatsapp/cloud-api/)
- [Webhook Setup Guide](https://developers.facebook.com/docs/whatsapp/cloud-api/guides/set-up-webhooks)

# Testando o WhatsApp Bot

Enquanto aguarda a verificação do Meta Business, você pode testar o bot de várias formas.

## Opção 1: Testar via Scripts (Recomendado)

### PowerShell
```powershell
.\test-whatsapp-bot.ps1
```

### Teste Individual
```powershell
$payload = @{
    object = "whatsapp_business_account"
    entry = @(
        @{
            id = "123456789"
            changes = @(
                @{
                    value = @{
                        messaging_product = "whatsapp"
                        metadata = @{
                            display_phone_number = "5511999999999"
                            phone_number_id = "123456789"
                        }
                        contacts = @(
                            @{
                                profile = @{ name = "Seu Nome" }
                                wa_id = "5511988887777"
                            }
                        )
                        messages = @(
                            @{
                                from = "5511988887777"
                                id = "wamid.test123"
                                timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString()
                                type = "text"
                                text = @{ body = "Oi" }
                            }
                        )
                    }
                    field = "messages"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/webhooks/whatsapp" `
    -Method POST `
    -Body $payload `
    -ContentType "application/json"
```

## Opção 2: Testar via cURL

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/webhooks/whatsapp \
  -H "Content-Type: application/json" \
  -d @events/whatsapp-text-message.json
```

## Opção 3: Número de Teste do Meta (Após Adicionar WhatsApp)

Mesmo sem verificação, o Meta fornece um número de teste:

1. No Meta Business Portal, vá em **WhatsApp > API Setup**
2. Procure por **"Send and receive messages"**
3. Você verá um botão **"Send test message"**
4. Configure o webhook:
   - URL: `https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/webhooks/whatsapp`
   - Verify Token: `n-agent-webhook-verify-2024`
5. Clique em **"Verify and save"**
6. Use o número fornecido para testar (geralmente válido por 72h)

## Verificar Logs

```powershell
# Ver logs em tempo real
aws logs tail /aws/lambda/n-agent-whatsapp-bot-prod --follow

# Ver últimos logs
aws logs tail /aws/lambda/n-agent-whatsapp-bot-prod --since 10m
```

## Verificar DynamoDB

```powershell
# Listar mensagens salvas
aws dynamodb scan --table-name n-agent-core-prod --filter-expression "begins_with(SK, :prefix)" --expression-attribute-values '{":prefix":{"S":"MSG#"}}' --limit 10
```

## Mensagens de Teste

### Saudação
- "Oi"
- "Olá"
- "Bom dia"

### Menu
- "menu"
- "início"
- "ajuda"

### Viagem
- "Quero fazer uma viagem"
- "Planejar viagem para Paris"
- "viagem"

### Interativo
Após receber botões/listas, o payload será diferente:
```json
{
  "type": "interactive",
  "interactive": {
    "type": "button_reply",
    "button_reply": {
      "id": "new_trip",
      "title": "✈️ Nova Viagem"
    }
  }
}
```

## Limitações do Teste

⚠️ **Importante**: Durante os testes sem o Meta configurado:
- ✅ O webhook **recebe** as mensagens corretamente
- ✅ A lógica do bot **processa** as mensagens
- ✅ As mensagens são **salvas** no DynamoDB
- ❌ O bot **NÃO CONSEGUE enviar** respostas reais (precisa do Access Token do Meta)

Para ver as respostas que **seriam** enviadas, verifique os logs:
```
logger.info('Text message sent', { to: options.to, messageId });
```

## Próximos Passos

1. ✅ Testar a lógica do bot localmente
2. ⏳ Aguardar verificação do Meta Business (3-7 dias úteis)
3. 🔑 Obter Access Token permanente
4. 📱 Testar com número de telefone real
5. 🚀 Começar a usar em produção

## Solução Temporária: Webhook Reverso

Se quiser testar **enviando** mensagens antes da verificação:

```typescript
// Adicionar ao bot-handler.ts (apenas para dev)
if (process.env.ENVIRONMENT === 'dev') {
  logger.info('DEV MODE: Mensagem que seria enviada', {
    to: message.from,
    response: responseText
  });
  
  // Simular resposta bem-sucedida
  return 'dev-message-id-' + Date.now();
}
```

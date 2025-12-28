# Fase 1 - Fundação (Semanas 1-4)

## Semana 1: Contas e Acessos

### Tarefas Manuais
- [ ] Criar conta AWS (Organization)
- [ ] Criar conta Google Cloud (para Gemini + Maps)
- [ ] Criar conta Meta Business (WhatsApp Business API)
- [ ] Criar organização GitHub + repositório monorepo
- [ ] Solicitar aprovação WhatsApp Business (pode demorar 1-2 semanas)
- [ ] Criar conta Stripe/gateway de pagamento

### Tarefas Técnicas ✅
- [x] Setup inicial do monorepo (Turborepo + pnpm)
- [x] Configurar ESLint, Prettier, TypeScript
- [x] Criar estrutura de pastas conforme proposta técnica
- [x] Instalação de dependências
- [x] Build de todos os pacotes funcionando

## Semana 2: IaC Base

### Tarefas
- [ ] Setup Terraform/CDK na pasta `/infra`
- [ ] Criar módulo: VPC (se necessário)
- [ ] Criar módulo: DynamoDB (tabelas NAgentCore e ChatHistory)
- [ ] Criar módulo: S3 (buckets para docs e assets)
- [ ] Criar módulo: API Gateway
- [ ] Pipeline CI/CD básico (GitHub Actions)

### Entregável
Deploy de "Hello World" Lambda via pipeline

## Semana 3: Autenticação

### Tarefas
- [ ] Configurar Amazon Cognito User Pool
- [ ] Implementar fluxos: signup, login, forgot password
- [ ] Configurar OAuth (Google/Microsoft)
- [ ] Criar Lambda de validação de token
- [ ] Criar middleware de auth para API Gateway

### Entregável
Endpoint `/auth/login` funcionando

## Semana 4: WhatsApp Webhook

### Tarefas
- [x] Configurar webhook no Meta Business (endpoint: /webhooks/whatsapp)
- [x] Criar Lambda `whatsapp-ingestion` para receber mensagens
- [x] Normalizar payload e persistir no DynamoDB
- [x] Criar Lambda para enviar mensagens de resposta
- [x] Testar fluxo: usuário envia "Oi" → bot responde "Olá!"

### Entregável
Bot WhatsApp respondendo mensagens básicas

### Arquivos Implementados
- `services/whatsapp-bot/src/types.ts` - Tipos do WhatsApp Cloud API
- `services/whatsapp-bot/src/normalizer.ts` - Normalização de payloads
- `services/whatsapp-bot/src/client.ts` - Cliente para envio de mensagens
- `services/whatsapp-bot/src/repository.ts` - Persistência no DynamoDB
- `services/whatsapp-bot/src/bot-handler.ts` - Lógica de respostas
- `services/whatsapp-bot/src/webhook.ts` - Handler principal

### Configuração Meta Business (Manual)
1. Acessar https://developers.facebook.com
2. Criar ou selecionar App do tipo Business
3. Adicionar produto "WhatsApp"
4. Configurar Webhook URL: `https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/webhooks/whatsapp`
5. Verify Token: (definido no GitHub Secrets)
6. Assinar campos: messages, messaging_postbacks
7. Gerar Access Token permanente e adicionar como GitHub Secret

---

## Checklist de Conclusão Fase 1

- [x] Monorepo configurado e rodando localmente
- [x] Infra AWS criada via IaC (Terraform)
- [x] Auth funcionando (Cognito + OAuth Google/Facebook/Microsoft)
- [x] WhatsApp webhook recebendo e respondendo
- [x] Pipeline CI/CD deployando automaticamente

## Endpoints Implementados

### API Gateway: j4f1m6rrak.execute-api.us-east-1.amazonaws.com

| Rota | Método | Lambda | Autenticação |
|------|--------|--------|--------------|
| /health | GET | trip-planner | Nenhuma |
| /webhooks/whatsapp | GET/POST | whatsapp-bot | Nenhuma |
| /auth/signup | POST | auth | Nenhuma |
| /auth/login | POST | auth | Nenhuma |
| /auth/confirm | POST | auth | Nenhuma |
| /auth/refresh | POST | auth | Nenhuma |
| /auth/forgot-password | POST | auth | Nenhuma |
| /auth/reset-password | POST | auth | Nenhuma |
| /auth/resend-code | POST | auth | Nenhuma |
| /api/v1/trips/* | ANY | trip-planner | JWT (Cognito) |

## Recursos AWS Criados

- **Cognito User Pool**: us-east-1_titTvA0Nz
- **API Gateway**: j4f1m6rrak
- **DynamoDB**: n-agent-core-prod, n-agent-chat-prod
- **S3**: n-agent-documents-prod, n-agent-assets-prod, n-agent-web-prod
- **Lambda**: auth, authorizer, whatsapp-bot, trip-planner, integrations
- **SES**: noreply@n-agent.com (sandbox)

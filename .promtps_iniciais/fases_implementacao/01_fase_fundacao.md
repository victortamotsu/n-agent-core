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
- [ ] Configurar webhook no Meta Business
- [ ] Criar Lambda `whatsapp-ingestion` para receber mensagens
- [ ] Normalizar payload e persistir no DynamoDB
- [ ] Criar Lambda para enviar mensagens de resposta
- [ ] Testar fluxo: usuário envia "Oi" → bot responde "Olá!"

### Entregável
Bot WhatsApp respondendo mensagens básicas

---

## Checklist de Conclusão Fase 1

- [ ] Monorepo configurado e rodando localmente
- [ ] Infra AWS criada via IaC
- [ ] Auth funcionando (login/logout)
- [ ] WhatsApp webhook recebendo e respondendo
- [ ] Pipeline CI/CD deployando automaticamente

# Pendências para Continuação do Projeto

## 🚨 Bloqueadores Críticos

### 1. Ativação Meta Business / WhatsApp Business API

**Status**: ⏳ Aguardando Aprovação (3-7 dias úteis)

**Contexto**:
- Conta Meta Business criada mas pendente de verificação
- WhatsApp Business API não pode ser testado com números reais até aprovação
- Webhook implementado e funcional, mas usando tokens temporários

**Ações Necessárias**:
1. Aguardar email de aprovação da Meta
2. Completar verificação de negócio se solicitado
3. Após aprovação:
   - Acessar [Meta for Developers](https://developers.facebook.com)
   - Adicionar produto "WhatsApp" ao app
   - Gerar **Access Token permanente** (não expira)
   - Obter **Phone Number ID** real
   - Atualizar GitHub Secrets:
     ```bash
     gh secret set WHATSAPP_ACCESS_TOKEN --body "EAAxxxxxxxxxx"
     gh secret set WHATSAPP_PHONE_NUMBER_ID --body "1234567890"
     ```
   - Configurar Webhook:
     - URL: `https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/webhooks/whatsapp`
     - Verify Token: `n-agent-webhook-verify-2024`
     - Campos: `messages`, `messaging_postbacks`
   - Enviar mensagem teste para número do WhatsApp Business

**Impacto**: 
- ❌ Não é possível testar envio real de mensagens
- ❌ Não é possível testar interactive messages (botões, listas)
- ❌ Não é possível validar fluxo completo end-to-end
- ✅ Webhook recebe mensagens e processa (verificado com simulação)

**Workaround Atual**:
- Tokens temporários configurados: `temp_token_waiting_meta_verification`
- Webhook testado com eventos simulados (3/3 testes passaram)
- Estrutura completa implementada e pronta para uso

---

## ⚠️ Pendências de Configuração

### 2. Amazon SES em Produção

**Status**: 🟡 Sandbox Mode

**Contexto**:
- SES configurado mas em sandbox (apenas emails verificados)
- Email `noreply@n-agent.com` configurado

**Ações Necessárias**:
1. Solicitar saída do sandbox no console AWS SES
2. Justificar uso (envio de confirmações de viagem, notificações)
3. Configurar DNS (SPF, DKIM, DMARC) para domínio próprio
4. Validar domínio `n-agent.com` (se tiver domínio próprio)

**Impacto**:
- ❌ Não é possível enviar emails para usuários reais em produção
- ✅ Funcional para testes com emails verificados

---

### 3. OAuth Providers (Google, Facebook, Microsoft)

**Status**: 🟡 Parcialmente Configurado

**Contexto**:
- Cognito configurado com suporte a OAuth
- Secrets configurados no GitHub (IDs e Secrets)
- Não testado end-to-end

**Ações Necessárias**:
1. **Google OAuth**:
   - Validar redirect URIs no Google Cloud Console
   - Testar fluxo de login
   
2. **Facebook OAuth**:
   - Aguardar aprovação Meta Business (mesmo bloqueio do WhatsApp)
   - Configurar App Review se necessário
   
3. **Microsoft OAuth**:
   - Validar redirect URIs no Azure AD
   - Testar fluxo de login

**Impacto**:
- ⚠️ Usuários só podem fazer signup/login com email/senha
- ✅ Auth básico funcional

---

### 4. Google Cloud APIs (Gemini + Maps)

**Status**: ❓ Não Verificado

**Contexto**:
- Conta Google Cloud mencionada na Semana 1 mas não configurada
- Necessário para:
  - Gemini AI (geração de roteiros)
  - Google Maps API (geocoding, lugares)

**Ações Necessárias**:
1. Criar projeto no Google Cloud Console
2. Habilitar APIs:
   - Gemini API (generative-ai)
   - Maps JavaScript API
   - Places API
   - Geocoding API
3. Gerar API Key e configurar restrições
4. Adicionar ao GitHub Secrets:
   ```bash
   gh secret set GOOGLE_CLOUD_API_KEY --body "AIzaxxxxxxxxxx"
   gh secret set GEMINI_API_KEY --body "AIzaxxxxxxxxxx"
   ```

**Impacto**:
- ❌ Trip Planner não pode gerar roteiros inteligentes
- ❌ Sem sugestões de lugares baseadas em IA
- ⚠️ Funcionalidade core do produto bloqueada

---

### 5. Stripe / Payment Gateway

**Status**: ❌ Não Iniciado

**Contexto**:
- Mencionado na Semana 1 mas não implementado
- Necessário para monetização

**Ações Necessárias**:
1. Criar conta Stripe
2. Configurar webhooks para eventos de pagamento
3. Implementar Lambda de processamento de pagamentos
4. Integrar com DynamoDB (associar pagamento a trip)

**Impacto**:
- ⚠️ Não crítico para MVP/Fase 1
- 📅 Planejado para fases futuras

---

## 📋 Checklist de Desbloqueio

### Para Começar Fase 2 (Mínimo Necessário):

- [ ] ✅ Meta Business aprovado e WhatsApp configurado
- [ ] ✅ Google Cloud APIs configuradas (Gemini + Maps)
- [ ] 🟡 SES em produção (ou usar provedor alternativo tipo SendGrid)
- [ ] 🟡 OAuth testado (pelo menos 1 provider)

### Para Lançamento Beta (Recomendado):

- [ ] Todos os itens acima
- [ ] WhatsApp Business verificado (badge verde)
- [ ] Domínio próprio configurado
- [ ] SSL/TLS configurado
- [ ] Monitoring/alertas configurados (CloudWatch)

---

## 📊 Estimativa de Tempo

| Item | Tempo Estimado | Controle |
|------|----------------|----------|
| Aprovação Meta Business | 3-7 dias | Meta |
| Google Cloud Setup | 2-4 horas | Você |
| SES Produção | 1-2 dias | AWS |
| OAuth Testing | 2-3 horas | Você |
| **Total** | **4-8 dias** | - |

---

## 🔗 Links Úteis

- [Meta Business Manager](https://business.facebook.com)
- [Meta for Developers](https://developers.facebook.com)
- [Google Cloud Console](https://console.cloud.google.com)
- [AWS SES Console](https://console.aws.amazon.com/ses)
- [Cognito Console](https://console.aws.amazon.com/cognito)
- [Stripe Dashboard](https://dashboard.stripe.com)

---

**Última Atualização**: 28/12/2024  
**Próxima Revisão**: Após aprovação Meta Business

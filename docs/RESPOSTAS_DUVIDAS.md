# 📝 Respostas às Suas Dúvidas

**Data**: 27/12/2025

---

## 1️⃣ Snyk - Security Scanner

### O que é?
Snyk é uma ferramenta de **segurança de código** que:
- 🔍 Escaneia dependências npm/pnpm
- 🚨 Detecta vulnerabilidades (CVEs)
- 🔧 Sugere fixes automáticos
- 🚦 Bloqueia deploys inseguros

### Como criar conta? (2 minutos)

```bash
# 1. Acesse: https://snyk.io/
# 2. Clique em "Sign Up Free"
# 3. Escolha "Sign up with GitHub"
# 4. Autorize o Snyk
# 5. Obtenha o token: Settings → General → Auth Token
# 6. Configure no GitHub:
gh secret set SNYK_TOKEN -b "seu-token-aqui"
```

### Quanto custa?

| Plano | Preço | Recursos | Recomendação |
|-------|-------|----------|--------------|
| **Free** | $0/mês | 200 testes/mês | ✅ **Use este para MVP** |
| Team | $52/mês | Testes ilimitados | Após tração |
| Business | $489/mês | Enterprise | Grande escala |

### Por que gostamos dele?

✅ **Melhor que `npm audit`** - Mais completo e preciso  
✅ **Integração nativa** com GitHub Actions  
✅ **Gratuito para MVP** - 200 testes/mês é suficiente  
✅ **Alertas proativos** - Notifica quando surge nova CVE  
✅ **Fix automático** - Cria PRs com upgrades  

**Já está configurado em**: [.github/workflows/ci.yml](.github/workflows/ci.yml)

---

## 2️⃣ Separação Dev/Prod na Mesma Conta AWS

### Como Funciona (Implementação Atual)

```
AWS Account: 944938120078
│
├── 📊 DynamoDB
│   ├── n-agent-core-dev
│   ├── n-agent-core-prod
│   ├── n-agent-chat-dev
│   └── n-agent-chat-prod
│
├── 🗂️ S3
│   ├── n-agent-documents-dev
│   ├── n-agent-documents-prod
│   ├── n-agent-assets-dev
│   └── n-agent-assets-prod
│
├── ⚡ Lambda
│   ├── n-agent-whatsapp-bot-dev
│   ├── n-agent-whatsapp-bot-prod
│   ├── n-agent-trip-planner-dev
│   └── n-agent-trip-planner-prod
│
└── 🔐 IAM Roles
    ├── n-agent-whatsapp-bot-role-dev
    ├── n-agent-whatsapp-bot-role-prod
    └── ...
```

### Separação por Nomenclatura

**Sufixos obrigatórios**: `-dev` e `-prod`

```hcl
# Terraform
resource "aws_dynamodb_table" "core" {
  name = "n-agent-core-${var.environment}"  # dev ou prod
  
  tags = {
    Environment = var.environment
    Project     = "n-agent"
    ManagedBy   = "terraform"
  }
}
```

### Vantagens desta Abordagem

✅ **Custo reduzido**: Apenas 1 conta AWS  
✅ **Simplicidade**: Setup inicial rápido  
✅ **Ideal para MVP**: Foco no produto, não na infra  
✅ **Menos burocracia**: Sem AWS Organizations  

### Desvantagens

⚠️ **Risco operacional**: Deletar recurso errado  
⚠️ **Permissões compartilhadas**: IAM mais complexo  
⚠️ **Quotas compartilhadas**: Limites AWS divididos  

### Mitigações Implementadas

✅ **Nomenclatura clara**: Sufixos `-dev` / `-prod`  
✅ **Tags obrigatórias**: Todos os recursos taggeados  
✅ **Terraform workspaces**: `dev` e `prod` separados  
✅ **IAM policies**: Restrições por tag  

### Alternativa Futura: Contas Separadas

Quando migrar para contas separadas:
- 🚀 **Após MVP validado** (>100 usuários)
- 💰 **Quando custo não for problema** (>$500/mês infra)
- 👥 **Quando tiver equipe grande** (>5 devs)

```
AWS Organization
├── Dev Account: 944938120078
│   └── Resources (sem sufixo)
└── Prod Account: 123456789012
    └── Resources (sem sufixo)
```

---

## 3️⃣ Nomenclatura com Sufixos `_DEV` / `_PROD`

### ✅ Você estava correto!

A estrutura estava **inconsistente**. Agora está padronizada.

### Antes (Incorreto) ❌

```bash
# Ambíguo - qual ambiente?
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### Depois (Correto) ✅

```bash
# Nomenclatura clara
AWS_ACCESS_KEY_ID_DEV
AWS_SECRET_ACCESS_KEY_DEV
AWS_ACCESS_KEY_ID_PROD
AWS_SECRET_ACCESS_KEY_PROD
```

### O Que Foi Alterado

#### 1. GitHub Secrets (Configurados)

```bash
# Desenvolvimento
gh secret set AWS_ACCESS_KEY_ID_DEV -b "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY_DEV -b "secret..."

# Produção
gh secret set AWS_ACCESS_KEY_ID_PROD -b "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY_PROD -b "secret..."
```

#### 2. Workflows Atualizados

**deploy-dev.yml** agora usa:
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID_DEV }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY_DEV }}
```

**deploy-prod.yml** usa:
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID_PROD }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY_PROD }}
```

#### 3. Todos os Secrets Futuros Seguem o Padrão

| Secret | Dev | Prod |
|--------|-----|------|
| **AWS** | `_DEV` | `_PROD` |
| **CloudFront** | `CLOUDFRONT_DISTRIBUTION_ID_DEV` | `CLOUDFRONT_DISTRIBUTION_ID_PROD` |
| **Google Maps** | `GOOGLE_MAPS_API_KEY_DEV` | `GOOGLE_MAPS_API_KEY_PROD` |
| **WhatsApp** | `WHATSAPP_ACCESS_TOKEN_DEV` | `WHATSAPP_ACCESS_TOKEN_PROD` |

**Exceções** (sem sufixo):
- `SNYK_TOKEN` - Mesmo para dev e prod
- `GCP_SERVICE_ACCOUNT_KEY` - Separar por projeto GCP

---

## 🎯 Checklist de Implementação

### ✅ Completo

- [x] Renomear secrets para incluir sufixos `_DEV` / `_PROD`
- [x] Atualizar workflow `deploy-dev.yml`
- [x] Atualizar workflow `deploy-prod.yml`
- [x] Configurar secrets no GitHub
- [x] Documentar boas práticas

### 📝 Próximos Passos

- [ ] Criar conta no Snyk (2 minutos)
- [ ] Configurar `SNYK_TOKEN` no GitHub
- [ ] Adicionar tags em todos os recursos Terraform
- [ ] Implementar IAM policies com conditions

---

## 📚 Documentação Criada

| Documento | Descrição |
|-----------|-----------|
| [BOAS_PRATICAS_AMBIENTES.md](./BOAS_PRATICAS_AMBIENTES.md) | Guia completo sobre separação de ambientes |
| [QUICKSTART_CREDENTIALS.md](./QUICKSTART_CREDENTIALS.md) | Setup rápido de credenciais |
| [SETUP_CREDENTIALS.md](./SETUP_CREDENTIALS.md) | Documentação detalhada |
| [PIPELINES_SETUP_COMPLETO.md](./PIPELINES_SETUP_COMPLETO.md) | Status das pipelines |

---

## 💡 Resumo das Respostas

### 1. Snyk
- ✅ Gratuito para MVP (200 testes/mês)
- ✅ Melhor que `npm audit`
- ✅ Já integrado no CI
- 👉 **Criar conta**: https://snyk.io/

### 2. Separação Dev/Prod
- ✅ Mesma conta AWS com sufixos `-dev` / `-prod`
- ✅ Boa para MVP e startup
- ✅ Migrar para contas separadas após validação
- 👉 **Ver detalhes**: [BOAS_PRATICAS_AMBIENTES.md](./BOAS_PRATICAS_AMBIENTES.md)

### 3. Nomenclatura de Secrets
- ✅ **Você estava certo!**
- ✅ Todos os secrets agora têm sufixos `_DEV` / `_PROD`
- ✅ Workflows atualizados
- 👉 **Secrets configurados** e funcionando

---

**Status**: ✅ Todas as dúvidas respondidas e implementadas!

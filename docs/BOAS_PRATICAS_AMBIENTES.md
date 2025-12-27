# 🏗️ Boas Práticas de Separação de Ambientes

**Data**: 27/12/2025  
**Versão**: 1.1

---

## 📋 Índice

1. [Desenvolvimento de Lambdas](#desenvolvimento-de-lambdas)
2. [Nomenclatura Padronizada](#nomenclatura-padronizada)
3. [GitHub Secrets](#github-secrets)
4. [Recursos AWS](#recursos-aws)
5. [Snyk - Security Scanner](#snyk-security-scanner)
6. [Estratégias de Separação](#estratégias-de-separação)

---

## 🚀 Desenvolvimento de Lambdas

### ⚡ Regra de Ouro: **SEMPRE teste localmente ANTES de fazer deploy**

Evite executar pipelines desnecessariamente. O fluxo correto é:

#### 📌 Workflow Recomendado

```mermaid
graph LR
    A[Editar Código] --> B[Testar Localmente]
    B --> C{Funcionou?}
    C -->|Não| A
    C -->|Sim| D[Quick Deploy Dev]
    D --> E{OK na AWS?}
    E -->|Não| F[Ver Logs]
    F --> A
    E -->|Sim| G[Commit + Push]
    G --> H[CI/CD Pipeline]
```

### 🎯 Métodos de Teste (em ordem de velocidade)

#### 1. **Debug Local com AWS Toolkit** (MAIS RÁPIDO - 0 custos)

```powershell
# 1. Bundle as Lambdas
node scripts/bundle-lambdas.js

# 2. Pressione F5 no VSCode
# 3. Coloque breakpoints
# 4. Veja variáveis em tempo real
```

**Vantagens:**
- ⚡ Instantâneo (sem deploy)
- 🐛 Debug completo com breakpoints
- 💰 Zero custos AWS
- 🔄 Iteração ultra-rápida

**Quando usar:** Desenvolvimento intenso, debug de lógica complexa

📖 **Guia Completo:** [docs/AWS_TOOLKIT_GUIA.md](./AWS_TOOLKIT_GUIA.md)

---

#### 2. **Quick Deploy para Dev** (RÁPIDO - ~10s)

```powershell
# Deploy direto sem CI/CD
.\scripts\quick-deploy.ps1 -Service trip-planner -Environment dev

# Teste na AWS real
curl https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/health

# Ver logs em tempo real
pnpm run logs:trips
```

**Vantagens:**
- 🎯 Testa no ambiente real AWS
- ⚡ Deploy em ~10 segundos
- 📊 Logs reais do CloudWatch
- 🔄 Pula CI/CD para iteração rápida

**Quando usar:** Validar comportamento na AWS, testar integrações reais

---

#### 3. **CI/CD Pipeline** (LENTO - ~2-3min)

```powershell
git add .
git commit -m "feat: nova funcionalidade"
git push origin main
```

**Vantagens:**
- ✅ Testes automatizados
- 🔒 Security scan (Snyk)
- 📦 Deploy automático
- 🌍 Deploy para prod

**Quando usar:** Código validado e pronto para produção

---

### 🚫 Anti-Padrões (O que NÃO fazer)

❌ **Commitar código sem testar localmente**
```powershell
# MAU - dispara pipeline sem garantia que funciona
git commit -m "tentativa 1"
git push
# ... aguarda 2min, pipeline falha
git commit -m "tentativa 2"
git push
# ... aguarda 2min, pipeline falha novamente
```

✅ **Testar localmente primeiro**
```powershell
# BOM - valida antes do deploy
node scripts/bundle-lambdas.js
# F5 para debugar localmente
# Código funcionando? Agora sim:
.\scripts\quick-deploy.ps1 -Service trip-planner -Environment dev
# OK na AWS? Commit!
git commit -m "feat: funcionalidade validada"
git push
```

---

### 📊 Comparação de Métodos

| Método | Tempo | Custo AWS | Debug | Ambiente Real |
|--------|-------|-----------|-------|---------------|
| Debug Local (F5) | 0s | $0 | ✅ Completo | ❌ Simulado |
| Quick Deploy Dev | ~10s | $0.001 | 📝 Logs | ✅ Real |
| CI/CD Pipeline | ~2-3min | $0.01 | 📝 Logs | ✅ Real |

---

### 💡 Dicas de Produtividade

1. **Use console.log() generosamente durante desenvolvimento**
   ```typescript
   console.log('Debug:', { method, path, body });
   // Visível em: pnpm run logs:trips
   ```

2. **Mantenha Docker rodando** para debug local funcionar instantaneamente

3. **Crie eventos de teste personalizados** em `events/*.json` para seus casos de uso

4. **Use environment variables** para diferenciar comportamento local vs AWS
   ```typescript
   if (process.env.ENVIRONMENT === 'local') {
     // Mock de DynamoDB
   }
   ```

---

## 🏷️ Nomenclatura Padronizada

### Princípio: **Sempre use sufixos `_DEV` e `_PROD`**

#### ✅ Correto
```bash
# GitHub Secrets
AWS_ACCESS_KEY_ID_DEV
AWS_SECRET_ACCESS_KEY_DEV
AWS_ACCESS_KEY_ID_PROD
AWS_SECRET_ACCESS_KEY_PROD
CLOUDFRONT_DISTRIBUTION_ID_DEV
CLOUDFRONT_DISTRIBUTION_ID_PROD

# Recursos AWS
n-agent-core-dev            (DynamoDB)
n-agent-core-prod           (DynamoDB)
n-agent-documents-dev       (S3)
n-agent-documents-prod      (S3)
n-agent-whatsapp-bot-dev    (Lambda)
n-agent-whatsapp-bot-prod   (Lambda)
```

#### ❌ Incorreto
```bash
# Ambíguo - qual ambiente?
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
n-agent-documents
n-agent-whatsapp-bot
```

---

## 🔐 GitHub Secrets

### Estrutura Recomendada

```yaml
# Desenvolvimento
AWS_ACCESS_KEY_ID_DEV: "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY_DEV: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
CLOUDFRONT_DISTRIBUTION_ID_DEV: "E1234567890ABC"
SNYK_TOKEN: "1234-5678-9abc-def0"  # Mesmo token para dev e prod

# Produção
AWS_ACCESS_KEY_ID_PROD: "AKIA9876543210EXAMPLE"
AWS_SECRET_ACCESS_KEY_PROD: "xyz123SecretKeyForProdEnvironment456789"
CLOUDFRONT_DISTRIBUTION_ID_PROD: "E0987654321XYZ"

# Integrações (Week 8-9)
GCP_SERVICE_ACCOUNT_KEY: "{...json...}"  # Mesmo para dev/prod (separar por projeto GCP)
GOOGLE_MAPS_API_KEY_DEV: "AIza..."
GOOGLE_MAPS_API_KEY_PROD: "AIza..."
WHATSAPP_VERIFY_TOKEN: "random-string-123"
WHATSAPP_ACCESS_TOKEN_DEV: "EAABs..."
WHATSAPP_ACCESS_TOKEN_PROD: "EAABs..."
```

### Como Configurar

```bash
# DEV
gh secret set AWS_ACCESS_KEY_ID_DEV -b "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY_DEV -b "secret..."

# PROD
gh secret set AWS_ACCESS_KEY_ID_PROD -b "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY_PROD -b "secret..."

# Verificar
gh secret list
```

---

## ☁️ Recursos AWS

### Nomenclatura de Recursos

| Recurso | Desenvolvimento | Produção |
|---------|----------------|----------|
| **DynamoDB Tables** | | |
| Trips & Users | `n-agent-core-dev` | `n-agent-core-prod` |
| Chat History | `n-agent-chat-dev` | `n-agent-chat-prod` |
| **S3 Buckets** | | |
| Documentos | `n-agent-documents-dev` | `n-agent-documents-prod` |
| Assets/Media | `n-agent-assets-dev` | `n-agent-assets-prod` |
| Frontend Web | `n-agent-web-dev` | `n-agent-web-prod` |
| **Lambda Functions** | | |
| WhatsApp Bot | `n-agent-whatsapp-bot-dev` | `n-agent-whatsapp-bot-prod` |
| Trip Planner | `n-agent-trip-planner-dev` | `n-agent-trip-planner-prod` |
| Integrations | `n-agent-integrations-dev` | `n-agent-integrations-prod` |
| **IAM Roles** | | |
| WhatsApp Bot | `n-agent-whatsapp-bot-role-dev` | `n-agent-whatsapp-bot-role-prod` |
| Trip Planner | `n-agent-trip-planner-role-dev` | `n-agent-trip-planner-role-prod` |
| **API Gateway** | | |
| REST API | `n-agent-api-dev` | `n-agent-api-prod` |
| **CloudFront** | | |
| CDN | Distribution ID separado | Distribution ID separado |

### Tags Obrigatórias

Todos os recursos devem ter:

```hcl
tags = {
  Project     = "n-agent"
  Environment = var.environment  # "dev" ou "prod"
  ManagedBy   = "terraform"
  CostCenter  = "travel-ai"
}
```

---

## 🛡️ Snyk - Security Scanner

### O que é o Snyk?

Snyk é uma **ferramenta de segurança** que:
- 🔍 Escaneia dependências (npm, pnpm, yarn, pip, etc.)
- 🚨 Detecta vulnerabilidades conhecidas (CVEs)
- 🔧 Sugere correções automáticas (pull requests)
- 🚦 Bloqueia builds com vulnerabilidades críticas
- 📊 Dashboard de segurança do projeto

### Por que usar Snyk?

| Vantagem | Descrição |
|----------|-----------|
| **Melhor que `npm audit`** | Mais completo, atualizado e preciso |
| **Integração nativa** | GitHub Actions, GitLab CI, CircleCI |
| **Gratuito para MVP** | 200 testes/mês (suficiente para começar) |
| **Alertas proativos** | Notifica quando nova CVE é descoberta |
| **Fix automático** | Cria PRs com upgrades de dependências |

### Como Criar Conta (2 minutos)

1. **Acesse**: https://snyk.io/
2. **Sign Up Free**: Escolha "Sign up with GitHub"
3. **Autorize**: Permitir acesso aos repositórios
4. **Obtenha o Token**:
   - Settings → General → Auth Token
   - Copiar o token (formato: `1234-5678-9abc-def0`)

5. **Configure no GitHub**:
   ```bash
   gh secret set SNYK_TOKEN -b "seu-token-aqui"
   ```

### Custos

| Plano | Preço | Recursos | Recomendação |
|-------|-------|----------|--------------|
| **Free** | $0/mês | 200 testes/mês | ✅ **MVP** |
| **Team** | $52/mês | Testes ilimitados | Após tração |
| **Business** | $489/mês | RBAC, SSO, SLA | Enterprise |

### Integração no CI/CD

Já está configurado em [.github/workflows/ci.yml](.github/workflows/ci.yml):

```yaml
security-scan:
  name: Security Scan
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run Snyk scan
      uses: snyk/actions/node@master
      continue-on-error: true  # Não bloqueia deploy inicialmente
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Próximos Passos

1. ✅ Criar conta no Snyk
2. ✅ Obter token de autenticação
3. ✅ Configurar `SNYK_TOKEN` no GitHub
4. ✅ Remover `continue-on-error: true` após validação inicial

---

## 🏗️ Estratégias de Separação de Ambientes

### Opção 1: Mesma Conta AWS (Atual) ✅

**Como funciona:**
```
AWS Account: 944938120078
├── Resources -dev
│   ├── DynamoDB tables
│   ├── S3 buckets
│   ├── Lambda functions
│   └── IAM roles
└── Resources -prod
    ├── DynamoDB tables
    ├── S3 buckets
    ├── Lambda functions
    └── IAM roles
```

**Vantagens:**
- ✅ **Custo reduzido**: 1 conta = menos overhead
- ✅ **Simplicidade**: Setup inicial rápido
- ✅ **Bom para MVP**: Foco no produto, não na infra

**Desvantagens:**
- ⚠️ **Risco operacional**: Deletar recurso errado
- ⚠️ **Permissões compartilhadas**: IAM policies mais complexas
- ⚠️ **Quotas compartilhadas**: Limites AWS divididos

**Mitigações:**
- ✅ Nomenclatura clara com sufixos `-dev` / `-prod`
- ✅ Tags obrigatórias em todos os recursos
- ✅ IAM policies com conditions por environment
- ✅ Terraform workspaces separados

### Opção 2: Contas AWS Separadas (Futuro)

**Como funciona:**
```
AWS Organization
├── Dev Account: 944938120078
│   └── Resources (sem sufixo)
└── Prod Account: 123456789012
    └── Resources (sem sufixo)
```

**Vantagens:**
- ✅ **Isolamento total**: Zero risco de acidente cross-environment
- ✅ **Permissões simplificadas**: Cada conta tem seu IAM
- ✅ **Quotas independentes**: Limites AWS não compartilhados
- ✅ **Billing separado**: Visibilidade de custos por ambiente

**Desvantagens:**
- ⚠️ **Custo maior**: Overhead de 2 contas
- ⚠️ **Complexidade**: Precisa AWS Organizations
- ⚠️ **Setup inicial**: Mais tempo para configurar

**Quando migrar?**
- 🚀 **Após MVP validado**: Quando tiver tração
- 💰 **Quando custo não for problema**: >$500/mês de infra
- 👥 **Quando tiver equipe grande**: >5 desenvolvedores

### Comparação

| Critério | Mesma Conta | Contas Separadas |
|----------|-------------|------------------|
| **Setup inicial** | ⭐⭐⭐⭐⭐ Rápido | ⭐⭐⭐ Médio |
| **Custo** | ⭐⭐⭐⭐⭐ Baixo | ⭐⭐⭐ Médio |
| **Segurança** | ⭐⭐⭐ Boa | ⭐⭐⭐⭐⭐ Excelente |
| **Simplicidade** | ⭐⭐⭐⭐ Simples | ⭐⭐⭐ Médio |
| **Escalabilidade** | ⭐⭐⭐ Boa | ⭐⭐⭐⭐⭐ Excelente |

### Recomendação

```
┌─────────────────────────────────────────────┐
│  Fase MVP (Agora): Mesma Conta AWS          │
│  ✅ Sufixos -dev / -prod                    │
│  ✅ Tags obrigatórias                       │
│  ✅ Terraform workspaces                    │
└─────────────────────────────────────────────┘
                    ⬇️
┌─────────────────────────────────────────────┐
│  Pós-MVP (3-6 meses): Migrar para Contas   │
│  ✅ AWS Organizations                       │
│  ✅ Billing consolidado                     │
│  ✅ Isolamento total                        │
└─────────────────────────────────────────────┘
```

---

## 🔒 Segurança e Boas Práticas

### IAM Policies com Conditions

Exemplo de política que restringe acesso por environment:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/n-agent-*-dev",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

### Terraform Workspaces

```bash
# Criar workspaces
cd infra/environments
terraform workspace new dev
terraform workspace new prod

# Usar workspace
terraform workspace select dev
terraform apply

terraform workspace select prod
terraform apply
```

### Resource Tagging Strategy

```hcl
locals {
  common_tags = {
    Project     = "n-agent"
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = "travel-ai"
    Owner       = "victor@n-agent.com"
    Repository  = "github.com/victortamotsu/n-agent-core"
  }
}

resource "aws_dynamodb_table" "core" {
  name = "n-agent-core-${var.environment}"
  
  tags = local.common_tags
}
```

---

## 📚 Recursos Adicionais

- **AWS Organizations**: https://aws.amazon.com/organizations/
- **Terraform Workspaces**: https://developer.hashicorp.com/terraform/language/state/workspaces
- **Snyk Documentation**: https://docs.snyk.io/
- **AWS Tagging Best Practices**: https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html

---

## ✅ Checklist de Implementação

### Imediato (Agora)
- [x] Renomear secrets para incluir sufixos `_DEV` / `_PROD`
- [x] Atualizar workflows GitHub Actions
- [ ] Criar conta no Snyk
- [ ] Configurar `SNYK_TOKEN` no GitHub
- [ ] Validar nomenclatura de todos os recursos AWS

### Semana 2
- [ ] Adicionar tags em todos os recursos Terraform
- [ ] Implementar IAM policies com conditions
- [ ] Configurar Terraform workspaces

### Pós-MVP (3-6 meses)
- [ ] Avaliar migração para contas AWS separadas
- [ ] Implementar AWS Organizations
- [ ] Configurar CloudTrail cross-account
- [ ] Billing consolidado

---

**Documentação atualizada em**: 27/12/2025  
**Próxima revisão**: Após Semana 2 (IaC completo)

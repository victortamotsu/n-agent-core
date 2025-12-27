# 🚀 Quick Start - Configuração de Credenciais

## ⚡ Resumo Executivo

Você configurou AWS CLI localmente. Agora precisamos configurar credenciais para as pipelines do GitHub Actions.

---

## 📋 Checklist Rápido

### AWS (Obrigatório Agora)

- [ ] **Passo 1**: Criar IAM User para GitHub Actions
- [ ] **Passo 2**: Obter Access Keys (ID + Secret)
- [ ] **Passo 3**: Adicionar secrets no GitHub
- [ ] **Passo 4**: Testar pipeline

### GCP (Necessário na Semana 8-9)

- [ ] Service Account criada
- [ ] API Keys do Google Maps obtidas
- [ ] Secrets do GCP configurados no GitHub

---

## 🔐 Como Obter Credenciais AWS

### Opção 1: Via AWS Console (Mais Fácil)

```
1. AWS Console → IAM → Users
2. "Add users" → Nome: github-actions-n-agent
3. "Access key - Programmatic access" ✓
4. Next → Attach policies → Create policy
5. Copiar JSON da política (veja docs/SETUP_CREDENTIALS.md)
6. Finalizar → Copiar Access Key ID e Secret Access Key
```

### Opção 2: Via AWS CLI (Mais Rápido)

```bash
# 1. Criar usuário
aws iam create-user --user-name github-actions-n-agent

# 2. Criar e salvar access key
aws iam create-access-key --user-name github-actions-n-agent > aws-keys.json

# 3. Ver as credenciais
cat aws-keys.json
```

**Resultado esperado:**
```json
{
  "AccessKey": {
    "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "Status": "Active"
  }
}
```

⚠️ **GUARDE ESSAS CREDENCIAIS!** Você vai precisar delas no próximo passo.

---

## 🔑 Como Configurar GitHub Secrets

### Via Web (Recomendado)

```
1. GitHub → Seu repositório → Settings
2. Secrets and variables → Actions
3. "New repository secret"
4. Adicionar cada secret da tabela abaixo
```

### Secrets Obrigatórios (Agora)

| Nome do Secret | Onde Obter | Exemplo |
|----------------|-----------|---------|
| `AWS_ACCESS_KEY_ID` | JSON da etapa anterior | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | JSON da etapa anterior | `wJalrX...` |

### Secrets Opcionais (Adicionar Depois)

| Nome do Secret | Quando Usar | Onde Obter |
|----------------|-------------|-----------|
| `AWS_ACCESS_KEY_ID_PROD` | Deploy em produção | Criar outro IAM user |
| `AWS_SECRET_ACCESS_KEY_PROD` | Deploy em produção | Criar outro IAM user |
| `CLOUDFRONT_DISTRIBUTION_ID_DEV` | Após criar CloudFront | Console CloudFront |
| `GCP_SERVICE_ACCOUNT_KEY` | Semana 8-9 (Maps/Gemini) | GCP Console |
| `GOOGLE_MAPS_API_KEY` | Semana 8-9 | GCP Console |

### Via GitHub CLI (Alternativa)

```bash
# Instalar GitHub CLI: https://cli.github.com

# Login
gh auth login

# Adicionar secret
gh secret set AWS_ACCESS_KEY_ID -b "AKIAIOSFODNN7EXAMPLE"
gh secret set AWS_SECRET_ACCESS_KEY -b "wJalrXUtnFEMI/K7MDENG/..."

# Listar secrets
gh secret list
```

---

## ✅ Testar a Pipeline

### 1. Verificar se os secrets estão configurados

```bash
gh secret list
# Deve mostrar:
# AWS_ACCESS_KEY_ID     Updated 2025-12-27
# AWS_SECRET_ACCESS_KEY Updated 2025-12-27
```

### 2. Fazer um commit de teste

```bash
git checkout -b test-pipeline
git add .
git commit -m "test: trigger GitHub Actions"
git push origin test-pipeline
```

### 3. Verificar execução

```bash
# Via CLI
gh run list

# Ou acessar no navegador:
# https://github.com/YOUR_USERNAME/n-agent-core/actions
```

### 4. Se falhar, verificar logs

```bash
gh run view --log
```

---

## 🔍 Troubleshooting Comum

### ❌ "Error: Access Denied"

**Causa**: IAM user sem permissões adequadas

**Solução**:
```bash
# Verificar políticas anexadas
aws iam list-attached-user-policies --user-name github-actions-n-agent

# Se vazio, anexar política
aws iam attach-user-policy \
  --user-name github-actions-n-agent \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

⚠️ **Nota**: AdministratorAccess é amplo demais. Use apenas para testes iniciais!

### ❌ "Error: InvalidAccessKeyId"

**Causa**: Secret configurado incorretamente

**Solução**:
```bash
# Recriar access key
aws iam create-access-key --user-name github-actions-n-agent

# Atualizar secret no GitHub
gh secret set AWS_ACCESS_KEY_ID -b "NOVA_KEY_AQUI"
```

### ❌ Pipeline não dispara

**Causa**: Branch incorreta ou workflow desabilitado

**Solução**:
- Push deve ser para `develop` (dev) ou `main` (prod)
- Verificar se workflows estão habilitados em Settings → Actions

---

## 📝 Próximos Passos

Após configurar os secrets AWS:

1. ✅ **Agora**: Testar pipeline de CI (lint + build)
2. ⏳ **Semana 2**: Deploy de infraestrutura via Terraform
3. ⏳ **Semana 8**: Adicionar secrets do GCP

---

## 📚 Documentação Completa

Para detalhes completos, políticas IAM personalizadas e configuração GCP:

➡️ **[docs/SETUP_CREDENTIALS.md](./SETUP_CREDENTIALS.md)**

---

## 🆘 Precisa de Ajuda?

### Comandos Úteis

```bash
# Verificar usuário AWS atual
aws sts get-caller-identity

# Listar IAM users
aws iam list-users

# Verificar secrets do GitHub
gh secret list

# Ver logs da última pipeline
gh run view --log
```

### Contatos de Suporte

- AWS Support: https://console.aws.amazon.com/support/
- GitHub Actions: https://docs.github.com/actions
- Documentação do Projeto: [README.md](../README.md)

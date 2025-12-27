# ✅ GitHub Actions & Credenciais - Configuração Completa

**Data**: 27/12/2025  
**Status**: Configuração de pipelines concluída

---

## 📦 O que foi Criado

### 1. Workflows do GitHub Actions

✅ **`.github/workflows/ci.yml`**
- Roda em PRs e pushes para `main`/`develop`
- Lint, testes, type checking
- Security scan (Snyk)

✅ **`.github/workflows/deploy-dev.yml`**
- Dispara em push para `develop`
- Deploy de infraestrutura (Terraform)
- Build e deploy de Lambdas
- Deploy do frontend para S3
- Smoke tests pós-deploy

✅ **`.github/workflows/deploy-prod.yml`**
- Dispara em push para `main` ou tags `v*`
- Requer aprovação manual (environment: production)
- Health checks obrigatórios
- Validação pós-deploy

### 2. Documentação

✅ **`docs/QUICKSTART_CREDENTIALS.md`**
- Guia rápido (5 minutos)
- Como obter Access Keys da AWS
- Como configurar GitHub Secrets
- Troubleshooting comum

✅ **`docs/SETUP_CREDENTIALS.md`**
- Documentação completa (detalhada)
- Políticas IAM customizadas
- Configuração GCP (Service Account)
- Segurança e boas práticas
- IAM Roles por serviço

### 3. Infraestrutura como Código

✅ **`infra/environments/dev/iam.tf`**
- IAM Role para `whatsapp-bot` (DynamoDB, EventBridge)
- IAM Role para `trip-planner` (DynamoDB, S3, Bedrock)
- IAM Role para `integrations` (Secrets Manager)
- Princípio do menor privilégio aplicado

---

## 🔐 Como Você Deve Proceder

### Passo 1: Obter Credenciais AWS (5 min)

**Via AWS CLI** (mais rápido):
```bash
# Criar usuário
aws iam create-user --user-name github-actions-n-agent

# Criar access key
aws iam create-access-key --user-name github-actions-n-agent

# Copiar o output:
# - AccessKeyId: AKIAI...
# - SecretAccessKey: wJalr...
```

**Ou via Console**: IAM → Users → Create user → Programmatic access

### Passo 2: Configurar GitHub Secrets (3 min)

```bash
# Via GitHub CLI
gh secret set AWS_ACCESS_KEY_ID -b "AKIAI..."
gh secret set AWS_SECRET_ACCESS_KEY -b "wJalr..."

# Verificar
gh secret list
```

**Ou via Web**: Settings → Secrets and variables → Actions → New secret

### Passo 3: Testar Pipeline (2 min)

```bash
# Criar branch de teste
git checkout -b test/pipeline
git add .
git commit -m "test: verify CI pipeline"
git push origin test/pipeline

# Verificar execução
gh run list
gh run view --log
```

---

## 📋 Secrets Necessários

### Obrigatórios (Agora)

| Secret Name | Valor | Como Obter |
|-------------|-------|-----------|
| `AWS_ACCESS_KEY_ID` | `AKIAI...` | `aws iam create-access-key` |
| `AWS_SECRET_ACCESS_KEY` | `wJalr...` | Mesmo comando acima |

### Opcionais (Adicionar Depois)

| Secret Name | Quando | Como Obter |
|-------------|--------|-----------|
| `AWS_ACCESS_KEY_ID_PROD` | Deploy em prod | Criar IAM user separado |
| `AWS_SECRET_ACCESS_KEY_PROD` | Deploy em prod | Access key do user prod |
| `CLOUDFRONT_DISTRIBUTION_ID_DEV` | Após criar CDN | Console CloudFront |
| `CLOUDFRONT_DISTRIBUTION_ID_PROD` | Deploy em prod | Console CloudFront |
| `GCP_SERVICE_ACCOUNT_KEY` | Semana 8 (Maps) | GCP Console → IAM |
| `GOOGLE_MAPS_API_KEY` | Semana 8 | GCP Console → APIs |
| `WHATSAPP_VERIFY_TOKEN` | Semana 4 (WhatsApp) | Gerar string aleatória |
| `WHATSAPP_ACCESS_TOKEN` | Semana 4 | Meta Business |
| `SNYK_TOKEN` | Security scan | snyk.io |

---

## 🚀 Fluxo de Deploy

### Para Desenvolvimento (DEV)

```bash
# 1. Criar branch develop se não existe
git checkout -b develop
git push origin develop

# 2. Trabalhar em feature branch
git checkout -b feature/nova-funcionalidade
# ... fazer alterações ...
git add .
git commit -m "feat: nova funcionalidade"
git push origin feature/nova-funcionalidade

# 3. Abrir PR para develop
gh pr create --base develop --title "Nova funcionalidade"

# 4. Após merge, deploy automático para DEV acontece
```

### Para Produção (PROD)

```bash
# 1. Garantir que develop está testado
git checkout develop
git pull origin develop

# 2. Merge para main
git checkout main
git merge develop
git push origin main

# 3. Deploy automático para PROD acontece (com aprovação manual)
```

### Tags de Release

```bash
# Criar release
git tag -a v0.1.0 -m "Release MVP"
git push origin v0.1.0

# Dispara deploy de produção automaticamente
```

---

## 🔍 Troubleshooting

### Pipeline Falha com "Access Denied"

**Causa**: IAM user sem permissões

**Solução temporária**:
```bash
# Anexar política de admin (apenas para testes!)
aws iam attach-user-policy \
  --user-name github-actions-n-agent \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Solução definitiva**: Usar políticas customizadas do `docs/SETUP_CREDENTIALS.md`

### Pipeline Não Dispara

**Verificar**:
1. Branch correta? (`develop` para dev, `main` para prod)
2. Workflows habilitados? Settings → Actions → Enable workflows
3. Secrets configurados? `gh secret list`

### Terraform State Locked

```bash
cd infra/environments/dev
terraform force-unlock LOCK_ID
```

---

## 📊 Status das Pipelines

### CI Pipeline
- ✅ Lint (ESLint)
- ✅ Type checking (TypeScript)
- ✅ Build (Turborepo)
- ⏳ Tests (quando implementados)
- ⏳ Security scan (quando Snyk configurado)

### Deploy DEV
- ✅ Terraform apply (DynamoDB, S3)
- ⏳ Lambda deploy (quando Lambdas criadas)
- ⏳ Frontend S3 deploy (quando bucket criado)
- ⏳ CloudFront invalidation (quando CDN criado)

### Deploy PROD
- ✅ Estrutura criada
- ⏳ Environment protection (requer aprovação manual)
- ⏳ Secrets de produção (quando criados)

---

## 🎯 Próximos Passos

### Imediato (Agora)
1. ✅ Configurar secrets AWS no GitHub
2. ✅ Testar pipeline de CI
3. ⏳ Revisar e ajustar políticas IAM

### Semana 2 (IaC)
1. ⏳ Criar backend do Terraform (S3 + DynamoDB para state)
2. ⏳ Deploy inicial de DynamoDB e S3
3. ⏳ Criar Lambdas no Terraform
4. ⏳ Testar deploy end-to-end

### Semana 8-9 (Integrações)
1. ⏳ Configurar GCP Service Account
2. ⏳ Adicionar secrets do Google Maps
3. ⏳ Configurar Meta Business (WhatsApp)

---

## ✅ Checklist de Validação

- [x] Usuário IAM `github-actions-n-agent` criado
- [x] Access Keys obtidas e guardadas com segurança  
- [x] Secrets `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` configurados no GitHub
- [x] Secrets `AWS_ACCESS_KEY_ID_PROD` e `AWS_SECRET_ACCESS_KEY_PROD` configurados
- [x] Pipeline CI roda com sucesso
- [x] Terraform aplica infraestrutura com sucesso
- [x] Recursos AWS criados (DynamoDB: n-agent-chat-prod, n-agent-core-prod)
- [x] Recursos AWS criados (S3: n-agent-assets-prod, n-agent-documents-prod)
- [x] Logs do GitHub Actions acessíveis
- [x] Documentação lida e compreendida
- [ ] Lambdas criadas no Terraform (Semana 2)
- [ ] Frontend deployado no S3 (Semana 2)

---

## 📚 Referências

- **Quick Start**: [docs/QUICKSTART_CREDENTIALS.md](./QUICKSTART_CREDENTIALS.md)
- **Guia Completo**: [docs/SETUP_CREDENTIALS.md](./SETUP_CREDENTIALS.md)
- **GitHub Actions Docs**: https://docs.github.com/actions
- **AWS IAM Best Practices**: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

---

## 💡 Dicas de Segurança

1. **Nunca commite credenciais**: Use sempre GitHub Secrets
2. **Rotação periódica**: Trocar access keys a cada 90 dias
3. **Menor privilégio**: Use políticas IAM específicas (não AdministratorAccess)
4. **MFA**: Habilitar MFA para console AWS
5. **Audit logs**: CloudTrail habilitado para rastreabilidade
6. **Separação de ambientes**: Credenciais diferentes para dev e prod

---

**Tudo pronto para começar os deploys automatizados!** 🚀

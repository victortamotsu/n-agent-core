# 🛡️ Snyk - Guia Completo de Setup

**Atualizado**: 27/12/2025

---

## 🔑 Como Encontrar o Auth Token

### Opção 1: Via URL Direta (Mais Rápido)

Acesse diretamente:
```
https://app.snyk.io/account
```

### Opção 2: Via Interface (Passo a Passo)

1. **Login no Snyk**: https://app.snyk.io/

2. **Clique no seu Avatar** (canto superior direito)

3. **Selecione "Account Settings"** (não "Organization Settings"!)

4. **Na página Account Settings**, você verá várias abas:
   - General
   - Authorized Applications
   - Notification Settings
   - etc.

5. **Role a página para baixo** na aba "General"

6. **Procure por "Auth Token"** ou "API Token"

7. **Clique em "Click to show"** para revelar o token

8. **Copie o token** (formato: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### Alternativa: Service Account (Melhor para CI/CD)

Se não encontrar "Auth Token" em Account Settings, use Service Account:

1. Vá para: https://app.snyk.io/
2. Clique no nome da **Organization** (canto superior esquerdo)
3. Selecione **"Settings"** (ícone de engrenagem)
4. No menu lateral esquerdo: **"Service accounts"**
5. Clique em **"Create a service account"**
6. Nome: `github-actions-n-agent`
7. Role: `Org Admin` ou `Org Collaborator`
8. Clique em **"Create"**
9. **Copie o token** que aparece (você só verá uma vez!)

---

## 🔧 Configurar no GitHub

### Via GitHub CLI (Recomendado)

```bash
# Cole o token que você copiou
gh secret set SNYK_TOKEN -b "seu-token-aqui"

# Verificar
gh secret list | grep SNYK
```

### Via Interface Web

```
1. GitHub → Repositório n-agent-core
2. Settings → Secrets and variables → Actions
3. "New repository secret"
4. Name: SNYK_TOKEN
5. Secret: cole o token do Snyk
6. "Add secret"
```

---

## 📊 Entendendo os "200 Testes/Mês"

### ❌ NÃO É: 200 requisições totais

### ✅ É: 200 scans completos do projeto

### O Que Conta Como "1 Teste"?

| Ação | Conta como teste? | Quantos testes? |
|------|-------------------|-----------------|
| **Push para GitHub** | ✅ Sim | 1 teste |
| **Pull Request** | ✅ Sim | 1 teste |
| **Scan manual** | ✅ Sim | 1 teste |
| **Verificar vulnerabilidade** | ❌ Não | 0 |
| **Ver dashboard** | ❌ Não | 0 |
| **Receber alertas** | ❌ Não | 0 |
| **Auto-monitoring** | ❌ Não | 0 (contínuo grátis) |

### Exemplo Real de Uso

```
Mês de Dezembro 2025:
├── Semana 1: 10 pushes = 10 testes
├── Semana 2: 15 pushes = 15 testes
├── Semana 3: 12 pushes = 12 testes
└── Semana 4: 8 pushes  = 8 testes
─────────────────────────────────────
Total: 45 testes (22% do limite)
```

### 200 Testes é Muito ou Pouco?

| Cenário | Pushes/Mês | Testes Usados | Status |
|---------|------------|---------------|--------|
| **Solo developer** (você agora) | 40-60 | 40-60 | ✅ **Sobra muito** |
| **2 devs ativos** | 80-100 | 80-100 | ✅ **Confortável** |
| **3-4 devs** | 120-180 | 120-180 | ✅ **OK** |
| **5+ devs muito ativos** | 200+ | 200+ | ⚠️ **Upgrade needed** |

### Dicas para Economizar Testes

Se você estiver chegando perto do limite:

```yaml
# .github/workflows/ci.yml
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]  # Remover develop aqui
    
jobs:
  security-scan:
    # Só roda em PRs e main, não em toda branch
    if: github.event_name == 'pull_request' || github.ref == 'refs/heads/main'
```

Ou configure para rodar apenas 1x por dia:

```yaml
security-scan:
  runs-on: ubuntu-latest
  # Só roda uma vez por dia às 9h
  schedule:
    - cron: '0 9 * * *'
```

---

## 🚀 Testar Integração

Após configurar o token, teste:

```bash
# 1. Fazer um commit vazio para disparar CI
git commit --allow-empty -m "test: snyk integration"
git push origin main

# 2. Acompanhar execução
gh run watch

# 3. Ver detalhes do security scan
gh run list --limit 1
gh run view --job=<job-id>
```

---

## 📈 Monitorar Uso

### Via Snyk Dashboard

1. Acesse: https://app.snyk.io/org/seu-org/manage/billing
2. Veja: "Test usage" → "Current month"
3. Acompanhe o gráfico de consumo

### Via GitHub Actions

Toda execução mostra no log:

```
Security Scan > Run Snyk scan
✓ Tested 1500 dependencies for known vulnerabilities
✓ No vulnerabilities found
✓ Tests remaining this month: 195/200
```

---

## 🎯 Quando Fazer Upgrade?

Considere o plano **Team ($52/mês)** quando:

1. ✅ Ultrapassar 200 testes regularmente (2-3 meses seguidos)
2. ✅ Ter 4+ desenvolvedores ativos
3. ✅ Precisar de features avançadas:
   - Unlimited tests
   - Priority support
   - JIRA/Slack integration
   - License compliance scanning
   - Container scanning

### Comparação de Planos

| Feature | Free | Team ($52/mês) |
|---------|------|----------------|
| **Tests/mês** | 200 | Ilimitado |
| **Desenvolvedores** | Ilimitado | Ilimitado |
| **Open source projects** | ✅ Ilimitado | ✅ Ilimitado |
| **Vulnerability database** | ✅ | ✅ |
| **GitHub/GitLab integration** | ✅ | ✅ |
| **Auto PR fixes** | ✅ | ✅ |
| **Priority support** | ❌ | ✅ |
| **JIRA/Slack** | ❌ | ✅ |
| **License compliance** | ❌ | ✅ |
| **Container scanning** | ❌ | ✅ |
| **IaC scanning** | Limitado | ✅ |

---

## 🔍 O Que o Snyk Detecta?

### Tipos de Vulnerabilidades

```json
{
  "severity": {
    "critical": "Exploração remota, RCE, SQL injection",
    "high": "XSS, CSRF, autenticação fraca",
    "medium": "DoS, information disclosure",
    "low": "Bugs menores, deprecations"
  }
}
```

### Exemplo de Alerta

```
❌ High severity vulnerability found in lodash@4.17.19
┃ 
┃ Prototype Pollution [CWE-1321]
┃ https://snyk.io/vuln/SNYK-JS-LODASH-1018905
┃ 
┃ Introduced through: lodash@4.17.19
┃ Fixed in: lodash@4.17.21
┃ 
┃ Recommendation: Upgrade to lodash@4.17.21
```

### O Que NÃO Detecta

❌ Bugs de lógica no seu código  
❌ Problemas de performance  
❌ Code smells / má prática  
❌ Vulnerabilidades em código proprietário  

Para isso, use ferramentas complementares:
- **SonarCloud** - Code quality
- **CodeQL** - Análise de segurança estática
- **ESLint Security Plugin** - Regras de segurança JS

---

## ⚡ Quick Reference

### URLs Importantes

| Recurso | URL |
|---------|-----|
| **Dashboard** | https://app.snyk.io/ |
| **Account Settings** | https://app.snyk.io/account |
| **Auth Token** | https://app.snyk.io/account (role até Auth Token) |
| **Service Accounts** | https://app.snyk.io/manage/service-accounts |
| **Billing** | https://app.snyk.io/org/seu-org/manage/billing |
| **Docs** | https://docs.snyk.io/ |

### Comandos CLI

```bash
# Instalar Snyk CLI (opcional)
npm install -g snyk

# Login
snyk auth

# Testar projeto localmente
snyk test

# Monitorar projeto (envia para dashboard)
snyk monitor

# Ver vulnerabilidades
snyk test --json | jq '.vulnerabilities'
```

---

## 🆘 Troubleshooting

### "Token inválido" no GitHub Actions

**Problema**: `Error: Authentication failed. Please check your token.`

**Solução**:
1. Verifique se o token está correto: `gh secret list`
2. Re-gere o token no Snyk (Account Settings)
3. Atualize o secret: `gh secret set SNYK_TOKEN -b "novo-token"`

### "Rate limit exceeded"

**Problema**: Ultrapassou 200 testes/mês

**Soluções**:
1. Aguardar virada do mês
2. Fazer upgrade para Team ($52/mês)
3. Reduzir frequência de scans (schedule cron)

### "No projects found"

**Problema**: Snyk não encontrou o `package.json`

**Solução**: Verificar se está rodando no diretório raiz:
```yaml
- name: Run Snyk scan
  working-directory: ./  # Ajustar se necessário
  run: snyk test
```

---

## ✅ Checklist Final

- [ ] Conta criada no Snyk
- [ ] Auth Token ou Service Account Token obtido
- [ ] `SNYK_TOKEN` configurado no GitHub Secrets
- [ ] Commit de teste feito
- [ ] CI rodou com sucesso
- [ ] Dashboard do Snyk mostra o projeto

---

**Dúvidas?** Consulte: https://docs.snyk.io/getting-started

**Semana 1 completa!** Próximo passo: Semana 2 (Lambda Functions + API Gateway) 🚀

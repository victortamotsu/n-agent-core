# 🚀 Guia de Deploy - n-agent

Este documento descreve os 3 modos de deploy disponíveis para o n-agent.

## 📋 Pré-requisitos

### Todos os Modos

- ✅ Python 3.12 configurado (`.python-version`)
- ✅ `bedrock-agentcore-starter-toolkit` em `[dependency-groups] dev` (não em `dependencies`)
- ✅ `requirements.txt` gerado SEM ruamel-yaml
- ✅ Testes passando localmente

### Deploy Manual (WSL 2)

- ✅ WSL 2 Ubuntu instalado
- ✅ uv instalado no WSL: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- ✅ AWS CLI instalado no WSL
- ✅ Credenciais AWS configuradas: `~/.aws/credentials` (WSL)
- ✅ agentcore CLI: `uv tool install bedrock-agentcore-starter-toolkit`

### Deploy CI/CD (GitHub Actions)

- ✅ OIDC Provider configurado no AWS
- ✅ IAM Role `GitHubActionsDeployRole` criado
- ✅ Secrets configurados no GitHub:
  - `AWS_DEPLOY_ROLE_ARN`
  - `BEDROCK_AGENTCORE_MEMORY_ID`

## 🎯 Modo 1: Desenvolvimento Local (Windows)

**Uso**: Desenvolvimento diário, testes rápidos

```powershell
cd agent

# Instalar dependências
uv sync

# Rodar em modo DEV
$env:BEDROCK_AGENTCORE_MEMORY_ID="nAgentMemory-jXyHuA6yrO"
uv run agentcore dev

# Testar (outro terminal)
curl -X POST http://localhost:8080/invocations `
  -H "Content-Type: application/json" `
  -d '{"prompt": "Olá!"}'

# Testes
uv run pytest tests/ -v

# Lint
uv run ruff check src/
```

**Vantagens**:
- ✅ Feedback imediato
- ✅ Debug fácil
- ✅ Não consome recursos AWS

**Quando usar**: Todo desenvolvimento, antes de commit

## 🔧 Modo 2: Deploy Manual (WSL 2)

**Uso**: Deploy pontual, testes em produção, emergências

```powershell
# Deploy completo (validação + testes + deploy)
.\deploy.ps1

# Deploy sem testes (use só se já testou)
.\deploy.ps1 -SkipTests

# Apenas validação (sem deploy)
.\scripts\validate-pre-deploy.ps1
```

**O que o script faz**:
1. ✅ Verifica WSL 2 disponível
2. ✅ Valida dependências (uv, AWS CLI)
3. ✅ Executa testes
4. ✅ Valida build (sem ruamel-yaml)
5. ✅ Confirmação manual
6. ✅ Deploy via `agentcore launch`

**Vantagens**:
- ✅ Controle total
- ✅ Validação pré-deploy automática
- ✅ Feedback imediato

**Quando usar**: 
- Hotfix urgente
- Testar mudança específica em prod
- Troubleshooting

## 🤖 Modo 3: Deploy Automático (GitHub Actions)

**Uso**: Deploy padrão em produção

```bash
# Desenvolvimento
git checkout -b feature/nova-funcionalidade
# ... fazer mudanças em agent/ ...
git add agent/
git commit -m "feat: nova funcionalidade"
git push origin feature/nova-funcionalidade

# PR review...

# Merge para main = deploy automático
git checkout main
git merge feature/nova-funcionalidade
git push origin main
```

**Pipeline**:
1. ✅ Checkout code
2. ✅ Setup uv + Python 3.12
3. ✅ Instalar AWS CLI
4. ✅ Configure AWS via OIDC
5. ✅ Validar requirements.txt (sem ruamel-yaml)
6. ✅ Executar testes (pytest)
7. ✅ Executar linter (ruff)
8. ✅ Deploy (`agentcore launch`)
9. ✅ Smoke test (invoke)
10. ✅ Output logs CloudWatch

**Vantagens**:
- ✅ Repeatable
- ✅ Auditable (log completo)
- ✅ Sem dependência de máquina local

**Quando usar**: Todo deploy para produção (padrão)

## 📊 Comparação

| Aspecto | Local Dev | Manual (WSL) | CI/CD |
|---------|-----------|--------------|-------|
| **Velocidade** | Imediata | ~2 min | ~5 min |
| **Validação** | Manual | Automática | Automática |
| **Testes** | Opcional | Sim | Sim |
| **Auditoria** | Não | Logs locais | GitHub Actions log |
| **Rollback** | N/A | Manual | Git revert + push |
| **Uso** | Desenvolvimento | Emergência | Produção padrão |

## ✅ Checklist Pré-Deploy

Antes de qualquer deploy (manual ou CI/CD):

- [ ] Testes passando: `uv run pytest tests/ -v`
- [ ] Linter OK: `uv run ruff check src/`
- [ ] Python 3.12: `cat agent/.python-version`
- [ ] requirements.txt atualizado: `uv pip compile pyproject.toml`
- [ ] SEM ruamel-yaml: `grep -i ruamel agent/requirements.txt` (deve falhar)
- [ ] Config válido: `.bedrock_agentcore.yaml` tem memory_id, account, region

## 🔍 Verificação Pós-Deploy

```bash
# Status do agent
wsl bash -lc "cd /mnt/c/.../agent && agentcore status"

# Testar invoke
wsl bash -lc "cd /mnt/c/.../agent && agentcore invoke '{\"prompt\": \"test\"}'"

# Logs CloudWatch
aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT \
  --since 5m --follow --region us-east-1

# Dashboard Observability
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#gen-ai-observability/agent-core
```

## 🆘 Troubleshooting

### Erro: ruamel-yaml em requirements.txt

**Causa**: `bedrock-agentcore-starter-toolkit` em `dependencies` (runtime)

**Solução**:
```toml
# pyproject.toml
dependencies = [
    "bedrock-agentcore>=1.1.2",
    # NÃO incluir: bedrock-agentcore-starter-toolkit
    ...
]

[dependency-groups]
dev = [
    "bedrock-agentcore-starter-toolkit>=0.2.5",  # Aqui sim!
    ...
]
```

Depois: `uv sync && uv pip compile pyproject.toml > requirements.txt`

### Deploy falha com 502 Error

**Causa**: Runtime initialization timeout ou erro no código

**Solução**:
1. Ver logs: `aws logs tail /aws/bedrock-agentcore/runtimes/...`
2. Testar local: `uv run agentcore dev`
3. Verificar Memory ID: `$env:BEDROCK_AGENTCORE_MEMORY_ID`

### CI/CD falha na autenticação

**Causa**: OIDC não configurado ou secrets faltando

**Solução**: Ver [.github/SECRETS.md](.github/SECRETS.md)

## 📚 Referências

- [AgentCore Developer Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)
- [uv Documentation](https://docs.astral.sh/uv/)
- [GitHub Actions OIDC AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

# 🚀 Configuração CI/CD com AgentCore Deploy

## Overview

O CI/CD pipeline executa automaticamente em pushes para `main` e `develop`:

1. **Lint** - Valida código com Ruff e Black
2. **Test** - Executa testes com pytest
3. **Deploy** - Deploy automático no AgentCore (apenas `main`)

---

## 📋 Pré-requisitos para Deploy Automático

### 1. Configurar Secrets no GitHub

Acesse: **Settings → Secrets and variables → Actions → New repository secret**

#### Secrets Obrigatórios

```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
BEDROCK_AGENTCORE_MEMORY_ID=n-agent-memory-xxx
```

#### Como obter os valores:

**AWS Credentials**:
```bash
# Criar IAM user para CI/CD
aws iam create-user --user-name github-actions-deployer

# Anexar políticas necessárias
aws iam attach-user-policy \
  --user-name github-actions-deployer \
  --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess

aws iam attach-user-policy \
  --user-name github-actions-deployer \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

# Criar access key
aws iam create-access-key --user-name github-actions-deployer
```

**Memory ID**:
```bash
# Listar memories existentes
aws bedrock-agent list-memories --region us-east-1

# Ou criar nova
aws bedrock-agent create-memory \
  --memory-configuration '{"vectorIndexConfiguration":{"embeddingModelArn":"arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"}}' \
  --name n-agent-memory \
  --description "Memory for n-agent travel assistant" \
  --region us-east-1
```

---

## 🔄 Workflow de Deploy

### Quando o Deploy é Executado

- ✅ Push para branch `main`
- ✅ Após lint e testes passarem
- ❌ Pull requests (apenas lint + test)
- ❌ Push para outras branches

### O que o Deploy Faz

```bash
1. Configura AWS credentials via GitHub Secrets
2. Instala dependências (uv sync)
3. Configura AgentCore (agentcore configure)
4. Faz deploy (agentcore launch)
```

### Variáveis de Ambiente

Configuradas automaticamente no workflow:

```yaml
ROUTER_MODEL: us.amazon.nova-micro-v1:0
CHAT_MODEL: us.amazon.nova-lite-v1:0
PLANNING_MODEL: us.amazon.nova-pro-v1:0
VISION_MODEL: anthropic.claude-3-5-sonnet-20241022-v2:0
AWS_REGION: us-east-1
BEDROCK_AGENTCORE_MEMORY_ID: (from secrets)
```

---

## 🧪 Testar CI/CD

### 1. Commit e Push

```bash
git add .
git commit -m "feat: Update documentation structure"
git push origin main
```

### 2. Monitorar Execução

- Acesse: **Actions** tab no GitHub
- Clique no workflow em execução
- Acompanhe os 3 jobs: Lint → Test → Deploy

### 3. Verificar Deploy

```bash
# Listar agents deployados
aws bedrock-agent list-agents --region us-east-1

# Ver logs do AgentCore
aws logs tail /aws/bedrock-agentcore/n-agent-core --follow
```

---

## ❌ Troubleshooting

### Deploy falha: "AccessDeniedException"

**Causa**: IAM user sem permissões suficientes

**Solução**:
```bash
aws iam attach-user-policy \
  --user-name github-actions-deployer \
  --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess
```

### Deploy falha: "Memory not found"

**Causa**: `BEDROCK_AGENTCORE_MEMORY_ID` inválido ou inexistente

**Solução**:
```bash
# Verificar se Memory existe
aws bedrock-agent get-memory \
  --memory-id n-agent-memory-xxx \
  --region us-east-1

# Criar se não existir (ver seção Pré-requisitos)
```

### Deploy falha: "agentcore: command not found"

**Causa**: `bedrock-agentcore-starter-toolkit` não instalado

**Solução**: Verificar `agent/pyproject.toml` inclui:
```toml
[project.dependencies]
bedrock-agentcore-starter-toolkit = ">=0.2.5"
```

---

## 🔒 Segurança

### Boas Práticas

1. **IAM Least Privilege**: User CI/CD só com permissões necessárias
2. **Rotate Keys**: Renovar AWS keys periodicamente
3. **Protected Branches**: Exigir code review antes do merge
4. **Environment Secrets**: Usar GitHub Environments para staging/prod

### Permissões Mínimas IAM

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeAgent",
        "bedrock:CreateAgent",
        "bedrock:UpdateAgent",
        "bedrock-agent:CreateMemory",
        "bedrock-agent:GetMemory",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 📊 Custos

### Por Deploy

- **GitHub Actions**: Gratuito (repositories públicos)
- **AWS Bedrock**: ~$0.01 (validação de deploy)
- **CloudWatch Logs**: ~$0.005/GB (logs retidos 7 dias)

### Otimizações

- Deploy apenas em `main` (não em PRs)
- Cache de dependências UV
- Timeout de 10 minutos (evita custos desnecessários)

---

## 🎯 Próximos Passos

1. ✅ Configurar secrets no GitHub
2. ✅ Fazer primeiro push para `main`
3. ✅ Verificar deploy bem-sucedido
4. 🔄 Configurar environments (staging/production)
5. 🔄 Adicionar smoke tests pós-deploy

---

**Última atualização**: 28/12/2024  
**Workflow**: [.github/workflows/ci.yml](../.github/workflows/ci.yml)

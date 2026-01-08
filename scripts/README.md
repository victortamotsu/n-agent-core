# Scripts de Automação - n-agent

Este diretório contém scripts para desenvolvimento, deploy e testes do n-agent.

## 📜 Scripts Disponíveis

### Development & Testing

- **`dev.sh`** - Inicia servidor de desenvolvimento local
- **`validate.sh`** - Valida código (linter + testes) sem deploy
- **`test-production.sh`** - Suite de testes de produção

### Deployment

- **`deploy.sh`** - Deploy manual (use apenas para debug/testes)
- **`provision.sh`** - Provisiona infraestrutura (Cognito, API Gateway, Lambda BFF)
- **GitHub Actions** - Deploy automático via pipeline (RECOMENDADO)

### Setup

- **`wsl2-quickstart.sh`** - Setup automático de ambiente WSL 2

---

## 🧪 Testes de Produção

### test-production.sh

Suite completa de testes para validar funcionamento do agent em produção.

**Modos de Teste**:

1. **Local/Dev** - Testa contra servidor local (`agentcore dev`)
2. **Production** - Testa contra AWS AgentCore Runtime (default)

**Uso**:

```bash
# Teste em produção (AWS)
./scripts/test-production.sh

# Ou explicitamente
./scripts/test-production.sh production

# Teste local (requer agentcore dev rodando)
./scripts/test-production.sh local
```

**Testes Inclusos**:
- ✅ Basic invoke (agent respondendo)
- ✅ Router classification (otimização de custo)
- ✅ Memory context save
- ✅ Memory context retrieval (entre sessões)
- ✅ Travel query handling

**Saída Esperada**:
```
========================================
n-agent Production Test Suite
========================================
Environment: Local
Test Mode: production

Test 1: Basic greeting
  ✓ PASSED
Test 2: Travel query (router test)
  ✓ PASSED
Test 3: Memory context save
  ✓ PASSED
Test 4: Memory context retrieval
  ✓ PASSED

========================================
Test Results
========================================
Total:  4
Passed: 4
Failed: 0

✓ All tests passed!
```

---

## 🚀 Deploy

### ✅ RECOMENDADO: GitHub Actions

Esta é a forma **padrão e correta** de fazer deploy:

```bash
git add agent/
git commit -m "feat: nova funcionalidade"
git push origin main  # Auto-deploy
```

**Pipeline automática**:
1. ✅ Valida dependencies (Python 3.12, no ruamel-yaml)
2. ✅ Roda 29 testes unitários
3. ✅ Deploy via `agentcore launch`
4. ✅ **Testes de produção** (test-production.sh)
5. ✅ CloudWatch logs

### ⚠️ Deploy Manual (deploy.sh)

Use **APENAS** para:
- 🔧 Testes locais e debugging
- 🧪 Mudanças experimentais
- 🚨 Hotfixes de emergência

```bash
./scripts/deploy.sh              # Full validation + deploy
./scripts/deploy.sh --skip-tests # Emergency only
```

**NÃO use** para workflow regular de desenvolvimento.

---

## 🏗️ Provisioning Infrastructure (provision.sh)

Script automatizado para provisionar infraestrutura via Terraform:
- ✅ Cognito User Pool (autenticação)
- ✅ API Gateway (HTTP API com JWT)
- ✅ Lambda BFF (proxy API → AgentCore)

### Uso

```bash
./scripts/provision.sh
```

### O que o script faz?

1. **Valida pré-requisitos**:
   - ✅ Terraform instalado (>= 1.6.0)
   - ✅ AWS CLI configurado
   - ✅ AgentCore Runtime deployed
   
2. **Verifica terraform.tfvars**:
   - Cria de `terraform.tfvars.example` se não existir
   - Valida valores obrigatórios (agentcore_agent_id, etc.)

3. **Terraform workflow**:
   - `terraform init`
   - `terraform plan` (com confirmação)
   - `terraform apply`

4. **Captura outputs**:
   - Salva outputs em JSON
   - Mostra summary (API endpoint, Cognito IDs, Lambda)

5. **Health check**:
   - Testa endpoint `/health` da API
   - Sugere próximos passos

### Outputs capturados

```json
{
  "api_endpoint": "https://abc123.execute-api.us-east-1.amazonaws.com",
  "cognito_user_pool_id": "us-east-1_ABC123",
  "cognito_client_id": "1a2b3c4d5e6f7g8h9i0j",
  "lambda_bff_function_name": "n-agent-core-bff-prod"
}
```

### Próximos passos (após provisioning)

1. **Criar usuário de teste**:
```bash
aws cognito-idp admin-create-user \
  --user-pool-id "us-east-1_ABC123" \
  --username "test@example.com" \
  --temporary-password "TempPass123!" \
  --user-attributes Name=email,Value=test@example.com
```

2. **Executar testes de integração**:
```bash
export API_ENDPOINT="https://abc123.execute-api.us-east-1.amazonaws.com"
export COGNITO_USER_POOL_ID="us-east-1_ABC123"
export COGNITO_CLIENT_ID="1a2b3c4d5e6f7g8h9i0j"
./scripts/test-api-integration.sh
```

3. **Configurar GitHub Secrets** (para CI/CD):
```bash
gh secret set API_ENDPOINT --body "$API_ENDPOINT"
gh secret set COGNITO_USER_POOL_ID --body "$COGNITO_USER_POOL_ID"
gh secret set COGNITO_CLIENT_ID --body "$COGNITO_CLIENT_ID"
```

4. **Deploy frontend**:
```bash
cd apps/web-client
echo "VITE_API_URL=$API_ENDPOINT" > .env.production
npm run build
```

---

## 🛠️ WSL 2 Quick Start

Script automatizado para configurar o ambiente completo de desenvolvimento no WSL 2.

### O que o script faz?

✅ Atualiza sistema Ubuntu  
✅ Instala Python 3.11, pip, build tools  
✅ Instala uv (Python package manager)  
✅ Instala AWS CLI  
✅ Copia AWS credentials do Windows  
✅ Copia projeto para filesystem do WSL  
✅ Cria venv com Python 3.11  
✅ Instala todas as dependências  
✅ Gera requirements.txt  
✅ Roda testes para validar  
✅ Verifica configuração do AgentCore  

### Como usar?

#### 1. Instalar WSL 2 (se ainda não tiver)

No PowerShell como Administrador:

```powershell
wsl --install
```

Reinicie o Windows após a instalação.

#### 2. Abrir Ubuntu

Após reiniciar, o Ubuntu abrirá automaticamente. Configure usuário e senha quando solicitado.

#### 3. Rodar o quick start script

```bash
# Copiar script do Windows para WSL
cp /mnt/c/Users/victo/Projetos/n-agent-core/scripts/wsl2-quickstart.sh ~/

# Dar permissão de execução
chmod +x ~/wsl2-quickstart.sh

# Executar
~/wsl2-quickstart.sh
```

#### 4. Seguir os próximos passos

Após o script concluir, você verá instruções para:
- Ativar venv
- Rodar dev mode
- Deploy para AWS
- Testar endpoint

### Tempo estimado

- **Setup inicial (primeira vez)**: ~10-15 minutos
- **Instalações**: ~5 minutos
- **Cópia do projeto**: ~2 minutos
- **Instalação de dependências**: ~3 minutos

### Troubleshooting

#### Erro: "Este script deve ser executado dentro do WSL 2!"

Você está rodando no PowerShell/CMD do Windows. Execute dentro do Ubuntu (WSL).

#### Erro: "Projeto não encontrado"

Verifique se o caminho está correto no script:
```bash
nano ~/wsl2-quickstart.sh
# Alterar linha: /mnt/c/Users/victo/Projetos/n-agent-core
```

#### Erro: AWS credentials não encontradas

Configure manualmente após o script:
```bash
aws configure
```

#### Performance lenta

Certifique-se de que o projeto foi copiado para `~/n-agent-core` (filesystem do WSL), não `/mnt/c/...` (Windows).

### Comandos úteis após setup

```bash
# Entrar no projeto
cd ~/n-agent-core/agent
source .venv/bin/activate

# Dev mode
uv run agentcore dev

# Testes
uv run pytest tests/ -v

# Linter
uv run ruff check src/ --fix

# Formatter
uv run ruff format src/

# Deploy
uv run agentcore launch

# Status
uv run agentcore status

# Logs
uv run agentcore logs
```

### Integração com VS Code

1. Instalar extensão **WSL** no VS Code (Windows)
2. Clicar no ícone verde (canto inferior esquerdo) → "Connect to WSL"
3. Abrir pasta: `File` → `Open Folder` → `~/n-agent-core`
4. Selecionar Python interpreter: `Ctrl+Shift+P` → "Python: Select Interpreter" → `~/.venv/bin/python`

### Próximos passos

Após setup completo, siga o [Checklist da Fase 1](../.promtps_iniciais/fases_implementacao/CHECKLIST_FASE1.md) para completar o deploy.

### Documentação completa

[WSL 2 Setup Guide](../docs/WSL2_SETUP.md) - Guia completo com todos os detalhes.

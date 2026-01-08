# Production Environment - Terraform Configuration

Este diretório contém a configuração Terraform para o ambiente de **produção** do n-agent, incluindo:

- ✅ **Cognito User Pool**: Autenticação com Google/Microsoft OAuth
- ✅ **API Gateway**: HTTP API com autenticação JWT
- ✅ **Lambda BFF**: Proxy entre API Gateway e AgentCore Runtime
- ✅ **DynamoDB**: Tabelas para dados e perfis (via módulo root)
- ✅ **WhatsApp Lambda**: Webhook para integração WhatsApp (via módulo root)

## 📋 Pré-requisitos

1. **AWS CLI configurado**:
   ```bash
   aws configure
   aws sts get-caller-identity  # Verificar credenciais
   ```

2. **Terraform >= 1.6.0**:
   ```bash
   terraform version
   ```

3. **AgentCore Runtime deployed**:
   ```bash
   cd ../../../agent
   agentcore status  # Deve mostrar READY
   ```

4. **Backend S3 configurado** (opcional):
   - Bucket: `n-agent-terraform-state`
   - DynamoDB: `n-agent-terraform-locks`
   - Remova o bloco `backend "s3"` no `main.tf` para usar backend local

## 🚀 Deployment

### 1. Criar arquivo de variáveis

```bash
# Copiar exemplo
cp terraform.tfvars.example terraform.tfvars

# Editar com seus valores
# Especialmente: agentcore_agent_id, OAuth credentials (opcional)
nano terraform.tfvars
```

**Valores obrigatórios**:
- `agentcore_agent_id`: Obtido de `.bedrock_agentcore.yaml` ou `agentcore status`
- `agentcore_agent_arn`: ARN completo do AgentCore Runtime

**Valores opcionais** (deixe vazio para pular OAuth):
- `google_client_id` / `google_client_secret`
- `microsoft_client_id` / `microsoft_client_secret` / `microsoft_tenant_id`

### 2. Inicializar Terraform

```bash
terraform init
```

**Se usar backend S3**:
```bash
# Criar bucket e tabela primeiro (apenas 1x)
cd ../../bootstrap
terraform init && terraform apply

# Voltar para prod
cd ../environments/prod
terraform init
```

### 3. Planejar mudanças

```bash
terraform plan -out=tfplan
```

**Revisar cuidadosamente**:
- ✅ Resources to create: ~15-20 recursos
- ✅ Cognito User Pool, API Gateway, Lambda, integrations
- ⚠️ Nenhum recurso deve ser **destroyed** (a menos que intencional)

### 4. Aplicar configuração

```bash
terraform apply tfplan
```

Aguardar ~2-3 minutos para provisionamento.

### 5. Capturar outputs

```bash
terraform output -json > outputs.json

# Ou visualizar diretamente
terraform output deployment_summary
```

**Outputs importantes**:
```json
{
  "api_endpoint": "https://abc123.execute-api.us-east-1.amazonaws.com",
  "cognito_pool_id": "us-east-1_ABC123",
  "cognito_client_id": "1a2b3c4d5e6f7g8h9i0j",
  "lambda_bff": "n-agent-core-bff-prod"
}
```

## 🧪 Testes

### 1. Health Check (público)

```bash
API_ENDPOINT=$(terraform output -raw api_endpoint)
curl -X GET "$API_ENDPOINT/health"
```

**Resposta esperada**:
```json
{"status": "healthy", "service": "n-agent-bff"}
```

### 2. Autenticação Cognito

```bash
# Obter IDs
POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_client_id)

# Criar usuário de teste (via AWS Console ou CLI)
aws cognito-idp admin-create-user \
  --user-pool-id "$POOL_ID" \
  --username "test@example.com" \
  --temporary-password "TempPass123!" \
  --user-attributes Name=email,Value=test@example.com

# Obter token JWT (após definir senha permanente)
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters USERNAME=test@example.com,PASSWORD=YourPassword123!
```

### 3. Chat Request (autenticado)

```bash
# Usar token JWT do passo anterior
JWT_TOKEN="eyJraWQiOiI..."

curl -X POST "$API_ENDPOINT/chat" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Olá, quero planejar uma viagem para Paris!",
    "sessionId": "test-session-123"
  }'
```

### 4. Teste completo (script)

```bash
# Voltar para raiz do projeto
cd ../../../..

# Executar suite de testes
./scripts/test-api-integration.sh
```

**Testes incluem**:
- ✅ Health check
- ✅ Autenticação Cognito
- ✅ Validação de request não autorizado
- ✅ Chat com autenticação
- ✅ Persistência de contexto (memória)

## 🔐 Segredos GitHub (CI/CD)

Adicionar ao GitHub Secrets para pipeline:

```bash
# API Gateway
gh secret set API_ENDPOINT --body "$(terraform output -raw api_endpoint)"
gh secret set API_GATEWAY_ID --body "$(terraform output -raw api_id)"

# Cognito
gh secret set COGNITO_USER_POOL_ID --body "$(terraform output -raw cognito_user_pool_id)"
gh secret set COGNITO_CLIENT_ID --body "$(terraform output -raw cognito_client_id)"

# Lambda
gh secret set LAMBDA_BFF_FUNCTION_NAME --body "$(terraform output -raw lambda_bff_function_name)"

# AgentCore (já deve existir)
gh secret set AGENTCORE_AGENT_ID --body "nagent-GcrnJb6DU5"
gh secret set AGENTCORE_MEMORY_ID --body "nAgentMemory-jXyHuA6yrO"
```

## 📊 Monitoramento

### CloudWatch Logs

```bash
# Lambda BFF logs
aws logs tail /aws/lambda/n-agent-core-bff-prod --follow

# API Gateway logs
aws logs tail /aws/apigateway/n-agent-core-api-prod --follow

# AgentCore Runtime logs
aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT --follow
```

### Métricas importantes

- **API Gateway**: 4XXError, 5XXError, Latency
- **Lambda**: Errors, Duration, ConcurrentExecutions
- **Cognito**: UserAuthentication, SignInSuccesses

## 🧹 Cleanup

**⚠️ ATENÇÃO**: Isso irá destruir TODOS os recursos (irreversível!)

```bash
terraform destroy
```

**Alternativa segura** (destruir apenas módulos novos):

```bash
# Remover apenas Cognito
terraform destroy -target=module.cognito

# Remover apenas API Gateway
terraform destroy -target=module.api_gateway

# Remover apenas Lambda BFF
terraform destroy -target=module.lambda_bff
```

## 📝 Troubleshooting

### Erro: "Backend configuration required"

```bash
# Remover bloco backend "s3" do main.tf
# OU criar backend:
cd ../../bootstrap && terraform apply
```

### Erro: "AgentCore agent not found"

```bash
# Verificar ID correto
cd ../../../agent
agentcore status

# Atualizar terraform.tfvars com ID correto
```

### Erro: "Lambda invocation failed"

```bash
# Verificar logs
aws logs tail /aws/lambda/n-agent-core-bff-prod --follow

# Testar Lambda diretamente
aws lambda invoke \
  --function-name n-agent-core-bff-prod \
  --payload '{"prompt":"test"}' \
  response.json
```

### Erro: "Cognito user pool domain already exists"

```bash
# Trocar nome do domínio em terraform.tfvars
# user_pool_domain deve ser único globalmente
```

## 🎯 Próximos Passos

1. ✅ **Provisionar infraestrutura**: `terraform apply`
2. ✅ **Executar testes**: `./scripts/test-api-integration.sh`
3. ✅ **Configurar GitHub Secrets**: Para CI/CD
4. ⏭️ **Deploy frontend**: `apps/web-client` com endpoint da API
5. ⏭️ **Configurar domínio**: Route53 + ACM para HTTPS
6. ⏭️ **Habilitar WAF**: Proteção contra ataques

## 📚 Referências

- [Cognito Module](../../modules/cognito/README.md)
- [API Gateway Module](../../modules/api-gateway/README.md)
- [Lambda BFF Module](../../modules/lambda-bff/README.md)
- [Deploy Guide](../../../../docs/DEPLOY_GUIDE.md)
- [Cost Analysis](../../../../docs/COST_ANALYSIS.md)

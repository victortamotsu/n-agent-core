# 🏗️ Terraform Infrastructure as Code

## Overview

Deploy toda a infraestrutura do n-agent-core usando Terraform com state remoto (S3) e locks (DynamoDB).

---

## 📋 Estrutura

```
infra/terraform/
├── backend.tf              # Backend S3 + DynamoDB
├── main.tf                 # Módulos principais
├── variables.tf            # Variáveis globais
├── outputs.tf              # Outputs
├── bootstrap/              # Setup inicial de backend
│   ├── main.tf
│   └── versions.tf
├── modules/
│   ├── agentcore/         # Bedrock AgentCore + Memory
│   ├── whatsapp-lambda/   # Lambda webhook WhatsApp
│   ├── secrets/           # Secrets Manager
│   ├── iam/               # Roles e políticas
│   └── storage/           # S3 + DynamoDB
└── environments/
    ├── dev/               # Ambiente dev
    └── prod/              # Ambiente prod
```

---

## 🚀 Setup Inicial

### 1. Bootstrap (apenas primeira vez)

```bash
# Criar S3 bucket e DynamoDB table para state/locks
cd infra/terraform/bootstrap

terraform init
terraform plan
terraform apply

# Outputs:
# s3_bucket_name = "n-agent-terraform-state"
# dynamodb_table_name = "n-agent-terraform-locks"
```

### 2. Configurar Variáveis de Ambiente

Terraform lê automaticamente as secrets do GitHub Actions via `TF_VAR_*`:

```bash
# Localmente (para testes)
export TF_VAR_whatsapp_verify_token="${{ secrets.WHATSAPP_VERIFY_TOKEN }}"
export TF_VAR_whatsapp_access_token="${{ secrets.WHATSAPP_ACCESS_TOKEN }}"
export TF_VAR_whatsapp_phone_number_id="${{ secrets.WHATSAPP_PHONE_NUMBER_ID }}"
export TF_VAR_google_oauth_client_id="${{ secrets.GOOGLE_OAUTH_CLIENT_ID }}"
export TF_VAR_google_oauth_client_secret="${{ secrets.GOOGLE_OAUTH_CLIENT_SECRET }}"
export TF_VAR_facebook_app_id="${{ secrets.FACEBOOK_APP_ID }}"
export TF_VAR_facebook_app_secret="${{ secrets.FACEBOOK_APP_SECRET }}"
export TF_VAR_microsoft_client_id="${{ secrets.MICROSOFT_CLIENT_ID }}"
export TF_VAR_microsoft_client_secret="${{ secrets.MICROSOFT_CLIENT_SECRET }}"
```

### 3. Deploy Dev Environment

```bash
cd infra/terraform/environments/dev

terraform init
terraform plan
terraform apply

# Outputs incluem:
# - agentcore_agent_id
# - agentcore_memory_id
# - whatsapp_lambda_url
# - secrets_manager_arn
```

### 4. Deploy Prod Environment

```bash
cd infra/terraform/environments/prod

terraform init
terraform plan
terraform apply
```

---

## 🔄 CI/CD Integration

### GitHub Actions Workflow

O workflow atualizado usa Terraform em vez de `agentcore launch`:

```yaml
deploy:
  name: Deploy Infrastructure
  runs-on: ubuntu-latest
  needs: [lint, test]
  if: github.ref == 'refs/heads/main'
  
  steps:
  - uses: actions/checkout@v4
  
  - name: Setup Terraform
    uses: hashicorp/setup-terraform@v3
    with:
      terraform_version: 1.6.0
  
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID_PROD }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY_PROD }}
      aws-region: us-east-1
  
  - name: Terraform Init
    run: |
      cd infra/terraform/environments/prod
      terraform init
  
  - name: Terraform Plan
    run: |
      cd infra/terraform/environments/prod
      terraform plan \
        -var="whatsapp_verify_token=${{ secrets.WHATSAPP_VERIFY_TOKEN }}" \
        -var="whatsapp_access_token=${{ secrets.WHATSAPP_ACCESS_TOKEN }}" \
        -var="whatsapp_phone_number_id=${{ secrets.WHATSAPP_PHONE_NUMBER_ID }}" \
        -out=tfplan
  
  - name: Terraform Apply
    run: |
      cd infra/terraform/environments/prod
      terraform apply -auto-approve tfplan
```

---

## 📦 Módulos

### 1. AgentCore Module
- **Recursos**: Bedrock Memory (OpenSearch Serverless), AgentCore deploy via CLI
- **Inputs**: Models, timeout, memory, IAM role
- **Outputs**: agent_id, memory_id

### 2. WhatsApp Lambda Module
- **Recursos**: Lambda function, Function URL, SNS topic, CloudWatch logs
- **Inputs**: Secrets ARN, AgentCore agent ID
- **Outputs**: lambda_url, sns_topic_arn

### 3. Secrets Module
- **Recursos**: Secrets Manager secret com todas credenciais
- **Inputs**: WhatsApp, OAuth credentials
- **Outputs**: secret_arn

### 4. IAM Module
- **Recursos**: Roles para AgentCore e Lambda
- **Permissions**: Bedrock, Secrets Manager, SNS, CloudWatch
- **Outputs**: agentcore_role_arn, lambda_role_arn

### 5. Storage Module
- **Recursos**: S3 bucket (documents), DynamoDB table (app data)
- **Features**: Versioning, encryption, public access block
- **Outputs**: bucket names, table name

---

## 🔐 Secrets Reutilizadas

### Já Configuradas no GitHub

```bash
✅ AWS_ACCESS_KEY_ID          # Root/shared
✅ AWS_ACCESS_KEY_ID_DEV       # Dev environment
✅ AWS_ACCESS_KEY_ID_PROD      # Prod environment
✅ AWS_SECRET_ACCESS_KEY       # Root/shared
✅ AWS_SECRET_ACCESS_KEY_DEV   # Dev environment
✅ AWS_SECRET_ACCESS_KEY_PROD  # Prod environment
✅ WHATSAPP_VERIFY_TOKEN       # Usado no módulo secrets
✅ WHATSAPP_ACCESS_TOKEN       # Usado no módulo secrets
✅ WHATSAPP_PHONE_NUMBER_ID    # Usado no módulo secrets
✅ GOOGLE_OAUTH_CLIENT_ID      # Usado no módulo secrets
✅ GOOGLE_OAUTH_CLIENT_SECRET  # Usado no módulo secrets
✅ FACEBOOK_APP_ID             # Usado no módulo secrets
✅ FACEBOOK_APP_SECRET         # Usado no módulo secrets
✅ MICROSOFT_CLIENT_ID         # Usado no módulo secrets
✅ MICROSOFT_CLIENT_SECRET     # Usado no módulo secrets
```

### Não Precisa Criar

Todas as secrets necessárias já existem! Terraform as lê automaticamente via `TF_VAR_*`.

---

## 🛠️ Comandos Úteis

### Verificar State

```bash
cd infra/terraform/environments/dev
terraform show
terraform state list
```

### Verificar Outputs

```bash
terraform output
terraform output -json > outputs.json
```

### Destruir Infraestrutura (cuidado!)

```bash
# Dev
cd infra/terraform/environments/dev
terraform destroy

# Prod
cd infra/terraform/environments/prod
terraform destroy
```

### Importar Recursos Existentes

```bash
# Exemplo: importar Lambda existente
terraform import module.infrastructure.module.whatsapp_webhook.aws_lambda_function.whatsapp_webhook \
  n-agent-core-dev-whatsapp-webhook
```

---

## 💰 Custos Estimados

### State Storage
- **S3**: ~$0.023/GB-month (< $0.10/mês para state)
- **DynamoDB**: Pay-per-request (~$0.01/mês com locks ocasionais)

### Infrastructure (via Terraform)
- **AgentCore**: Pay-per-use (~$1.52/mês com 1000 requests)
- **Lambda**: $0.20 per 1M requests + compute
- **OpenSearch Serverless**: $345.60/mês (2 OCUs mínimo)
- **Secrets Manager**: $0.40/secret-month
- **S3 Documents**: $0.023/GB-month
- **DynamoDB**: Pay-per-request

**Total estimado**: ~$350-400/mês (maioria é OpenSearch para Memory)

---

## 🔄 Versionamento e Rollback

### State Versioning

O S3 bucket tem versionamento habilitado:

```bash
# Listar versões
aws s3api list-object-versions \
  --bucket n-agent-terraform-state \
  --prefix prod/terraform.tfstate

# Restaurar versão anterior
aws s3api get-object \
  --bucket n-agent-terraform-state \
  --key prod/terraform.tfstate \
  --version-id VERSION_ID \
  terraform.tfstate
```

### Rollback de Deploy

```bash
# 1. Reverter código Git
git revert HEAD

# 2. Re-deploy via Terraform
cd infra/terraform/environments/prod
terraform apply
```

---

## 🐛 Troubleshooting

### State locked

```bash
# Forçar unlock (cuidado!)
terraform force-unlock LOCK_ID
```

### Backend não inicializado

```bash
# Re-executar bootstrap
cd infra/terraform/bootstrap
terraform apply
```

### Módulo não encontrado

```bash
# Re-inicializar
terraform init -upgrade
```

---

## 📚 Referências

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [AWS Bedrock Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagent_agent)

---

**Última atualização**: 28/12/2024  
**Status**: ✅ Pronto para uso

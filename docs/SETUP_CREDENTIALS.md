# Guia de Configuração - GitHub Actions com AWS e GCP

## 📋 Índice

1. [Configuração AWS](#configuração-aws)
2. [Configuração GCP](#configuração-gcp)
3. [Configuração GitHub Secrets](#configuração-github-secrets)
4. [IAM Roles e Políticas](#iam-roles-e-políticas)

---

## 🔐 Configuração AWS

### Passo 1: Criar IAM User para CI/CD

1. Acesse o Console AWS → IAM → Users
2. Clique em "Add users"
3. Nome: `github-actions-n-agent`
4. Marque: "Access key - Programmatic access"

### Passo 2: Obter Access Keys

Após criar o usuário, você receberá:

```
AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

⚠️ **IMPORTANTE**: Guarde essas credenciais em local seguro. A Secret Key só é mostrada uma vez!

### Passo 3: Criar Políticas IAM Personalizadas

#### Política para Deploy (Desenvolvimento)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateManagement",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::n-agent-terraform-state-dev",
        "arn:aws:s3:::n-agent-terraform-state-dev/*"
      ]
    },
    {
      "Sid": "DynamoDBManagement",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable",
        "dynamodb:DeleteTable",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:ListTagsOfResource"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/n-agent-*-dev"
    },
    {
      "Sid": "S3BucketManagement",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutEncryptionConfiguration",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::n-agent-*-dev"
    },
    {
      "Sid": "S3ObjectManagement",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::n-agent-*-dev/*"
    },
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:ListFunctions",
        "lambda:TagResource"
      ],
      "Resource": "arn:aws:lambda:us-east-1:*:function:n-agent-*-dev"
    },
    {
      "Sid": "IAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy"
      ],
      "Resource": "arn:aws:iam::*:role/n-agent-*-dev"
    },
    {
      "Sid": "APIGatewayManagement",
      "Effect": "Allow",
      "Action": [
        "apigateway:*"
      ],
      "Resource": "arn:aws:apigateway:us-east-1::/*"
    },
    {
      "Sid": "CloudFrontManagement",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CognitoManagement",
      "Effect": "Allow",
      "Action": [
        "cognito-idp:CreateUserPool",
        "cognito-idp:DeleteUserPool",
        "cognito-idp:UpdateUserPool",
        "cognito-idp:DescribeUserPool",
        "cognito-idp:CreateUserPoolClient",
        "cognito-idp:DeleteUserPoolClient"
      ],
      "Resource": "arn:aws:cognito-idp:us-east-1:*:userpool/*"
    }
  ]
}
```

#### Política para Produção (Mais Restritiva)

Para produção, crie uma política similar mas com:
- Resources específicos (sem wildcards)
- Sem permissões de Delete
- Apenas Update/Deploy

### Passo 4: Comandos via AWS CLI

Se preferir criar via CLI:

```bash
# Criar usuário
aws iam create-user --user-name github-actions-n-agent

# Criar access key
aws iam create-access-key --user-name github-actions-n-agent

# Criar política (salve o JSON acima como policy.json)
aws iam create-policy \
  --policy-name n-agent-github-actions-dev \
  --policy-document file://policy.json

# Anexar política ao usuário
aws iam attach-user-policy \
  --user-name github-actions-n-agent \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/n-agent-github-actions-dev
```

---

## 🔐 Configuração GCP

### Passo 1: Criar Service Account

1. Acesse GCP Console → IAM & Admin → Service Accounts
2. Clique em "Create Service Account"
3. Nome: `n-agent-github-actions`
4. ID: `n-agent-github-actions@PROJECT_ID.iam.gserviceaccount.com`

### Passo 2: Atribuir Roles

Para o MVP, precisamos das seguintes permissões:

```bash
# Vertex AI (para Gemini)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:n-agent-github-actions@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Google Maps (Places, Directions)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:n-agent-github-actions@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageConsumer"
```

### Passo 3: Gerar Chave JSON

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=n-agent-github-actions@PROJECT_ID.iam.gserviceaccount.com
```

Conteúdo do arquivo `key.json`:

```json
{
  "type": "service_account",
  "project_id": "n-agent-project",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "n-agent-github-actions@PROJECT_ID.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://..."
}
```

### Passo 4: Ativar APIs Necessárias

```bash
# Vertex AI (Gemini)
gcloud services enable aiplatform.googleapis.com

# Maps Platform
gcloud services enable maps-backend.googleapis.com
gcloud services enable places-backend.googleapis.com
gcloud services enable directions-backend.googleapis.com
```

### Passo 5: Criar API Keys para Google Maps

```bash
# Criar API Key
gcloud alpha services api-keys create \
  --display-name="n-agent-maps-dev" \
  --api-target=service=maps-backend.googleapis.com \
  --api-target=service=places-backend.googleapis.com \
  --api-target=service=directions-backend.googleapis.com
```

Ou via Console:
1. APIs & Services → Credentials
2. Create Credentials → API Key
3. Restringir a key:
   - Application restrictions: HTTP referrers (frontend) ou IP addresses (backend)
   - API restrictions: Maps JavaScript API, Places API, Directions API

---

## 🔑 Configuração GitHub Secrets

### Passo 1: Acessar Settings

1. Vá para o repositório no GitHub
2. Settings → Secrets and variables → Actions
3. Clique em "New repository secret"

### Passo 2: Adicionar Secrets AWS

| Secret Name | Valor | Descrição |
|-------------|-------|-----------|
| `AWS_ACCESS_KEY_ID` | AKIAIOSFODNN7EXAMPLE | Access Key ID do usuário IAM (dev) |
| `AWS_SECRET_ACCESS_KEY` | wJalr... | Secret Access Key do usuário IAM (dev) |
| `AWS_ACCESS_KEY_ID_PROD` | AKIAI... | Access Key ID para produção |
| `AWS_SECRET_ACCESS_KEY_PROD` | wJalr... | Secret Access Key para produção |
| `CLOUDFRONT_DISTRIBUTION_ID_DEV` | E1234567890ABC | ID da distribuição CloudFront (dev) |
| `CLOUDFRONT_DISTRIBUTION_ID_PROD` | E0987654321XYZ | ID da distribuição CloudFront (prod) |

### Passo 3: Adicionar Secrets GCP

| Secret Name | Valor | Descrição |
|-------------|-------|-----------|
| `GCP_SERVICE_ACCOUNT_KEY` | { "type": "service_account", ... } | JSON completo da service account |
| `GCP_PROJECT_ID` | n-agent-project | ID do projeto GCP |
| `GOOGLE_MAPS_API_KEY` | AIzaSy... | API Key do Google Maps (frontend) |
| `GOOGLE_MAPS_API_KEY_BACKEND` | AIzaSy... | API Key do Google Maps (backend) |

### Passo 4: Adicionar Secrets de Integrações

| Secret Name | Valor | Descrição |
|-------------|-------|-----------|
| `WHATSAPP_VERIFY_TOKEN` | random_string_here | Token para verificação do webhook |
| `WHATSAPP_ACCESS_TOKEN` | EAABsbCS... | Token de acesso do WhatsApp Business |
| `STRIPE_SECRET_KEY` | sk_test_... | Chave secreta do Stripe |
| `SNYK_TOKEN` | abc123... | Token do Snyk (security scan) |

### Passo 5: Verificar Secrets

```bash
# Listar secrets (via GitHub CLI)
gh secret list

# Testar workflow manualmente
gh workflow run deploy-dev.yml
```

---

## 🛡️ IAM Roles por Serviço (AWS)

### Lambda Execution Roles

Cada Lambda deve ter sua própria role com permissões mínimas:

#### WhatsApp Bot Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:*:table/n-agent-chat-*",
        "arn:aws:dynamodb:us-east-1:*:table/n-agent-core-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "events:PutEvents"
      ],
      "Resource": "arn:aws:events:us-east-1:*:event-bus/default"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:*:*"
    }
  ]
}
```

#### Trip Planner Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/n-agent-core-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::n-agent-documents-*/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel"
      ],
      "Resource": "arn:aws:bedrock:us-east-1::foundation-model/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:*:*"
    }
  ]
}
```

---

## ✅ Checklist de Segurança

- [ ] Access Keys criadas e armazenadas com segurança
- [ ] Políticas IAM seguem princípio do menor privilégio
- [ ] Secrets configurados no GitHub (não commitados)
- [ ] GCP Service Account com roles mínimas necessárias
- [ ] API Keys do Google Maps com restrições ativas
- [ ] Ambientes de dev e prod usam credenciais separadas
- [ ] Logs e auditoria habilitados (CloudTrail, Cloud Audit Logs)
- [ ] MFA habilitado para usuários com acesso ao Console
- [ ] Rotação de credenciais programada (90 dias)

---

## 🚀 Testando a Pipeline

```bash
# 1. Commit e push para develop (dispara deploy-dev)
git checkout develop
git add .
git commit -m "test: trigger dev pipeline"
git push origin develop

# 2. Verificar no GitHub Actions
# https://github.com/YOUR_ORG/n-agent-core/actions

# 3. Para produção, merge para main
git checkout main
git merge develop
git push origin main
```

---

## 📝 Próximos Passos

1. ✅ Configurar secrets no GitHub
2. ⏳ Criar ambiente de produção no Terraform
3. ⏳ Testar deploy em dev
4. ⏳ Configurar notificações (Slack/Discord)
5. ⏳ Adicionar testes automatizados

---

## 🆘 Troubleshooting

### Erro: "Access Denied" na pipeline

**Solução**: Verifique se o usuário IAM tem as políticas corretas anexadas.

```bash
aws iam list-attached-user-policies --user-name github-actions-n-agent
```

### Erro: "GCP authentication failed"

**Solução**: Verifique se o JSON da service account está correto no secret.

```bash
# Testar localmente
export GOOGLE_APPLICATION_CREDENTIALS="key.json"
gcloud auth application-default print-access-token
```

### Erro: "Terraform state locked"

**Solução**: Aguarde o término de outra pipeline ou force unlock.

```bash
cd infra/environments/dev
terraform force-unlock LOCK_ID
```

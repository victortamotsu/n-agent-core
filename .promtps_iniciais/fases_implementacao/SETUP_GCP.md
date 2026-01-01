# 🔧 Configuração Google Cloud Platform (GCP) - Gemini Integration

## Objetivo
Configurar acesso ao Google Gemini via Vertex AI para ter modelo alternativo/complementar ao AWS Bedrock.

## Pré-requisitos
- Conta Google Cloud ativa
- Cartão de crédito válido (para verificação)
- AWS CLI configurado (para armazenar credenciais)

---

## Passo 1: Criar Projeto no GCP

### 1.1 Acessar Console
1. Acesse: https://console.cloud.google.com/
2. Faça login com sua conta Google

### 1.2 Criar Novo Projeto
1. Clique no seletor de projetos (canto superior esquerdo)
2. Clique em **"NEW PROJECT"**
3. Configurações:
   - **Project name**: `n-agent-project`
   - **Project ID**: Será gerado automaticamente (ex: `n-agent-project-123456`)
   - **Location**: No organization (ou sua organização se tiver)
4. Clique em **"CREATE"**
5. Aguarde 10-20 segundos até o projeto ser criado

### 1.3 Anotar Project ID
⚠️ **IMPORTANTE**: Anote o **Project ID** (não o nome, mas o ID único)
- Exemplo: `n-agent-project-123456`

---

## Passo 2: Habilitar Vertex AI API

### 2.1 Acessar API Library
1. No menu lateral (☰), vá em **"APIs & Services"** → **"Library"**
2. Ou acesse diretamente: https://console.cloud.google.com/apis/library

### 2.2 Buscar e Habilitar Vertex AI
1. Na barra de busca, digite: **"Vertex AI API"**
2. Clique em **"Vertex AI API"**
3. Clique em **"ENABLE"**
4. Aguarde 1-2 minutos até a API ser habilitada

### 2.3 Verificar Habilitação
1. Vá em **"APIs & Services"** → **"Enabled APIs & services"**
2. Confirme que **"Vertex AI API"** está na lista

---

## Passo 3: Criar Service Account

### 3.1 Acessar IAM
1. No menu lateral (☰), vá em **"IAM & Admin"** → **"Service Accounts"**
2. Ou acesse: https://console.cloud.google.com/iam-admin/serviceaccounts

### 3.2 Criar Nova Service Account
1. Clique em **"+ CREATE SERVICE ACCOUNT"**
2. Preencha:
   - **Service account name**: `n-agent-service`
   - **Service account ID**: Será gerado automaticamente (`n-agent-service@...`)
   - **Description**: "Service account for n-agent Gemini integration"
3. Clique em **"CREATE AND CONTINUE"**

### 3.3 Conceder Permissões (Role)
1. Na seção **"Grant this service account access to project"**:
   - Clique em **"Select a role"**
   - Busque: **"Vertex AI User"**
   - Selecione: **"Vertex AI User"**
2. Clique em **"CONTINUE"**

### 3.4 Conceder Acesso (Opcional)
1. Seção **"Grant users access to this service account"** → **Skip** (não é necessário)
2. Clique em **"DONE"**

---

## Passo 4: Gerar Chave JSON

### 4.1 Acessar Service Account
1. Na lista de Service Accounts, clique em `n-agent-service@...`
2. Vá na aba **"KEYS"**

### 4.2 Criar Nova Chave
1. Clique em **"ADD KEY"** → **"Create new key"**
2. Selecione **"JSON"**
3. Clique em **"CREATE"**
4. O arquivo JSON será baixado automaticamente

⚠️ **SEGURANÇA**: 
- Este arquivo contém credenciais sensíveis
- Nunca commite no Git
- Guarde em local seguro

### 4.3 Renomear Arquivo
1. Renomeie o arquivo baixado para: `gcp-credentials.json`
2. Mova para um diretório seguro (ex: `C:\Users\victo\.aws\`)

---

## Passo 5: Armazenar no AWS Secrets Manager

### 5.1 Verificar Arquivo JSON
Abra o arquivo `gcp-credentials.json` e verifique que contém:
```json
{
  "type": "service_account",
  "project_id": "n-agent-project-123456",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "n-agent-service@...",
  "client_id": "...",
  ...
}
```

### 5.2 Criar Secret no AWS
Execute no PowerShell:

```powershell
# Navegar até o diretório onde está o arquivo
cd C:\Users\victo\.aws\

# Criar secret no AWS Secrets Manager
aws secretsmanager create-secret `
  --name n-agent/google-cloud-credentials `
  --description "Google Cloud Service Account for Gemini/Vertex AI" `
  --secret-string file://gcp-credentials.json `
  --region us-east-1
```

### 5.3 Verificar Secret Criado
```powershell
aws secretsmanager describe-secret `
  --secret-id n-agent/google-cloud-credentials `
  --region us-east-1
```

---

## Passo 6: Testar Acesso ao Gemini

### 6.1 Instalar Google Cloud SDK (Opcional)
Para testar localmente:

```powershell
# Instalar gcloud CLI
choco install gcloudsdk
```

### 6.2 Autenticar com Service Account
```bash
gcloud auth activate-service-account `
  --key-file="C:\Users\victo\.aws\gcp-credentials.json"

gcloud config set project n-agent-project-123456
```

### 6.3 Testar Vertex AI API
```bash
# Listar modelos disponíveis
gcloud ai models list --region=us-central1
```

---

## Passo 7: Configurar no Código Python

### 7.1 Adicionar Dependências
```bash
cd C:\Users\victo\Projetos\n-agent-core\agent
uv add google-cloud-aiplatform
```

### 7.2 Código de Teste (Python)
Crie arquivo `test_gemini.py`:

```python
import os
import json
import boto3
from google.oauth2 import service_account
from google.cloud import aiplatform

# 1. Buscar credenciais do Secrets Manager
secrets_client = boto3.client('secretsmanager', region_name='us-east-1')
response = secrets_client.get_secret_value(SecretId='n-agent/google-cloud-credentials')
credentials_json = json.loads(response['SecretString'])

# 2. Criar credenciais Google
credentials = service_account.Credentials.from_service_account_info(
    credentials_json,
    scopes=['https://www.googleapis.com/auth/cloud-platform']
)

# 3. Inicializar Vertex AI
aiplatform.init(
    project=credentials_json['project_id'],
    location='us-central1',
    credentials=credentials
)

# 4. Testar Gemini
from vertexai.generative_models import GenerativeModel

model = GenerativeModel("gemini-1.5-flash")
response = model.generate_content("Olá! Você está funcionando?")

print("✅ Gemini Response:")
print(response.text)
```

### 7.3 Executar Teste
```bash
uv run python test_gemini.py
```

---

## ✅ Checklist de Conclusão

- [ ] Projeto GCP criado (`n-agent-project`)
- [ ] Vertex AI API habilitada
- [ ] Service Account criada (`n-agent-service`)
- [ ] Role "Vertex AI User" atribuída
- [ ] Chave JSON gerada e baixada
- [ ] Arquivo renomeado para `gcp-credentials.json`
- [ ] Secret criado no AWS Secrets Manager
- [ ] Secret verificado via AWS CLI
- [ ] (Opcional) gcloud CLI instalado
- [ ] (Opcional) Teste Python executado com sucesso

---

## 📊 Custos Estimados

### Vertex AI (Gemini)
- **Gemini 1.5 Flash**: $0.075/1M tokens input, $0.30/1M tokens output
- **Gemini 1.5 Pro**: $1.25/1M tokens input, $5.00/1M tokens output

**Comparação com AWS Bedrock**:
- Gemini Flash é similar ao Nova Lite (preço competitivo)
- Gemini Pro é mais caro que Nova Pro

**Recomendação**: Usar Gemini apenas como fallback ou para casos específicos.

---

## 🔒 Segurança

### Boas Práticas Implementadas
✅ Credenciais armazenadas no AWS Secrets Manager (criptografadas)  
✅ Service Account com least-privilege (apenas Vertex AI User)  
✅ Arquivo JSON local mantido fora do Git (.gitignore)  
✅ Rotação de credenciais recomendada a cada 90 dias  

### Próximos Passos
- Na Fase 1: Implementar fallback para Gemini quando Bedrock falhar
- Na Fase 3: Comparar qualidade de respostas Gemini vs Nova/Claude

---

## 📚 Documentação de Referência

- [Vertex AI Quickstart](https://cloud.google.com/vertex-ai/docs/start/introduction-unified-platform)
- [Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Gemini API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/gemini)
- [Python Client Library](https://cloud.google.com/python/docs/reference/aiplatform/latest)

---

**Status**: 📝 Aguardando execução manual  
**Tempo Estimado**: 15-20 minutos  
**Próxima Fase**: Após conclusão, implementar código de integração no Router Agent

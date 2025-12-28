# Fase 0 - Preparação do Ambiente

## Objetivo
Preparar todo o ambiente AWS e ferramentas de desenvolvimento antes de iniciar a construção.

## Entradas
- Conta AWS ativa (944938120078)
- Usuário IAM com AdministratorAccess (victor-admin)
- Repositório Git limpo

## Saídas
- Acesso ao Bedrock habilitado
- AgentCore Starter Toolkit instalado
- Ambiente Python configurado
- Estrutura de pastas do projeto criada
- CI/CD básico configurado

---

## 🚨 Mudanças Arquiteturais Importantes

Esta fase foi atualizada para refletir decisões do arquivo [00_arquitetura.md](./00_arquitetura.md):

1. **Multi-Agente com Router**: Habilitamos **5 modelos** (não apenas 2):
   - ⚡ **Nova Micro** ($0.035/1M) - Router Agent para classificar queries
   - 💬 **Nova Lite** ($0.06/1M) - Chat Agent para queries triviais/informativas (60-85% das mensagens)
   - 🧠 **Nova Pro** ($0.80/1M) - Planning Agent para queries complexas
   - 👁️ **Claude 3 Haiku** ($0.25/1M) - Visão rápida
   - 📝 **Claude 3 Sonnet** ($3.00/1M) - OCR e documentos

2. **Economia com Multi-Agente**: Sistema roteia queries simples ("Oi", "Obrigado") para modelos baratos, economizando 10-100x em custos

3. **Prompt Caching**: Nova custom models têm cache **grátis** ($0 read/write), reduzindo custo em 99.6%

---

## Passo 1: Habilitar Modelos no Amazon Bedrock

### Ações Manuais (Console AWS)

1. Acesse o [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. No menu lateral, clique em **Model access**
3. Clique em **Modify model access**
4. Habilite os seguintes modelos:
   - ✅ **Amazon Nova Micro** (para Router Agent - $0.035/1M)
   - ✅ **Amazon Nova Lite** (para Chat Agent - $0.06/1M)
   - ✅ **Amazon Nova Pro** (para Planning Agent - $0.80/1M)
   - ✅ **Anthropic Claude 3 Haiku** (para Vision rápida - $0.25/1M)
   - ✅ **Anthropic Claude 3 Sonnet** (para OCR/Documentos - $3.00/1M)
5. Clique em **Save changes**
6. Aguarde a aprovação (geralmente instantânea para modelos Amazon)

> ⚠️ **Nota**: Modelos Anthropic podem levar até 24h para aprovação.

### Verificação
```bash
aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[?contains(modelId, 'claude') || contains(modelId, 'nova')].modelId"
```

---

## Passo 2: Configurar Acesso ao AgentCore

### Ações Manuais (Console AWS)

1. Acesse o [Amazon Bedrock AgentCore Console](https://console.aws.amazon.com/bedrock-agentcore/)
2. Se for o primeiro acesso:
   - Aceite os termos de serviço
   - O console criará automaticamente as roles necessárias
3. Verifique que você pode acessar:
   - Runtime
   - Memory
   - Gateway
   - Observability

### Verificação via CLI
```bash
aws bedrock-agentcore-control list-agent-runtimes --region us-east-1
```

---

## Passo 3: Instalar Ferramentas de Desenvolvimento

### Pré-requisitos
- Python 3.10+ instalado
- Git configurado
- AWS CLI v2 configurado com profile `default`

### Instalação do UV (Gerenciador de Pacotes Python)

```powershell
# Windows PowerShell
irm https://astral.sh/uv/install.ps1 | iex
```

### Verificação
```bash
uv --version
python --version
```

---

## Passo 4: Criar Estrutura do Projeto

### Estrutura de Pastas

```
/n-agent-core
│
├── /agent                     # Código do AgentCore Runtime
│   ├── /src
│   │   ├── main.py           # Entrypoint do agente
│   │   ├── /tools            # Definições de ferramentas
│   │   └── /prompts          # System prompts
│   ├── pyproject.toml
│   └── .bedrock_agentcore.yaml
│
├── /apps                      # Aplicações Frontend
│   ├── /web-client           # React + Vite
│   └── /admin-panel          # Painel administrativo
│
├── /packages                  # Bibliotecas compartilhadas
│   ├── /core-types           # Interfaces TypeScript
│   └── /ui-lib               # Componentes React
│
├── /lambdas                   # Funções Lambda auxiliares
│   ├── /doc-generator        # Gerador de documentos
│   ├── /whatsapp-webhook     # Handler WhatsApp
│   └── /bff                  # Backend for Frontend
│
├── /infra                     # Infrastructure as Code
│   └── /terraform
│       ├── /modules
│       └── /environments
│
├── /.promtps_iniciais         # Documentação de requisitos
│   ├── proposta_inicial.md
│   ├── proposta_técnica.md
│   └── /fases_implementacao
│
└── /.github
    └── /workflows            # CI/CD
```

### Comando para Criar Estrutura

```bash
# Criar diretórios
mkdir -p agent/src/tools agent/src/prompts
mkdir -p apps/web-client apps/admin-panel
mkdir -p packages/core-types packages/ui-lib
mkdir -p lambdas/doc-generator lambdas/whatsapp-webhook lambdas/bff
mkdir -p infra/terraform/modules infra/terraform/environments
mkdir -p .github/workflows
```

---

## Passo 5: Inicializar Projeto Python do Agente

### Comandos

```bash
cd agent

# Inicializar projeto com UV
uv init --python 3.13

# Adicionar dependências principais
uv add bedrock-agentcore strands-agents boto3

# Adicionar ferramentas de desenvolvimento
uv add --dev bedrock-agentcore-starter-toolkit pytest black ruff
```

### Arquivo pyproject.toml Esperado

```toml
[project]
name = "n-agent"
version = "0.1.0"
description = "Assistente pessoal de viagens"
requires-python = ">=3.10"
dependencies = [
    "bedrock-agentcore",
    "strands-agents",
    "boto3",
]

[tool.uv]
dev-dependencies = [
    "bedrock-agentcore-starter-toolkit",
    "pytest",
    "black",
    "ruff",
]
```

---

## Passo 6: Criar Agente Básico de Teste

### Arquivo: agent/src/main.py

```python
from bedrock_agentcore.runtime import App
from strands import Agent

app = App()

@app.entrypoint
def handle_request(event: dict) -> dict:
    """Entrypoint do agente n-agent."""
    
    prompt = event.get("prompt", "")
    session_id = event.get("session_id", "default")
    
    # Agente básico para teste
    agent = Agent(
        model="us.amazon.nova-lite-v1:0",
        system_prompt="""
        Você é o n-agent, um assistente pessoal de viagens.
        Seja simpático e prestativo.
        Por enquanto, apenas responda perguntas gerais sobre viagens.
        """
    )
    
    response = agent.run(prompt)
    
    return {
        "result": str(response),
        "session_id": session_id
    }
```

### Testar Localmente

```bash
cd agent

# Iniciar servidor local
agentcore dev

# Em outro terminal, testar
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Olá! Quero planejar uma viagem para a Europa."}'
```

---

## Passo 7: Configurar CI/CD Básico

### Arquivo: .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-agent:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install uv
        uses: astral-sh/setup-uv@v4
        
      - name: Set up Python
        run: uv python install 3.13
        
      - name: Install dependencies
        working-directory: ./agent
        run: uv sync --dev
        
      - name: Lint
        working-directory: ./agent
        run: |
          uv run ruff check .
          uv run black --check .
        
      - name: Test
        working-directory: ./agent
        run: uv run pytest -v
```

---

## Passo 8: Configurar Google Cloud (para Gemini)

### Ações Manuais

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto: `n-agent-project`
3. Habilite a **Vertex AI API**
4. Crie uma Service Account com role `Vertex AI User`
5. Gere uma chave JSON e salve em local seguro
6. Configure no AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name n-agent/google-cloud-credentials \
  --secret-string file://path/to/service-account.json \
  --region us-east-1
```

---

## Passo 9: Configurar Meta WhatsApp Business

### Ações Manuais

1. Acesse o [Meta for Developers](https://developers.facebook.com/)
2. Crie um novo App do tipo **Business**
3. Adicione o produto **WhatsApp**
4. Configure o **Webhook URL** (será preenchido na Fase 2)
5. Copie:
   - **Phone Number ID**
   - **WhatsApp Business Account ID**
   - **Access Token** (temporário para desenvolvimento)
6. Armazene no Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name n-agent/whatsapp-credentials \
  --secret-string '{"phone_number_id":"xxx","waba_id":"xxx","access_token":"xxx"}' \
  --region us-east-1
```

---

## Checklist de Conclusão

- [ ] Modelos Bedrock habilitados (Claude, Nova)
- [ ] Acesso ao AgentCore Console funcionando
- [ ] UV instalado e funcionando
- [ ] Estrutura de pastas criada
- [ ] Projeto Python inicializado
- [ ] Agente de teste respondendo localmente
- [ ] CI/CD configurado no GitHub
- [ ] Google Cloud configurado (opcional, pode deixar para depois)
- [ ] Meta WhatsApp configurado (opcional, pode deixar para depois)

---

## Próxima Fase

Com o ambiente preparado, siga para a **[Fase 1 - Fundação](./01_fundacao.md)** onde vamos:
- Deploy do primeiro agente no AgentCore Runtime
- Configurar AgentCore Memory
- Criar tabelas DynamoDB
- Configurar Cognito

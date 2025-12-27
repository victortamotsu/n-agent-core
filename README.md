# n-agent - Assistente Pessoal de Viagens

> Plataforma de agente de IA para planejamento e organização de viagens

## 📋 Sobre o Projeto

O n-agent é um assistente pessoal baseado em IA que ajuda usuários a planejar, organizar e executar viagens de forma inteligente, desde a fase de conhecimento até a criação de memórias.

## 🏗️ Arquitetura

Este é um monorepo gerenciado por **Turborepo** com a seguinte estrutura:

```
n-agent-monorepo/
├── apps/              # Aplicações principais
│   ├── web-client/    # Frontend React (Vite + Material UI)
│   ├── admin-panel/   # Painel administrativo
│   └── api-bff/       # Backend for Frontend
├── packages/          # Pacotes compartilhados
│   ├── core-types/    # TypeScript types
│   ├── utils/         # Utilidades compartilhadas
│   └── logger/        # Logger padronizado
├── services/          # Microsserviços Lambda
│   ├── whatsapp-bot/  # Webhook WhatsApp
│   ├── trip-planner/  # Lógica de viagens
│   └── integrations/  # APIs externas
└── infra/             # Infrastructure as Code (Terraform)
```

## 🚀 Quick Start

### Pré-requisitos

- Node.js >= 18.0.0
- pnpm >= 8.0.0
- AWS CLI configurado (para deploy)

### Instalação

```bash
# Instalar dependências
pnpm install

# Rodar em modo desenvolvimento
pnpm dev

# Build de todos os projetos
pnpm build

# Lint
pnpm lint

# Format
pnpm format
```

### Desenvolvimento Local

```bash
# Web client (React)
cd apps/web-client
pnpm dev
# Acesse http://localhost:3000

# API BFF
cd apps/api-bff
pnpm dev
# Acesse http://localhost:4000
```

## 🛠️ Stack Tecnológica

### Frontend
- React 18
- TypeScript
- Material UI (M3 Expressive)
- Vite
- React Router

### Backend
- Node.js
- TypeScript
- Express
- AWS Lambda
- AWS DynamoDB
- AWS S3

### IaC
- Terraform
- AWS (100% serverless)

### AI/ML
- Amazon Bedrock (Claude 3.5 Sonnet, AWS Nova)
- Google Gemini 2.0 Flash + Search Grounding

## 📦 Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `pnpm dev` | Inicia todos os apps em modo dev |
| `pnpm build` | Build de produção |
| `pnpm lint` | Roda ESLint em todo o monorepo |
| `pnpm format` | Formata código com Prettier |
| `pnpm clean` | Limpa node_modules e builds |

## 🌍 Ambientes

- **dev** - Desenvolvimento local
- **staging** - Homologação
- **prod** - Produção

## � CI/CD

### Pipelines do GitHub Actions

| Workflow | Trigger | Descrição |
|----------|---------|-----------|
| **CI** | PR/Push para `main` ou `develop` | Lint, testes, build |
| **Deploy Dev** | Push para `develop` | Deploy automático em DEV |
| **Deploy Prod** | Push para `main` ou tags `v*` | Deploy em PRODUÇÃO |

### Configurar Credenciais

Para configurar as credenciais AWS e GCP para as pipelines:

➡️ **[Guia Rápido de Credenciais](./docs/QUICKSTART_CREDENTIALS.md)** (5 minutos)  
➡️ **[Guia Completo](./docs/SETUP_CREDENTIALS.md)** (documentação detalhada)  
➡️ **[Boas Práticas de Ambientes](./docs/BOAS_PRATICAS_AMBIENTES.md)** (separação dev/prod)

**Secrets necessários (com sufixos!):**
- `AWS_ACCESS_KEY_ID_DEV` / `AWS_ACCESS_KEY_ID_PROD`
- `AWS_SECRET_ACCESS_KEY_DEV` / `AWS_SECRET_ACCESS_KEY_PROD`
- `SNYK_TOKEN` (scanner de segurança)
- `GCP_SERVICE_ACCOUNT_KEY` (Semana 8+)
- `GOOGLE_MAPS_API_KEY_DEV` / `GOOGLE_MAPS_API_KEY_PROD` (Semana 8+)

## 📚 Documentação

- [Proposta Inicial](./promtps/proposta_inicial.md)
- [Proposta Técnica](./promtps/proposta_técnica.md)
- [Plano de Implementação](./promtps/fases_implementacao/)
- [Quick Start - Credenciais](./docs/QUICKSTART_CREDENTIALS.md) ⚡
- [Setup Completo de Credenciais](./docs/SETUP_CREDENTIALS.md)
- [Boas Práticas de Ambientes](./docs/BOAS_PRATICAS_AMBIENTES.md) 🏗️
- [Pipelines - Setup Completo](./docs/PIPELINES_SETUP_COMPLETO.md)

## 🤝 Fase Atual

**Fase 1 - Fundação (Semana 1)** ✅ **COMPLETA**

- [x] Setup do monorepo
- [x] Configuração de TypeScript, ESLint e Prettier
- [x] Estrutura de apps, packages e services
- [x] Infraestrutura base (Terraform)
- [x] CI/CD com GitHub Actions
- [x] Deploy automático em AWS
- [x] Recursos AWS criados (DynamoDB, S3, IAM)

## 📝 Licença

Proprietary - Todos os direitos reservados

---

Desenvolvido com ❤️ para viajantes

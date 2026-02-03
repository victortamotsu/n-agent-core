# n-agent - Repositório Limpo

Este repositório foi completamente limpo em **03 de fevereiro de 2026**.

## 📁 Conteúdo Atual

O repositório contém apenas os documentos de proposta inicial:

- `.promtps_iniciais/proposta_inicial.md` - Proposta de produto e negócio
- `.promtps_iniciais/proposta_técnica.md` - Proposta de arquitetura técnica

## 🧹 Limpeza Realizada

### Recursos AWS Removidos

✅ **36 recursos gerenciados via Terraform**:
- API Gateway HTTP API
- Amazon Cognito User Pool + Identity Providers (Google, Microsoft)
- AWS Lambda Functions (BFF, WhatsApp Webhook)
- CloudWatch Log Groups
- IAM Roles e Policies
- Secrets Manager Secrets
- SNS Topics

✅ **Recursos não-gerenciados removidos**:
- DynamoDB: `n-agent-profiles`, `n-agent-terraform-locks` (deletadas)
- CloudWatch Logs: `/aws/bedrock-agentcore/runtimes/*`, `/aws/codebuild/*` (deletados)

✅ **Custos AWS em Janeiro 2026**: **$0.00**

### ⚠️ Recurso Remanescente (Não Gera Custo)

- **S3 Bucket**: `n-agent-terraform-state` (bucket do Terraform State com versionamento)
  - **Custo**: ~$0.00/mês (bucket vazio com apenas versões históricas)
  - **Ação requerida**: Pode ser removido manualmente via AWS Console se desejado

### Arquivos Locais Removidos

Todos os arquivos de código, configurações e documentação foram removidos:
- `/agent` - Python AgentCore agent
- `/apps` - React frontends
- `/infra` - Terraform IaC
- `/lambdas` - Lambda functions
- `/scripts` - Scripts de automação
- `/docs` - Documentação técnica
- Arquivos de configuração na raiz

## 🔄 Próximos Passos

Para reiniciar o projeto do zero:

1. Revisar as propostas em `.promtps_iniciais/`
2. Definir novo escopo técnico
3. Recriar estrutura de pastas conforme necessidade
4. Provisionar nova infraestrutura AWS

---

**Última limpeza**: 03 de fevereiro de 2026  
**Status AWS**: Limpo (custos: $0.00)  
**Status Git**: Mantido (histórico preservado)

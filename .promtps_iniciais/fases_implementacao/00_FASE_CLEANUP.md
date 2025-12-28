# 🧹 Fase 0 - Cleanup do Ambiente AWS

## Visão Geral

Este documento descreve o processo de limpeza do ambiente AWS antes da migração para Bedrock AgentCore.

## Recursos a Serem Removidos

### 🔴 Remover Completamente

| Recurso | Motivo | Arquivo |
|---------|--------|---------|
| `aws_bedrockagent_agent.n_agent` | Substituído por AgentCore Runtime | bedrock.tf |
| `aws_bedrockagent_agent_alias.prod` | Não necessário com AgentCore | bedrock.tf |
| `aws_bedrockagent_agent_action_group.trip_management` | Tools serão nativos no AgentCore | bedrock.tf |
| `aws_iam_role.bedrock_agent_role` | Política específica para Bedrock Agents | bedrock.tf |
| `aws_iam_role_policy.bedrock_agent_permissions` | Não necessário | bedrock.tf |
| `aws_iam_role.action_groups_role` | Lambda não mais necessária | bedrock.tf |
| `aws_iam_role_policy.action_groups_dynamodb` | Não necessário | bedrock.tf |
| `aws_iam_role_policy_attachment.action_groups_logs` | Não necessário | bedrock.tf |
| `aws_lambda_permission.bedrock_action_groups` | Não necessário | bedrock.tf |
| `aws_iam_role.ai_orchestrator_role` | Lambda não mais necessária | bedrock.tf |
| `aws_iam_role_policy.ai_orchestrator_bedrock` | Não necessário | bedrock.tf |
| `aws_iam_role_policy.ai_orchestrator_dynamodb` | Não necessário | bedrock.tf |
| `aws_iam_role_policy_attachment.ai_orchestrator_logs` | Não necessário | bedrock.tf |
| `aws_ssm_parameter.bedrock_agent_id` | Não necessário | bedrock.tf |
| `aws_ssm_parameter.bedrock_agent_alias_id` | Não necessário | bedrock.tf |
| `aws_lambda_function.action_groups` | Substituído por AgentCore Tools | resources.tf |
| `aws_lambda_function.ai_orchestrator` | Substituído por AgentCore Runtime | resources.tf |
| `aws_cloudwatch_log_group.action_groups` | Lambda removida | resources.tf |
| `aws_cloudwatch_log_group.ai_orchestrator` | Lambda removida | resources.tf |

### 🟡 Manter (Serão Reutilizados)

| Recurso | Motivo | Arquivo |
|---------|--------|---------|
| `aws_dynamodb_table.n_agent_core` | **MANTER** - Dados de usuários e viagens | resources.tf |
| `aws_dynamodb_table.n_agent_chat` | **MANTER** - Backup de histórico | resources.tf |
| `aws_cognito_user_pool.main` | **MANTER** - Autenticação | resources.tf |
| `aws_cognito_user_pool_client.web_client` | **MANTER** - Frontend | resources.tf |
| `aws_s3_bucket.documents` | **MANTER** - PDFs e docs | resources.tf |
| `aws_s3_bucket.assets` | **MANTER** - Assets | resources.tf |
| `aws_s3_bucket.web` | **MANTER** - Frontend | resources.tf |
| `aws_lambda_function.whatsapp_bot` | **MANTER** - Webhook WhatsApp | resources.tf |
| `aws_lambda_function.auth` | **MANTER** - Auth endpoints | resources.tf |
| `aws_lambda_function.authorizer` | **MANTER** - API Gateway | resources.tf |
| `aws_apigatewayv2_api.main` | **MANTER** - API principal | resources.tf |
| IAM roles para lambdas mantidas | **MANTER** - Necessário | iam.tf |

### 🟠 Avaliar (Podem ser removidos depois)

| Recurso | Decisão | Arquivo |
|---------|---------|---------|
| `aws_lambda_function.trip_planner` | Avaliar após AgentCore | resources.tf |
| `aws_lambda_function.integrations` | Avaliar após AgentCore | resources.tf |

---

## Processo de Cleanup

### Passo 1: Backup de Estado

```bash
# Fazer backup do estado atual do Terraform
cd infra/environments/prod
terraform state pull > terraform-state-backup-$(date +%Y%m%d).json
```

### Passo 2: Remover Recursos via Terraform

Os arquivos Terraform serão atualizados para remover os recursos. O `terraform apply` vai destruir apenas os recursos removidos.

### Passo 3: Verificar Remoção

```bash
# Verificar que recursos foram removidos
aws bedrock-agent list-agents --region us-east-1
aws lambda list-functions --query "Functions[?contains(FunctionName, 'action-groups') || contains(FunctionName, 'ai-orchestrator')]"
```

---

## Ordem de Remoção (Dependências)

A ordem é importante devido às dependências entre recursos:

```
1. aws_bedrockagent_agent_action_group (depende do agent)
2. aws_lambda_permission (depende do agent e lambda)
3. aws_bedrockagent_agent_alias (depende do agent)
4. aws_bedrockagent_agent (principal)
5. aws_ssm_parameter (dependem do agent)
6. aws_lambda_function (action_groups, ai_orchestrator)
7. aws_cloudwatch_log_group (dependem das lambdas)
8. aws_iam_role_policy (dependem das roles)
9. aws_iam_role_policy_attachment (dependem das roles)
10. aws_iam_role (por último)
```

---

## Checklist de Cleanup

- [ ] Backup do estado Terraform
- [ ] Remover bedrock.tf completamente
- [ ] Remover lambdas action_groups e ai_orchestrator de resources.tf
- [ ] Remover log groups de resources.tf
- [ ] Remover outputs relacionados de outputs.tf
- [ ] Executar `terraform plan` para verificar
- [ ] Executar `terraform apply` para aplicar
- [ ] Verificar no console AWS que recursos foram removidos
- [ ] Remover código fonte dos services não utilizados

---

## Código Fonte a Remover

Após a limpeza da infra, remover do repositório:

```
services/
  action-groups/       # Remover completamente
  ai-orchestrator/     # Remover completamente (será reescrito em Python)
```

---

## Estimativa de Economia

| Recurso | Custo Atual | Após Cleanup |
|---------|-------------|--------------|
| Lambda action-groups | ~$2/mês | $0 |
| Lambda ai-orchestrator | ~$3/mês | $0 |
| CloudWatch Logs | ~$1/mês | $0 |
| SSM Parameters | ~$0.10/mês | $0 |
| **Total** | **~$6/mês** | **$0** |

> **Nota**: A maior economia virá da simplificação da arquitetura, não do custo direto dos recursos.

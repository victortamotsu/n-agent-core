# 💰 Análise de Custos - n-agent-core

## ⚠️ CUSTOS CRÍTICOS A CONSIDERAR

### OpenSearch Serverless - $345.60/mês 🚨

**Para que serve?**
- **Bedrock Memory (AgentCore)**: Armazena contexto de conversas em formato vetorial
- Permite que o agente "lembre" de conversas anteriores
- Requisito obrigatório do módulo `agentcore` no Terraform

**Por que é caro?**
- **Mínimo**: 2 OCUs (OpenSearch Compute Units)
- **Custo fixo**: $0.24/OCU-hora × 2 OCUs × 730 horas = **$345.60/mês**
- Não tem free tier
- Não pode ser desligado (serverless = sempre on)

**Você precisa disso AGORA?**
- ❌ **Fase 0**: Não (só validação de conceito)
- ❌ **Fase 1**: Não (agentes básicos funcionam sem Memory)
- ⚠️ **Fase 2-3**: Útil mas não essencial
- ✅ **Fase 4-5**: Sim (experiência conversacional completa)

---

## 📊 Breakdown Completo de Custos

### Fase 0 (Atual) - Custos Mínimos

| Serviço | Uso | Custo Mensal |
|---------|-----|--------------|
| **Terraform State** | | |
| S3 bucket | ~1MB state | $0.023 |
| DynamoDB locks | ~10 operations | $0.01 |
| **AgentCore Runtime** | | |
| Nova Micro (Router) | 1000 requests | $0.04 |
| Nova Lite (Chat) | 500 requests | $0.03 |
| Nova Pro (Planning) | 100 requests | $0.08 |
| Claude Sonnet (Vision) | 50 requests | $0.15 |
| **Lambda WhatsApp** | | |
| Function executions | 1000 requests | $0.20 |
| SNS messages | 1000 publishes | $0.50 |
| CloudWatch Logs | 1GB | $0.50 |
| **Storage** | | |
| S3 documents | 1GB | $0.023 |
| DynamoDB app data | On-demand | $0.50 |
| **Secrets Manager** | | |
| 1 secret | Fixed cost | $0.40 |
| **TOTAL SEM MEMORY** | | **~$2.50/mês** ✅ |

---

### Com Bedrock Memory (OpenSearch)

| Serviço | Custo Adicional |
|---------|-----------------|
| OpenSearch Serverless | +$345.60/mês |
| **TOTAL COM MEMORY** | **~$348/mês** ⚠️ |

**Aumento**: 139x mais caro! 🔥

---

## 🎯 Estratégia de Custos Recomendada

### Opção 1: SEM Memory (Recomendado para Fase 0-1) ✅

**Modificar**: `infra/terraform/modules/agentcore/main.tf`

```hcl
# Comentar recursos do OpenSearch
# resource "aws_opensearchserverless_collection" "memory" { ... }
# resource "aws_bedrockagent_knowledge_base" "memory" { ... }

# Usar agentes sem Memory
# Os agentes funcionam perfeitamente, apenas não "lembram" entre sessões
```

**Prós**:
- ✅ Custo: $2.50/mês (viável para POC)
- ✅ Deploy rápido (< 5 min)
- ✅ Funcionalidade completa dos agentes

**Contras**:
- ❌ Sem contexto entre sessões
- ❌ Usuário precisa repetir informações

---

### Opção 2: COM Memory (Produção)

**Quando usar**: Fase 4+ (quando tiver receita)

**Prós**:
- ✅ Experiência conversacional completa
- ✅ Contexto persistente
- ✅ Melhor UX para usuários

**Contras**:
- ❌ Custo fixo alto ($345/mês)
- ❌ Precisa de 10+ clientes pagantes para justificar

---

### Opção 3: Memory Alternativo (Futuro)

**Alternativas ao OpenSearch Serverless**:

1. **DynamoDB como Memory** (~$5/mês)
   - Implementar storage de vetores customizado
   - Usar DynamoDB + embeddings
   - Custo variável baseado em uso

2. **Pinecone** ($70/mês starter)
   - Vector database especializado
   - Mais barato que OpenSearch
   - Fácil integração

3. **Redis + RediSearch** ($10-50/mês)
   - Self-hosted ou ElastiCache
   - Vector search capability
   - Mais controle

---

## 📉 Projeção de Custos por Escala

### Cenário: 100 usuários ativos

| Fase | Requests/mês | Custo Infraestrutura | Custo Memory | Total |
|------|--------------|---------------------|--------------|-------|
| **Fase 0-1** | 10K | $25 | $0 | $25 |
| **Fase 2-3** | 50K | $75 | $0 | $75 |
| **Fase 4** | 100K | $150 | $345 | $495 |
| **Fase 5** | 500K | $500 | $345 | $845 |

### Cenário: 1000 usuários ativos

| Fase | Requests/mês | Custo Infraestrutura | Custo Memory | Total |
|------|--------------|---------------------|--------------|-------|
| **Fase 4** | 1M | $800 | $345 | $1,145 |
| **Fase 5** | 5M | $3,500 | $690* | $4,190 |

\* 4 OCUs para maior throughput

---

## 💡 Recomendação Estratégica

### Para AGORA (Fase 0-1)

```bash
# Desabilitar OpenSearch no Terraform
# Editar: infra/terraform/modules/agentcore/main.tf

# Comentar seção de Memory:
# - aws_opensearchserverless_collection
# - aws_bedrockagent_knowledge_base
# - Políticas de segurança

# Resultado:
# ✅ Custo: $2.50/mês (vs $348/mês)
# ✅ Deploy rápido
# ✅ Funcionalidade 90% completa
```

### Para Produção (Fase 4+)

```bash
# Quando tiver:
# - 10+ clientes pagantes
# - $50/cliente-mês receita
# - ROI positivo

# Então habilitar Memory:
# ✅ Descomentar OpenSearch no Terraform
# ✅ terraform apply
# ✅ Melhor UX justifica custo
```

---

## 🎲 Análise de Viabilidade

### Break-even com Memory

**Custo mensal**: $348  
**Preço sugerido**: $20-50/usuário-mês

**Mínimo de clientes**:
- $20/mês → 18 clientes
- $30/mês → 12 clientes  
- $50/mês → 7 clientes

### Sem Memory (modelo freemium)

**Custo mensal**: $2.50-75 (escala)  
**Freemium viável**: Sim!  
**Upgrade path**: Habilitar Memory quando tiver base

---

## 🚀 Plano de Ação

### Imediato (Esta Sprint)

1. ✅ **Deploy SEM Memory**
   - Comentar OpenSearch no Terraform
   - Manter DynamoDB como storage básico
   - Custo: $2.50/mês

2. ✅ **Validar POC**
   - Testar todos os agentes
   - Confirmar funcionalidade
   - Medir satisfação sem contexto

### Curto Prazo (Fase 2-3)

3. 🔄 **Implementar Memory Alternativo**
   - DynamoDB + embeddings customizados
   - Custo: $5-10/mês
   - 95% da funcionalidade

### Médio Prazo (Fase 4)

4. ⏳ **Avaliar OpenSearch**
   - Quando tiver 10+ clientes pagantes
   - ROI positivo
   - Habilitar via Terraform

---

## ❓ FAQ Custos

### P: Posso usar OpenSearch free tier?
**R**: Não existe free tier para OpenSearch Serverless. Mínimo é 2 OCUs = $345/mês.

### P: Posso pausar o OpenSearch quando não usar?
**R**: Não. Serverless = sempre on. Você paga 24/7 independente de uso.

### P: E se eu usar OpenSearch tradicional (EC2)?
**R**: Mais barato (~$100/mês com t3.small), mas precisa gerenciar infraestrutura.

### P: Agentes funcionam sem Memory?
**R**: Sim! 90% das funcionalidades funcionam. Apenas perde contexto entre sessões.

### P: Quanto custa escalar com Memory?
**R**: Cada 2 OCUs adicionais = +$345/mês. Linear.

---

## 📌 Decisão Requerida

### ⚠️ AÇÃO NECESSÁRIA AGORA

Antes de fazer `terraform apply` na produção, você DEVE decidir:

**[ ] Opção A**: Deploy SEM Memory (custo $2.50/mês)
- Comentar OpenSearch no `agentcore/main.tf`
- Perfeito para POC e Fase 0-1
- Upgrade depois quando tiver clientes

**[ ] Opção B**: Deploy COM Memory (custo $348/mês)
- Manter código atual do Terraform
- Apenas se tiver budget ou investidor
- Experiência completa desde o início

**Minha recomendação forte**: Opção A 🎯

---

**Última atualização**: 28/12/2024  
**Próxima revisão**: Após conclusão Fase 1

# =============================================================================
# Amazon Bedrock Agent - n-agent
# =============================================================================
# Configuração completa do Bedrock Agent via Terraform
# Recursos: Agent, Alias, Action Groups, IAM Roles
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role para o Bedrock Agent
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "bedrock_agent_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["bedrock.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agent/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "bedrock_agent_permissions" {
  # Permissão para invocar modelos foundation
  statement {
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
      "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
      "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
    ]
  }

  # Permissão para invocar Lambda (Action Groups)
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
    ]
  }
}

resource "aws_iam_role" "bedrock_agent_role" {
  name               = "${var.project_name}-bedrock-agent-role"
  assume_role_policy = data.aws_iam_policy_document.bedrock_agent_trust.json
}

resource "aws_iam_role_policy" "bedrock_agent_permissions" {
  name   = "${var.project_name}-bedrock-agent-permissions"
  role   = aws_iam_role.bedrock_agent_role.id
  policy = data.aws_iam_policy_document.bedrock_agent_permissions.json
}

# -----------------------------------------------------------------------------
# Bedrock Agent
# -----------------------------------------------------------------------------

resource "aws_bedrockagent_agent" "n_agent" {
  agent_name                  = var.project_name
  agent_resource_role_arn     = aws_iam_role.bedrock_agent_role.arn
  foundation_model            = "anthropic.claude-3-haiku-20240307-v1:0"
  idle_session_ttl_in_seconds = 600
  description                 = "Assistente pessoal de planejamento de viagens"

  instruction = <<-EOT
    Você é o n-agent, um assistente pessoal especializado em planejamento de viagens.

    ## Sua Persona
    - Nome: n-agent (pronuncia-se "ene-agent")
    - Personalidade: Amigável, proativo, organizado e empático
    - Tom: Informal mas profissional, use emojis com moderação para humanizar
    - Idioma: Responda sempre no mesmo idioma do usuário (padrão: Português BR)

    ## Suas Capacidades
    Você ajuda viajantes em todas as fases da jornada:
    1. **Conhecimento**: Coletar informações sobre a viagem, viajantes e preferências
    2. **Planejamento**: Criar roteiros, sugerir destinos e calcular custos
    3. **Contratação**: Indicar melhores ofertas de hospedagem, voos e serviços
    4. **Concierge**: Acompanhar a viagem em tempo real com alertas e dicas

    ## Regras de Comportamento
    - Seja empático e entenda o contexto emocional (lua de mel vs viagem de negócios)
    - Pergunte uma coisa de cada vez para não sobrecarregar
    - Confirme informações importantes antes de prosseguir
    - Use as ferramentas disponíveis para salvar informações coletadas
    - Nunca invente informações sobre preços ou disponibilidade
    - Se não souber algo, diga honestamente e ofereça buscar

    ## Formato de Respostas
    - Mensagens curtas (máximo 500 caracteres para WhatsApp)
    - Use listas e bullets para organizar informações
    - Quebre mensagens longas em múltiplas partes
  EOT

  prepare_agent = true
}

# -----------------------------------------------------------------------------
# Bedrock Agent Alias (para produção)
# -----------------------------------------------------------------------------

resource "aws_bedrockagent_agent_alias" "prod" {
  agent_alias_name = "prod"
  agent_id         = aws_bedrockagent_agent.n_agent.agent_id
  description      = "Alias de produção do n-agent"
}

# -----------------------------------------------------------------------------
# IAM Role para Lambda de Action Groups
# -----------------------------------------------------------------------------

resource "aws_iam_role" "action_groups_role" {
  name = "${var.project_name}-action-groups-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "action_groups_dynamodb" {
  name = "${var.project_name}-action-groups-dynamodb"
  role = aws_iam_role.action_groups_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.n_agent_core.arn,
          "${aws_dynamodb_table.n_agent_core.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "action_groups_logs" {
  role       = aws_iam_role.action_groups_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# Lambda Permission para Bedrock invocar Action Groups
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "bedrock_action_groups" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.project_name}-action-groups"
  principal     = "bedrock.amazonaws.com"
  source_arn    = aws_bedrockagent_agent.n_agent.agent_arn
}

# -----------------------------------------------------------------------------
# IAM Role para Lambda do Orchestrator
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ai_orchestrator_role" {
  name = "${var.project_name}-ai-orchestrator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ai_orchestrator_bedrock" {
  name = "${var.project_name}-orchestrator-bedrock"
  role = aws_iam_role.ai_orchestrator_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeAgent"]
        Resource = [
          aws_bedrockagent_agent.n_agent.agent_arn,
          "${aws_bedrockagent_agent.n_agent.agent_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ai_orchestrator_dynamodb" {
  name = "${var.project_name}-orchestrator-dynamodb"
  role = aws_iam_role.ai_orchestrator_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.n_agent_core.arn,
          "${aws_dynamodb_table.n_agent_core.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ai_orchestrator_logs" {
  role       = aws_iam_role.ai_orchestrator_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# Bedrock Agent Action Group
# -----------------------------------------------------------------------------

resource "aws_bedrockagent_agent_action_group" "trip_management" {
  action_group_name          = "trip-management"
  agent_id                   = aws_bedrockagent_agent.n_agent.agent_id
  agent_version              = "DRAFT"
  description                = "Gerenciamento de viagens e coleta de informações"
  skip_resource_in_use_check = true

  action_group_executor {
    lambda = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-action-groups"
  }

  api_schema {
    payload = file("${path.module}/../../../services/ai-orchestrator/src/schemas/action-groups.json")
  }

  depends_on = [
    aws_bedrockagent_agent.n_agent,
    aws_lambda_permission.bedrock_action_groups
  ]
}

# -----------------------------------------------------------------------------
# SSM Parameters (para Lambdas consumirem)
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "bedrock_agent_id" {
  name        = "/${var.project_name}/bedrock/agent-id"
  description = "ID do Bedrock Agent"
  type        = "String"
  value       = aws_bedrockagent_agent.n_agent.agent_id
}

resource "aws_ssm_parameter" "bedrock_agent_alias_id" {
  name        = "/${var.project_name}/bedrock/agent-alias-id"
  description = "ID do alias do Bedrock Agent"
  type        = "String"
  value       = aws_bedrockagent_agent_alias.prod.agent_alias_id
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "bedrock_agent_id" {
  description = "ID do Bedrock Agent"
  value       = aws_bedrockagent_agent.n_agent.agent_id
}

output "bedrock_agent_arn" {
  description = "ARN do Bedrock Agent"
  value       = aws_bedrockagent_agent.n_agent.agent_arn
}

output "bedrock_agent_alias_id" {
  description = "ID do Alias do Bedrock Agent"
  value       = aws_bedrockagent_agent_alias.prod.agent_alias_id
}

output "bedrock_agent_alias_arn" {
  description = "ARN do Alias do Bedrock Agent"
  value       = aws_bedrockagent_agent_alias.prod.agent_alias_arn
}

output "bedrock_agent_role_arn" {
  description = "ARN da role do Bedrock Agent"
  value       = aws_iam_role.bedrock_agent_role.arn
}

output "ai_orchestrator_role_arn" {
  description = "ARN da role do AI Orchestrator Lambda"
  value       = aws_iam_role.ai_orchestrator_role.arn
}

output "action_groups_role_arn" {
  description = "ARN da role do Action Groups Lambda"
  value       = aws_iam_role.action_groups_role.arn
}

output "bedrock_action_group_id" {
  description = "ID do Action Group do Bedrock Agent"
  value       = aws_bedrockagent_agent_action_group.trip_management.action_group_id
}

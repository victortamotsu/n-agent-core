#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script de Cleanup - Fase 0 da Migração para Bedrock AgentCore

.DESCRIPTION
    Remove recursos AWS não mais necessários antes da migração para AgentCore.
    
.NOTES
    Execute este script a partir da raiz do projeto.
    Certifique-se de ter o Terraform e AWS CLI configurados.
#>

param(
    [switch]$DryRun = $false,
    [switch]$SkipBackup = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Cores para output
function Write-Step { param($msg) Write-Host "🔹 $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Danger { param($msg) Write-Host "🔴 $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  🧹 n-agent Cleanup - Fase 0 (Preparação para AgentCore)" -ForegroundColor Magenta  
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

$infraPath = "infra/environments/prod"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# ============================================================================
# Passo 1: Backup do Estado Terraform
# ============================================================================
if (-not $SkipBackup) {
    Write-Step "Fazendo backup do estado Terraform..."
    
    $backupDir = "infra/backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    $backupFile = "$backupDir/terraform-state-$timestamp.json"
    
    Push-Location $infraPath
    try {
        terraform state pull > "../../../$backupFile"
        Write-Success "Backup salvo em: $backupFile"
    }
    catch {
        Write-Warning "Não foi possível fazer backup do estado (pode não existir ainda)"
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# Passo 2: Confirmar Ação
# ============================================================================
if (-not $Force) {
    Write-Host ""
    Write-Danger "ATENÇÃO: Este script vai remover os seguintes recursos da AWS:"
    Write-Host ""
    Write-Host "  Bedrock Agents:" -ForegroundColor Yellow
    Write-Host "    - Agent 'n-agent' e seu alias 'prod'"
    Write-Host "    - Action Group 'trip-management'"
    Write-Host ""
    Write-Host "  Lambda Functions:" -ForegroundColor Yellow
    Write-Host "    - n-agent-action-groups"
    Write-Host "    - n-agent-ai-orchestrator"
    Write-Host ""
    Write-Host "  IAM Roles:" -ForegroundColor Yellow
    Write-Host "    - n-agent-bedrock-agent-role"
    Write-Host "    - n-agent-action-groups-role"
    Write-Host "    - n-agent-ai-orchestrator-role"
    Write-Host ""
    Write-Host "  Outros:" -ForegroundColor Yellow
    Write-Host "    - SSM Parameters (agent-id, agent-alias-id)"
    Write-Host "    - CloudWatch Log Groups (action-groups, ai-orchestrator)"
    Write-Host ""
    
    $confirm = Read-Host "Deseja continuar? (digite 'SIM' para confirmar)"
    if ($confirm -ne "SIM") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        exit 0
    }
}

# ============================================================================
# Passo 3: Renomear/Remover arquivos Terraform
# ============================================================================
Write-Step "Atualizando arquivos Terraform..."

$bedrockFile = "$infraPath/bedrock.tf"
$bedrockDisabled = "$infraPath/bedrock.tf.disabled"

if (Test-Path $bedrockFile) {
    if (Test-Path $bedrockDisabled) {
        Remove-Item $bedrockDisabled -Force
    }
    
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Renomearia $bedrockFile -> $bedrockDisabled"
    } else {
        Move-Item $bedrockFile $bedrockDisabled -Force
        Write-Success "Arquivo bedrock.tf desabilitado"
    }
}

# ============================================================================
# Passo 4: Criar arquivo de exclusão temporário
# ============================================================================
Write-Step "Criando arquivo de recursos removidos..."

$removedResourcesFile = "$infraPath/removed_resources.tf"
$removedContent = @"
# =============================================================================
# RECURSOS REMOVIDOS - Fase 0 Cleanup
# =============================================================================
# Este arquivo documenta os recursos que foram removidos do Terraform
# e serão destruídos no próximo 'terraform apply'
#
# Data: $timestamp
# Motivo: Migração para Amazon Bedrock AgentCore
# =============================================================================

# Recursos do bedrock.tf foram movidos para bedrock.tf.disabled
# Recursos abaixo de resources.tf serão comentados/removidos:

# - aws_lambda_function.action_groups
# - aws_lambda_function.ai_orchestrator
# - aws_cloudwatch_log_group.action_groups
# - aws_cloudwatch_log_group.ai_orchestrator

# Para completar a remoção, execute:
# 1. terraform plan -out=cleanup.tfplan
# 2. terraform apply cleanup.tfplan
"@

if (-not $DryRun) {
    Set-Content -Path $removedResourcesFile -Value $removedContent
    Write-Success "Arquivo de documentação criado: $removedResourcesFile"
}

# ============================================================================
# Passo 5: Instruções para terraform apply
# ============================================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  📋 Próximos Passos" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "  [DRY-RUN] Nenhuma alteração foi feita." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Execute novamente sem -DryRun para aplicar as mudanças." -ForegroundColor Yellow
} else {
    Write-Host "  1. Revise as mudanças nos arquivos Terraform:" -ForegroundColor White
    Write-Host "     - $infraPath/bedrock.tf.disabled (antigo bedrock.tf)"
    Write-Host ""
    Write-Host "  2. Execute o Terraform para ver o plano:" -ForegroundColor White
    Write-Host "     cd $infraPath" -ForegroundColor Cyan
    Write-Host "     terraform plan -out=cleanup.tfplan" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Aplique as mudanças (DESTRUTIVO!):" -ForegroundColor White
    Write-Host "     terraform apply cleanup.tfplan" -ForegroundColor Red
    Write-Host ""
    Write-Host "  4. Após confirmar que tudo foi removido, delete os arquivos:" -ForegroundColor White
    Write-Host "     rm bedrock.tf.disabled" -ForegroundColor Cyan
    Write-Host "     rm removed_resources.tf" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  5. Remova o código fonte não utilizado:" -ForegroundColor White
    Write-Host "     rm -rf services/action-groups" -ForegroundColor Cyan
    Write-Host "     rm -rf services/ai-orchestrator" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Cleanup preparado! Revise antes de aplicar." -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

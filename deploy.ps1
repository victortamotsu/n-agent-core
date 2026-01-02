#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy manual do n-agent para AgentCore Runtime via WSL 2

.DESCRIPTION
    Executa deploy do agent para AWS Bedrock AgentCore Runtime usando WSL 2.
    Valida ambiente, executa testes e realiza deploy.

.PARAMETER SkipTests
    Pula execução dos testes antes do deploy

.PARAMETER SkipValidation
    Pula validação de dependências (uv, AWS CLI)

.EXAMPLE
    .\deploy.ps1
    Deploy completo com testes e validação

.EXAMPLE
    .\deploy.ps1 -SkipTests
    Deploy sem executar testes (use apenas se já testou localmente)
#>

param(
    [switch]$SkipTests,
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 n-agent Deploy Manual" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se WSL está disponível
Write-Host "📋 Verificando WSL 2..." -ForegroundColor Yellow
try {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL não disponível"
    }
    Write-Host "✅ WSL 2 OK" -ForegroundColor Green
} catch {
    Write-Host "❌ WSL 2 não está instalado ou configurado" -ForegroundColor Red
    Write-Host "Execute: wsl --install" -ForegroundColor Yellow
    exit 1
}

# Validar dependências no WSL
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "📋 Validando dependências no WSL..." -ForegroundColor Yellow
    
    # Verificar uv
    $uvCheck = wsl -d Ubuntu bash -lc "command -v uv >/dev/null 2>&1 && echo 'OK' || echo 'MISSING'"
    if ($uvCheck -notmatch "OK") {
        Write-Host "❌ uv não está instalado no WSL" -ForegroundColor Red
        Write-Host "Execute: wsl bash -lc 'curl -LsSf https://astral.sh/uv/install.sh | sh'" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ uv instalado" -ForegroundColor Green
    
    # Verificar AWS CLI
    $awsCheck = wsl -d Ubuntu bash -c "command -v aws >/dev/null 2>&1 && echo 'OK' || echo 'MISSING'"
    if ($awsCheck -notmatch "OK") {
        Write-Host "❌ AWS CLI não está instalado no WSL" -ForegroundColor Red
        exit 1
    }
    
    # Verificar credenciais AWS
    Write-Host "📋 Verificando credenciais AWS..." -ForegroundColor Yellow
    $awsIdentity = wsl -d Ubuntu bash -lc "aws sts get-caller-identity 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Credenciais AWS não configuradas" -ForegroundColor Red
        Write-Host "Configure em: ~/.aws/credentials (WSL)" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ AWS CLI OK" -ForegroundColor Green
}

# Executar testes
if (-not $SkipTests) {
    Write-Host ""
    Write-Host "🧪 Executando testes..." -ForegroundColor Yellow
    
    $testResult = wsl -d Ubuntu bash -lc "cd /mnt/c/Users/victo/Projetos/n-agent-core/agent && uv run pytest tests/ -v 2>&1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Testes falharam!" -ForegroundColor Red
        Write-Host $testResult
        exit 1
    }
    
    # Verificar se passou todos os testes
    if ($testResult -match "(\d+) passed") {
        $testsPassed = $matches[1]
        Write-Host "✅ $testsPassed testes passaram" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Não foi possível verificar resultado dos testes" -ForegroundColor Yellow
    }
}

# Build de validação (sem deploy)
Write-Host ""
Write-Host "🔨 Validando build..." -ForegroundColor Yellow

$buildValidation = wsl -d Ubuntu bash -lc @"
cd /mnt/c/Users/victo/Projetos/n-agent-core/agent
uv sync --no-dev
uv pip compile pyproject.toml --universal --no-emit-options > requirements.txt
grep -i ruamel requirements.txt && echo 'ERROR: ruamel-yaml in requirements' && exit 1
echo 'OK'
"@

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build validation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build validado" -ForegroundColor Green

# Confirmar deploy
Write-Host ""
Write-Host "⚠️  ATENÇÃO: Você está prestes a fazer deploy para PRODUÇÃO" -ForegroundColor Yellow
Write-Host "   Account: 944938120078" -ForegroundColor Yellow
Write-Host "   Region: us-east-1" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Continuar? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "❌ Deploy cancelado pelo usuário" -ForegroundColor Red
    exit 0
}

# Deploy
Write-Host ""
Write-Host "🚀 Iniciando deploy..." -ForegroundColor Cyan
Write-Host ""

wsl -d Ubuntu bash -lc @"
cd /mnt/c/Users/victo/Projetos/n-agent-core/agent
agentcore launch 2>&1
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deploy concluído com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Verificar status: wsl bash -lc 'cd /mnt/c/.../agent && agentcore status'" -ForegroundColor Gray
    Write-Host "   2. Testar agent: wsl bash -lc 'cd /mnt/c/.../agent && agentcore invoke \"...\"'" -ForegroundColor Gray
    Write-Host "   3. Ver logs: aws logs tail /aws/bedrock-agentcore/runtimes/nagent-GcrnJb6DU5-DEFAULT" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ Deploy falhou!" -ForegroundColor Red
    exit 1
}

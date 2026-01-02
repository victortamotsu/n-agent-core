#!/usr/bin/env pwsh
# Validacao Pre-Deploy para n-agent
# Verifica Python, dependencies, tests, config

$ErrorActionPreference = "Stop"

Write-Host "Validacao Pre-Deploy" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Python version check
Write-Host "Verificando Python version..." -ForegroundColor Yellow
$pythonVersion = wsl -d Ubuntu bash -lc 'cd /mnt/c/Users/victo/Projetos/n-agent-core/agent && cat .python-version'
if ($pythonVersion -notmatch "3\.11") {
    Write-Host "ERROR: Python deve ser 3.11 (atual: $pythonVersion)" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Python 3.11" -ForegroundColor Green

# Requirements.txt check
Write-Host ""
Write-Host "Verificando requirements.txt..." -ForegroundColor Yellow
if (-not (Test-Path "agent\requirements.txt")) {
    Write-Host "Gerando requirements.txt..." -ForegroundColor Yellow
    wsl -d Ubuntu bash -lc 'cd /mnt/c/Users/victo/Projetos/n-agent-core/agent && uv pip compile pyproject.toml --universal --no-emit-options > requirements.txt'
}

$hasRuamel = wsl -d Ubuntu bash -c 'cd /mnt/c/Users/victo/Projetos/n-agent-core/agent && grep -i ruamel requirements.txt'
if ($LASTEXITCODE -eq 0) {
    Write-Host "ERROR: ruamel-yaml encontrado em requirements.txt!" -ForegroundColor Red
    exit 1
}
Write-Host "OK: requirements.txt valido" -ForegroundColor Green

# Tests
Write-Host ""
Write-Host "Executando testes..." -ForegroundColor Yellow
wsl -d Ubuntu bash -lc 'cd /mnt/c/Users/victo/Projetos/n-agent-core/agent && uv sync --no-dev && uv run pytest tests/ -v --tb=short' 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Testes falharam!" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Testes passaram" -ForegroundColor Green

# Config check
Write-Host ""
Write-Host "Verificando .bedrock_agentcore.yaml..." -ForegroundColor Yellow
$config = Get-Content "agent\.bedrock_agentcore.yaml" -Raw
$checks = @(
    "deployment_type: direct_code_deploy",
    "memory_id: nAgentMemory-jXyHuA6yrO",
    "account: '944938120078'",
    "region: us-east-1"
)

foreach ($check in $checks) {
    if ($config -notmatch [regex]::Escape($check)) {
        Write-Host "ERROR: Config invalido - faltando: $check" -ForegroundColor Red
        exit 1
    }
}
Write-Host "OK: Configuracao valida" -ForegroundColor Green

Write-Host ""
Write-Host "SUCCESS: Validacao pre-deploy concluida!" -ForegroundColor Green
Write-Host ""

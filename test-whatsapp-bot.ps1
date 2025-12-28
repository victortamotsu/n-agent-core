# Script para testar o WhatsApp Bot localmente
# Simula chamadas ao endpoint do webhook

$API_URL = "https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/webhooks/whatsapp"

Write-Host "Testando WhatsApp Bot - n-agent" -ForegroundColor Cyan
Write-Host ""

# Teste 1: Saudacao
Write-Host "Teste 1: Enviando 'Oi'..." -ForegroundColor Yellow
$payload1 = Get-Content "events/whatsapp-text-message.json" | ConvertFrom-Json
$body1 = $payload1.body | ConvertFrom-Json
$response1 = Invoke-RestMethod -Uri $API_URL -Method POST -Body ($payload1.body) -ContentType "application/json"
Write-Host "Resposta OK" -ForegroundColor Green
$response1 | ConvertTo-Json -Depth 5
Write-Host ""

Start-Sleep -Seconds 2

# Teste 2: Menu
Write-Host "Teste 2: Solicitando 'menu'..." -ForegroundColor Yellow
$payload2 = Get-Content "events/whatsapp-menu-request.json" | ConvertFrom-Json
$response2 = Invoke-RestMethod -Uri $API_URL -Method POST -Body ($payload2.body) -ContentType "application/json"
Write-Host "Resposta OK" -ForegroundColor Green
$response2 | ConvertTo-Json -Depth 5
Write-Host ""

Start-Sleep -Seconds 2

# Teste 3: Intencao de viagem
Write-Host "Teste 3: Dizendo 'Quero fazer uma viagem para Paris'..." -ForegroundColor Yellow
$payload3 = Get-Content "events/whatsapp-trip-intent.json" | ConvertFrom-Json
$response3 = Invoke-RestMethod -Uri $API_URL -Method POST -Body ($payload3.body) -ContentType "application/json"
Write-Host "Resposta OK" -ForegroundColor Green
$response3 | ConvertTo-Json -Depth 5
Write-Host ""

Write-Host "Testes concluidos!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Dica: Verifique os logs no CloudWatch para ver as respostas que foram enviadas" -ForegroundColor Gray
Write-Host "   aws logs tail /aws/lambda/n-agent-whatsapp-bot-prod --follow" -ForegroundColor Gray

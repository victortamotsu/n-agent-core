# Quick Deploy Script - Deploy Lambda directly to AWS for rapid testing
# Usage: .\scripts\quick-deploy.ps1 -Service trip-planner -Environment dev

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("whatsapp-bot", "trip-planner", "integrations", "all")]
    [string]$Service,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev"
)

Write-Host "🚀 Quick Deploy to AWS Lambda" -ForegroundColor Cyan
Write-Host "Service: $Service" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

function Deploy-Lambda {
    param([string]$ServiceName)
    
    $functionName = "n-agent-$ServiceName-$Environment"
    
    Write-Host "📦 Bundling $ServiceName..." -ForegroundColor Cyan
    node scripts/bundle-lambdas.js
    
    Write-Host "📦 Creating ZIP for $ServiceName..." -ForegroundColor Cyan
    $distPath = "services/$ServiceName/dist"
    $zipPath = "services/$ServiceName/$ServiceName.zip"
    
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Compress-Archive -Path "$distPath\*" -DestinationPath $zipPath -Force
    
    Write-Host "☁️  Deploying to AWS Lambda: $functionName..." -ForegroundColor Cyan
    aws lambda update-function-code `
        --function-name $functionName `
        --zip-file "fileb://$zipPath" `
        --no-cli-pager
    
    Write-Host "✅ $ServiceName deployed successfully!" -ForegroundColor Green
    Write-Host ""
}

if ($Service -eq "all") {
    Deploy-Lambda "whatsapp-bot"
    Deploy-Lambda "trip-planner"
    Deploy-Lambda "integrations"
} else {
    Deploy-Lambda $Service
}

Write-Host "🎉 Quick deploy completed!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Test your changes at:" -ForegroundColor Yellow
Write-Host "   https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/health" -ForegroundColor Cyan

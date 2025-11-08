# Script para criar Inbox no Chatwoot
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1",
    [string]$InboxName = "API Inbox - Teste"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🚀 Criando Inbox no Chatwoot..." -ForegroundColor Cyan
Write-Host ""

# Criar Inbox do tipo API
$InboxBody = @{
    name = $InboxName
    channel = @{
        type = "api"
        webhook_url = "https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook"
    }
} | ConvertTo-Json -Depth 10

try {
    $InboxResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes" `
        -Method POST `
        -Headers $Headers `
        -Body $InboxBody
    
    $InboxId = $InboxResponse.id
    $InboxName = $InboxResponse.name
    
    Write-Host "✅ Inbox criada com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "📋 Detalhes da Inbox:" -ForegroundColor White
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "   ID: $InboxId" -ForegroundColor Yellow
    Write-Host "   Nome: $InboxName" -ForegroundColor White
    Write-Host "   Tipo: API Channel" -ForegroundColor Gray
    Write-Host "   Webhook: https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔗 URL no Chatwoot:" -ForegroundColor White
    Write-Host "   $ChatwootUrl/app/accounts/$AccountId/inbox/$InboxId" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ Agora você pode criar conversas com:" -ForegroundColor White
    Write-Host "   .\create-chatwoot-conversation.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Erro ao criar Inbox!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $responseBody = $reader.ReadToEnd()
    Write-Host "Response:" -ForegroundColor Gray
    Write-Host $responseBody -ForegroundColor Gray
    
    exit 1
}

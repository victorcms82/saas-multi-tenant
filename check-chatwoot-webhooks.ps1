# Verificar webhooks ativos no Chatwoot
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🔍 Verificando webhooks do Chatwoot..." -ForegroundColor Cyan
Write-Host ""

try {
    $Response = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks" `
        -Method GET `
        -Headers $Headers
    
    if ($Response.payload.Count -eq 0) {
        Write-Host "✅ NENHUM webhook ativo!" -ForegroundColor Green
        Write-Host "Isso está correto! Use apenas o script de teste." -ForegroundColor White
    } else {
        Write-Host "⚠️  ATENÇÃO: $($Response.payload.Count) webhook(s) encontrado(s)!" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($webhook in $Response.payload) {
            Write-Host "  Webhook ID: $($webhook.id)" -ForegroundColor Red
            Write-Host "  URL: $($webhook.url)" -ForegroundColor Red
            Write-Host "  Eventos: $($webhook.subscriptions -join ', ')" -ForegroundColor Red
            Write-Host ""
            Write-Host "  ⚠️  ESTE WEBHOOK PODE ESTAR CAUSANDO LOOPS!" -ForegroundColor Yellow
            Write-Host "  Exclua em: $ChatwootUrl/app/accounts/$AccountId/settings/integrations/webhooks" -ForegroundColor Gray
            Write-Host ""
        }
    }
} catch {
    Write-Host "❌ Erro ao verificar: $_" -ForegroundColor Red
}

# Script para configurar webhook do Chatwoot para APENAS mensagens incoming
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🔧 Configurando webhooks do Chatwoot..." -ForegroundColor Cyan
Write-Host ""

# Listar webhooks existentes
Write-Host "📋 Listando webhooks..." -ForegroundColor Yellow
try {
    $WebhooksResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks" `
        -Method GET `
        -Headers $Headers
    
    Write-Host "✅ Webhooks encontrados: $($WebhooksResponse.payload.Count)" -ForegroundColor Green
    
    foreach ($webhook in $WebhooksResponse.payload) {
        Write-Host ""
        Write-Host "  Webhook ID: $($webhook.id)" -ForegroundColor White
        Write-Host "  URL: $($webhook.url)" -ForegroundColor Gray
        Write-Host "  Eventos: $($webhook.subscriptions -join ', ')" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Erro ao listar webhooks: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "⚠️  ATENÇÃO: Configuração via API não suportada!" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "O Chatwoot não permite configurar QUAIS eventos via API." -ForegroundColor White
Write-Host "Você precisa fazer isso manualmente pela interface web:" -ForegroundColor White
Write-Host ""
Write-Host "📝 Passos:" -ForegroundColor Cyan
Write-Host "  1. Acesse: $ChatwootUrl/app/accounts/$AccountId/settings/integrations/webhooks" -ForegroundColor Gray
Write-Host "  2. Clique no webhook: https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook" -ForegroundColor Gray
Write-Host "  3. Na seção 'Events', DESMARQUE:" -ForegroundColor Gray
Write-Host "     ❌ message_created (outgoing)" -ForegroundColor Red
Write-Host "  4. Mantenha MARCADO:" -ForegroundColor Gray
Write-Host "     ✅ message_created (incoming)" -ForegroundColor Green
Write-Host "  5. Clique em 'Update'" -ForegroundColor Gray
Write-Host ""
Write-Host "Alternativamente, você pode:" -ForegroundColor Yellow
Write-Host "  - Deletar o webhook atual" -ForegroundColor Gray
Write-Host "  - Criar novo webhook apenas para 'incoming messages'" -ForegroundColor Gray
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan

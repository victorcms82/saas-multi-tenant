# Script para criar webhook do Chatwoot APENAS para mensagens INCOMING
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1",
    [string]$WebhookUrl = "https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🔧 Configurando webhook do Chatwoot..." -ForegroundColor Cyan
Write-Host ""

# Primeiro, vamos verificar se já existe algum webhook
Write-Host "📋 Verificando webhooks existentes..." -ForegroundColor Yellow
try {
    $ExistingWebhooks = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks" `
        -Method GET `
        -Headers $Headers
    
    if ($ExistingWebhooks.payload.Count -gt 0) {
        Write-Host "⚠️  Encontrado(s) $($ExistingWebhooks.payload.Count) webhook(s) existente(s)" -ForegroundColor Yellow
        
        foreach ($webhook in $ExistingWebhooks.payload) {
            Write-Host ""
            Write-Host "  Webhook ID: $($webhook.id)" -ForegroundColor White
            Write-Host "  URL: $($webhook.url)" -ForegroundColor Gray
            Write-Host "  Eventos: $($webhook.subscriptions -join ', ')" -ForegroundColor Gray
            
            # Deletar webhook existente se for o mesmo URL
            if ($webhook.url -eq $WebhookUrl) {
                Write-Host "  🗑️  Deletando webhook duplicado..." -ForegroundColor Red
                try {
                    Invoke-RestMethod `
                        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks/$($webhook.id)" `
                        -Method DELETE `
                        -Headers $Headers | Out-Null
                    Write-Host "  ✅ Webhook deletado" -ForegroundColor Green
                } catch {
                    Write-Host "  ❌ Erro ao deletar: $_" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "✅ Nenhum webhook existente" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Erro ao listar webhooks: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "📝 Criando webhook para APENAS mensagens INCOMING..." -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Criar webhook com APENAS message_created para incoming
$WebhookPayload = @{
    url = $WebhookUrl
    subscriptions = @("message_created")  # Apenas incoming por padrão
} | ConvertTo-Json

Write-Host "📤 Payload:" -ForegroundColor Gray
Write-Host $WebhookPayload -ForegroundColor DarkGray
Write-Host ""

try {
    $WebhookResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks" `
        -Method POST `
        -Headers $Headers `
        -Body $WebhookPayload
    
    Write-Host "✅ Webhook criado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Webhook ID: $($WebhookResponse.id)" -ForegroundColor White
    Write-Host "URL: $($WebhookResponse.url)" -ForegroundColor White
    Write-Host "Eventos: $($WebhookResponse.subscriptions -join ', ')" -ForegroundColor White
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "⚠️  IMPORTANTE: Verificar configuração manual" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acesse o Chatwoot e verifique se o webhook está configurado para:" -ForegroundColor White
    Write-Host "  ✅ Message Created (Incoming) - MARCADO" -ForegroundColor Green
    Write-Host "  ❌ Message Created (Outgoing) - DESMARCADO" -ForegroundColor Red
    Write-Host ""
    Write-Host "URL: $ChatwootUrl/app/accounts/$AccountId/settings/integrations/webhooks" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Erro ao criar webhook: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Detalhes do erro:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "🧪 Próximos passos:" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Envie uma mensagem REAL via Chatwoot (como cliente)" -ForegroundColor White
Write-Host "2. Verifique se o n8n recebe apenas mensagens INCOMING" -ForegroundColor White
Write-Host "3. Confirme que mensagens OUTGOING (do bot) NÃO disparam o webhook" -ForegroundColor White
Write-Host ""

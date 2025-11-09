# Verificar e atualizar configuração da INBOX (não webhook global)
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1",
    [int]$InboxId = 1
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🔍 Verificando configuração da Inbox $InboxId..." -ForegroundColor Cyan
Write-Host ""

try {
    # Buscar dados da inbox
    $InboxResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes/$InboxId" `
        -Method GET `
        -Headers $Headers
    
    Write-Host "📋 Inbox ID: $($InboxResponse.id)" -ForegroundColor White
    Write-Host "📋 Nome: $($InboxResponse.name)" -ForegroundColor White
    Write-Host "📋 Channel Type: $($InboxResponse.channel_type)" -ForegroundColor White
    Write-Host "📋 Webhook URL: $($InboxResponse.webhook_url)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($InboxResponse.webhook_url) {
        Write-Host "⚠️  ATENÇÃO: Esta Inbox TEM webhook configurado!" -ForegroundColor Red
        Write-Host "Webhook URL: $($InboxResponse.webhook_url)" -ForegroundColor Red
        Write-Host ""
        Write-Host "🔧 Para remover o webhook desta Inbox:" -ForegroundColor Yellow
        Write-Host "   1. Acesse: $ChatwootUrl/app/accounts/$AccountId/settings/inboxes/$InboxId" -ForegroundColor Gray
        Write-Host "   2. Vá em 'Settings' ou 'Configuration'" -ForegroundColor Gray
        Write-Host "   3. Remova ou deixe vazio o campo 'Webhook URL'" -ForegroundColor Gray
        Write-Host "   4. Salve" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "❓ Deseja tentar remover via API? (Pode não funcionar para todos os tipos de inbox)" -ForegroundColor Yellow
        Write-Host "Digite 'sim' para tentar: " -NoNewline -ForegroundColor Yellow
        $resposta = Read-Host
        
        if ($resposta -eq "sim") {
            Write-Host ""
            Write-Host "🔧 Tentando remover webhook da Inbox..." -ForegroundColor Cyan
            
            $UpdatePayload = @{
                webhook_url = ""
            } | ConvertTo-Json
            
            try {
                $UpdateResponse = Invoke-RestMethod `
                    -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes/$InboxId" `
                    -Method PATCH `
                    -Headers $Headers `
                    -Body $UpdatePayload
                
                Write-Host "✅ Webhook removido com sucesso!" -ForegroundColor Green
            } catch {
                Write-Host "❌ Não foi possível remover via API: $_" -ForegroundColor Red
                Write-Host "Por favor, remova manualmente pela interface web." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✅ Esta Inbox NÃO tem webhook configurado!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "❌ Erro ao buscar Inbox: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "💡 DICA: Webhooks podem estar configurados em 2 lugares:" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "1. Settings > Integrations > Webhooks (GLOBAL - para todas inboxes)" -ForegroundColor White
Write-Host "2. Inbox Settings > Configuration (ESPECÍFICO - só para aquela inbox)" -ForegroundColor White
Write-Host ""
Write-Host "Ambos precisam estar VAZIOS para parar de receber webhooks!" -ForegroundColor Yellow
Write-Host ""

# ============================================
# Setup WhatsApp Meta Cloud API no Chatwoot
# ============================================
# Este script conecta o Chatwoot ao WhatsApp Business API oficial (Meta Cloud)
#
# Pré-requisitos:
# - Meta Developers App configurado
# - Phone Number ID do WhatsApp
# - Access Token permanente
# - WhatsApp Business Account ID
#
# Autor: GitHub Copilot + Victor Castro
# Data: 10/11/2025
# ============================================

param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ChatwootToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [int]$AccountId = 1,
    [int]$InboxId = 2,
    [int]$AgentId = 2,
    [string]$PhoneNumberId = "851688391353928",
    [string]$WhatsAppBusinessAccountId = "321795270349789288",
    [string]$AccessToken = "EAAV64FVdoGMBP24xQJraD9tEEW5IchEjPAJUsquz9BT16xbYJABGtud2ThZA1D3vC6SIpl3SfojlonZB3B50yRSVQatN7LVbDA7CsZBWUdvAZAWBYZBftrZCGN3ONTilFOZCnLfxnnmG8Dy5IEZCaDFn7q37zGFvyWibiARnJFtkvRONHZC3yNLbn1UXlWVZCW6CSRmwZCEJIaVaconRbJGmWZBVvYZB4Bb7udmevq6C2SIiKImfGZAT5u7G3ovQCUg7qoksIc1kjooDu0nzHYb55GW7WJ2HKvsZBVFZCZC18ZCclD6ZBLb",
    [string]$InboxName = "Clínica Sorriso - WhatsApp",
    [string]$WebhookUrl = "https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook"
)

$headers = @{
    "api_access_token" = $ChatwootToken
    "Content-Type" = "application/json"
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎯 Configurando WhatsApp Meta Cloud API no Chatwoot" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Passo 1: Deletar Inbox atual (se existir)
# ============================================
Write-Host "🗑️  Passo 1: Removendo Inbox $InboxId anterior (API channel)..." -ForegroundColor Yellow

try {
    $deleteUrl = "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes/$InboxId"
    $response = Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers -ErrorAction SilentlyContinue
    Write-Host "✅ Inbox $InboxId removido com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Inbox $InboxId não encontrado (pode não existir ainda)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# Passo 2: Criar novo Inbox com WhatsApp
# ============================================
Write-Host "📱 Passo 2: Criando novo Inbox com WhatsApp Meta Cloud API..." -ForegroundColor Yellow

$createInboxBody = @{
    name = $InboxName
    channel = @{
        type = "whatsapp"
        phone_number = "+15558354441"
        provider = "whatsapp_cloud"
        provider_config = @{
            api_key = $AccessToken
            phone_number_id = $PhoneNumberId
            business_account_id = $WhatsAppBusinessAccountId
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $createUrl = "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes"
    $inbox = Invoke-RestMethod -Uri $createUrl -Method Post -Headers $headers -Body $createInboxBody
    
    $newInboxId = $inbox.id
    
    Write-Host "✅ Inbox WhatsApp criado com sucesso!" -ForegroundColor Green
    Write-Host "   ID: $newInboxId" -ForegroundColor White
    Write-Host "   Nome: $($inbox.name)" -ForegroundColor White
    Write-Host "   Número: $($inbox.phone_number)" -ForegroundColor White
    Write-Host "   Provider: whatsapp_cloud (Meta oficial)" -ForegroundColor White
} catch {
    Write-Host "❌ Erro ao criar inbox:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Detalhes da resposta:" -ForegroundColor Yellow
    Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================
# Passo 3: Adicionar Agent ao Inbox
# ============================================
Write-Host "👤 Passo 3: Adicionando Agent $AgentId ao Inbox..." -ForegroundColor Yellow

$addAgentBody = @{
    inbox_id = $newInboxId
    user_ids = @($AgentId)
} | ConvertTo-Json

try {
    $addAgentUrl = "$ChatwootUrl/api/v1/accounts/$AccountId/inbox_members"
    Invoke-RestMethod -Uri $addAgentUrl -Method Post -Headers $headers -Body $addAgentBody | Out-Null
    Write-Host "✅ Agent adicionado ao Inbox com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Erro ao adicionar agent (pode já estar adicionado)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# Passo 4: Configurar Webhook no Inbox
# ============================================
Write-Host "🔗 Passo 4: Configurando webhook do Chatwoot..." -ForegroundColor Yellow
Write-Host "   URL: $WebhookUrl" -ForegroundColor White

# Nota: Webhooks são configurados via Settings → Integrations no Chatwoot UI
# Não há endpoint API direto para isso, então precisamos fazer manual ou via inbox settings

Write-Host "⚠️  Webhook deve ser configurado manualmente:" -ForegroundColor Yellow
Write-Host "   1. Acessar: $ChatwootUrl/app/accounts/$AccountId/settings/inboxes/$newInboxId" -ForegroundColor White
Write-Host "   2. Settings → Configuration → Webhook URL" -ForegroundColor White
Write-Host "   3. Adicionar: $WebhookUrl" -ForegroundColor White
Write-Host "   4. Salvar" -ForegroundColor White

Write-Host ""

# ============================================
# Passo 5: Configurar Webhook no Meta (Facebook)
# ============================================
Write-Host "🌐 Passo 5: Configurando webhook no Meta Developers..." -ForegroundColor Yellow

Write-Host "⚠️  Configure o webhook no Meta Developers:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. Acesse: https://developers.facebook.com/apps" -ForegroundColor White
Write-Host "   2. Seu App → WhatsApp → Configuration" -ForegroundColor White
Write-Host "   3. Webhook → Edit" -ForegroundColor White
Write-Host ""
Write-Host "   Callback URL:" -ForegroundColor Cyan
Write-Host "   $ChatwootUrl/api/v1/accounts/$AccountId/inboxes/$newInboxId/webhooks" -ForegroundColor White
Write-Host ""
Write-Host "   Verify Token: (criar um aleatório, ex: 'chatwoot_verify_123')" -ForegroundColor Cyan
Write-Host ""
Write-Host "   4. Verificar e salvar" -ForegroundColor White
Write-Host "   5. Subscription Fields: Selecionar 'messages'" -ForegroundColor White

Write-Host ""

# ============================================
# Passo 6: Testar Conexão
# ============================================
Write-Host "🧪 Passo 6: Testando conexão com WhatsApp..." -ForegroundColor Yellow

Write-Host ""
Write-Host "Para testar, envie uma mensagem para:" -ForegroundColor Cyan
Write-Host "+1 555 835 4441 (número de teste do WhatsApp)" -ForegroundColor White
Write-Host ""
Write-Host "A mensagem deve aparecer no Chatwoot Inbox $newInboxId" -ForegroundColor White

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✨ Setup WhatsApp Meta Cloud API concluído!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Resumo:" -ForegroundColor Cyan
Write-Host "   Inbox ID: $newInboxId" -ForegroundColor White
Write-Host "   Número WhatsApp: +1 555 835 4441" -ForegroundColor White
Write-Host "   Provider: Meta Cloud API (oficial)" -ForegroundColor White
Write-Host "   Agent ID: $AgentId adicionado" -ForegroundColor White
Write-Host ""

Write-Host "🔑 Próximos Passos:" -ForegroundColor Cyan
Write-Host "   1. ⚠️  Configurar webhook no Chatwoot (manual)" -ForegroundColor Yellow
Write-Host "   2. ⚠️  Configurar webhook no Meta Developers (manual)" -ForegroundColor Yellow
Write-Host "   3. ✅ Enviar mensagem de teste para +1 555 835 4441" -ForegroundColor Green
Write-Host "   4. ✅ Verificar no Chatwoot Inbox $newInboxId" -ForegroundColor Green
Write-Host "   5. ✅ Validar n8n workflow disparado" -ForegroundColor Green
Write-Host ""

Write-Host "🔗 Links úteis:" -ForegroundColor Cyan
Write-Host "   Chatwoot Inbox: $ChatwootUrl/app/accounts/$AccountId/inbox/$newInboxId" -ForegroundColor White
Write-Host "   Meta Developers: https://developers.facebook.com/apps" -ForegroundColor White
Write-Host "   n8n Executions: https://n8n.evolutedigital.com.br/workflow/1/executions" -ForegroundColor White
Write-Host ""

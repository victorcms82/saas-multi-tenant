# Script para criar conversa de teste no Chatwoot
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1",
    [string]$ContactName = "Cliente Teste",
    [string]$ContactPhone = "+5511999999999"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🚀 Criando conversa de teste no Chatwoot..." -ForegroundColor Cyan
Write-Host ""

# Passo 1: Criar ou buscar contato
Write-Host "📞 Criando contato..." -ForegroundColor Yellow
$ContactBody = @{
    name = $ContactName
    phone_number = $ContactPhone
} | ConvertTo-Json

try {
    $ContactResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/contacts" `
        -Method POST `
        -Headers $Headers `
        -Body $ContactBody
    
    $ContactId = $ContactResponse.payload.contact.id
    Write-Host "✅ Contato criado! ID: $ContactId" -ForegroundColor Green
} catch {
    # Se contato já existe, buscar
    Write-Host "⚠️  Contato já existe, buscando..." -ForegroundColor Yellow
    try {
        $ContactsResponse = Invoke-RestMethod `
            -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/contacts/search?q=$ContactPhone" `
            -Method GET `
            -Headers $Headers
        
        $ContactId = $ContactsResponse.payload[0].id
        Write-Host "✅ Contato encontrado! ID: $ContactId" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao buscar contato: $_" -ForegroundColor Red
        exit 1
    }
}

# Passo 2: Buscar Inbox disponível
Write-Host ""
Write-Host "📥 Buscando Inboxes..." -ForegroundColor Yellow
try {
    $InboxesResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes" `
        -Method GET `
        -Headers $Headers
    
    if ($InboxesResponse.payload.Count -eq 0) {
        Write-Host "❌ Nenhuma Inbox encontrada! Crie uma Inbox primeiro no Chatwoot." -ForegroundColor Red
        exit 1
    }
    
    $InboxId = $InboxesResponse.payload[0].id
    $InboxName = $InboxesResponse.payload[0].name
    Write-Host "✅ Inbox encontrada: $InboxName (ID: $InboxId)" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao buscar Inboxes: $_" -ForegroundColor Red
    exit 1
}

# Passo 3: Criar conversa
Write-Host ""
Write-Host "💬 Criando conversa..." -ForegroundColor Yellow
$ConversationBody = @{
    source_id = "test-$(Get-Date -Format 'yyyyMMddHHmmss')"
    inbox_id = $InboxId
    contact_id = $ContactId
    status = "open"
    custom_attributes = @{
        client_id = "clinica_sorriso_001"
        agent_id = "default"
    }
} | ConvertTo-Json -Depth 10

try {
    $ConversationResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/conversations" `
        -Method POST `
        -Headers $Headers `
        -Body $ConversationBody
    
    $ConversationId = $ConversationResponse.id
    Write-Host "✅ Conversa criada! ID: $ConversationId" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao criar conversa: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# Passo 4: Enviar mensagem inicial do cliente
Write-Host ""
Write-Host "📩 Enviando mensagem inicial..." -ForegroundColor Yellow
$MessageBody = @{
    content = "Olá! Qual o preço?"
    message_type = "incoming"
    private = $false
} | ConvertTo-Json

try {
    $MessageResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/conversations/$ConversationId/messages" `
        -Method POST `
        -Headers $Headers `
        -Body $MessageBody
    
    Write-Host "✅ Mensagem enviada!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Erro ao enviar mensagem (mas conversa foi criada): $_" -ForegroundColor Yellow
}

# Resumo
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "✅ CONVERSA CRIADA COM SUCESSO!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Detalhes:" -ForegroundColor White
Write-Host "   Contact ID: $ContactId" -ForegroundColor Gray
Write-Host "   Inbox ID: $InboxId ($InboxName)" -ForegroundColor Gray
Write-Host "   Conversation ID: $ConversationId" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔗 URL no Chatwoot:" -ForegroundColor White
Write-Host "   $ChatwootUrl/app/accounts/$AccountId/conversations/$ConversationId" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Próximos passos:" -ForegroundColor White
Write-Host "   1. Acesse a URL acima para ver a conversa" -ForegroundColor Gray
Write-Host "   2. Use este conversation_id no teste do webhook:" -ForegroundColor Gray
Write-Host ""
Write-Host "      .\test-wf0-webhook.ps1 -ConversationId $ConversationId" -ForegroundColor Yellow
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan

# Script para criar Inbox + Agent no Chatwoot para novo cliente
param(
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientName,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientEmail,
    
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🚀 Configurando Chatwoot para cliente: $ClientName ($ClientId)" -ForegroundColor Cyan

# Passo 1: Criar Inbox
Write-Host "`n📥 Criando Inbox..." -ForegroundColor Yellow
$InboxBody = @{
    name = "$ClientName - $ClientId"
    channel = @{
        type = "api"
        webhook_url = "https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook"
    }
} | ConvertTo-Json

try {
    $InboxResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/inboxes" `
        -Method POST `
        -Headers $Headers `
        -Body $InboxBody
    
    $InboxId = $InboxResponse.id
    Write-Host "✅ Inbox criada com sucesso! ID: $InboxId" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao criar Inbox: $_" -ForegroundColor Red
    exit 1
}

# Passo 2: Criar Agent Account para o Cliente
Write-Host "`n👤 Criando conta de Agent para o cliente..." -ForegroundColor Yellow
$AgentBody = @{
    name = "$ClientName (Cliente)"
    email = $ClientEmail
    role = "agent"  # Não administrator
    availability_status = "offline"
} | ConvertTo-Json

try {
    $AgentResponse = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/agents" `
        -Method POST `
        -Headers $Headers `
        -Body $AgentBody
    
    $AgentId = $AgentResponse.id
    Write-Host "✅ Agent criado com sucesso! ID: $AgentId" -ForegroundColor Green
    Write-Host "📧 Email de confirmação enviado para: $ClientEmail" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️  Erro ao criar Agent (pode já existir): $_" -ForegroundColor Yellow
    # Buscar Agent existente
    try {
        $AgentsResponse = Invoke-RestMethod `
            -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/agents" `
            -Method GET `
            -Headers $Headers
        
        $ExistingAgent = $AgentsResponse | Where-Object { $_.email -eq $ClientEmail }
        if ($ExistingAgent) {
            $AgentId = $ExistingAgent.id
            Write-Host "✅ Agent já existe! ID: $AgentId" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Não foi possível encontrar Agent existente" -ForegroundColor Red
        exit 1
    }
}

# Passo 3: Adicionar Agent à Inbox
Write-Host "`n🔗 Adicionando Agent à Inbox..." -ForegroundColor Yellow
$AddAgentBody = @{
    inbox_id = $InboxId
    user_ids = @($AgentId)
} | ConvertTo-Json

try {
    Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/inbox_members" `
        -Method POST `
        -Headers $Headers `
        -Body $AddAgentBody
    
    Write-Host "✅ Agent adicionado à Inbox!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Erro ao adicionar Agent (pode já estar na Inbox): $_" -ForegroundColor Yellow
}

# Passo 4: Salvar mapeamento Client → Inbox no banco
Write-Host "`n💾 Salvando mapeamento no Supabase..." -ForegroundColor Yellow

$SupabaseUrl = "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1"
$SupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"

$SupabaseHeaders = @{
    "apikey" = $SupabaseKey
    "Authorization" = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$UpdateBody = @{
    chatwoot_inbox_id = $InboxId
    chatwoot_agent_id = $AgentId
} | ConvertTo-Json

try {
    Invoke-RestMethod `
        -Uri "$SupabaseUrl/clients?client_id=eq.$ClientId" `
        -Method PATCH `
        -Headers $SupabaseHeaders `
        -Body $UpdateBody
    
    Write-Host "✅ Mapeamento salvo no banco!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Aviso: Não foi possível salvar no banco: $_" -ForegroundColor Yellow
    Write-Host "   Você pode fazer isso manualmente depois." -ForegroundColor Gray
}

# Resumo
Write-Host "`n" -NoNewline
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host (" RESUMO ".PadLeft(40, "=").PadRight(80, "=")) -ForegroundColor Cyan
Write-Host "Cliente: $ClientName" -ForegroundColor White
Write-Host "Client ID: $ClientId" -ForegroundColor White
Write-Host "Inbox ID: $InboxId" -ForegroundColor Green
Write-Host "Agent ID: $AgentId" -ForegroundColor Green
Write-Host "Email: $ClientEmail" -ForegroundColor White
Write-Host "`nURL de acesso do cliente:" -ForegroundColor Yellow
Write-Host "$ChatwootUrl/app/accounts/$AccountId/inbox/$InboxId" -ForegroundColor Cyan
Write-Host "`nPróximos passos:" -ForegroundColor Yellow
Write-Host "1. Cliente deve acessar email $ClientEmail e confirmar conta" -ForegroundColor Gray
Write-Host "2. Após confirmação, fazer login em $ChatwootUrl" -ForegroundColor Gray
Write-Host "3. Cliente verá apenas conversas da Inbox '$ClientName - $ClientId'" -ForegroundColor Gray
Write-Host "=" * 80 -ForegroundColor Cyan

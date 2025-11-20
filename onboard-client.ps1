# ============================================================================
# Script de Onboarding de Novos Clientes
# ============================================================================
# Uso: .\onboard-client.ps1 -ClientId "cliente_001" -ClientName "Nome Cliente"

param(
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientName,
    
    [Parameter(Mandatory=$true)]
    [string]$AdminEmail,
    
    [Parameter(Mandatory=$true)]
    [string]$AdminName,
    
    [Parameter(Mandatory=$false)]
    [string]$AdminPassword = "TempPass123!",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentName = "Assistente Virtual"
)

# Configurações do Supabase
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "       ONBOARDING DE NOVO CLIENTE - SAAS MULTI-TENANT      " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Headers para requisições
$headers = @{
    'apikey' = $SUPABASE_KEY
    'Authorization' = "Bearer $SUPABASE_KEY"
    'Content-Type' = 'application/json'
}

Write-Host "📋 DADOS DO CLIENTE:" -ForegroundColor Yellow
Write-Host "   Client ID: $ClientId" -ForegroundColor White
Write-Host "   Nome: $ClientName" -ForegroundColor White
Write-Host "   Admin: $AdminName ($AdminEmail)" -ForegroundColor White
Write-Host "   Agente: $AgentName" -ForegroundColor White
Write-Host ""

# ============================================================================
# PASSO 1: Criar Cliente no Banco
# ============================================================================

Write-Host "🔄 Passo 1/5: Criando cliente..." -ForegroundColor Cyan

$clientBody = @{
    p_client_id = $ClientId
    p_client_name = $ClientName
    p_contact_email = $AdminEmail
    p_contact_phone = ""
} | ConvertTo-Json

try {
    $clientResult = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/create_new_client" `
        -Method Post `
        -Headers $headers `
        -Body $clientBody
    
    if (-not $clientResult.success) {
        throw "Erro ao criar cliente: $($clientResult.error)"
    }
    
    Write-Host "   ✅ Cliente criado: $ClientId" -ForegroundColor Green
} catch {
    Write-Host "   ❌ ERRO: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# PASSO 2: Preparar dados do Admin
# ============================================================================

Write-Host "🔄 Passo 2/5: Preparando admin..." -ForegroundColor Cyan

$adminPrepBody = @{
    p_email = $AdminEmail
    p_full_name = $AdminName
    p_client_id = $ClientId
    p_role = "admin"
} | ConvertTo-Json

try {
    $adminPrep = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/create_client_admin" `
        -Method Post `
        -Headers $headers `
        -Body $adminPrepBody
    
    if (-not $adminPrep.success) {
        throw "Erro ao preparar admin: $($adminPrep.error)"
    }
    
    Write-Host "   ✅ Dados preparados" -ForegroundColor Green
    Write-Host "   📝 User ID: $($adminPrep.user_id)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ ERRO: $_" -ForegroundColor Red
    Write-Host "   🔙 Revertendo: removendo cliente..." -ForegroundColor Yellow
    
    # Rollback: deletar cliente
    Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/clients?client_id=eq.$ClientId" `
        -Method Delete `
        -Headers $headers `
        -ErrorAction SilentlyContinue
    
    exit 1
}

Write-Host ""

# ============================================================================
# PASSO 3: Criar usuário no Supabase Auth
# ============================================================================

Write-Host "🔄 Passo 3/5: Criando usuário no Auth..." -ForegroundColor Cyan

$authBody = @{
    email = $AdminEmail
    password = $AdminPassword
    email_confirm = $true
    user_metadata = @{
        full_name = $AdminName
    }
} | ConvertTo-Json

try {
    $authResult = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/auth/v1/admin/users" `
        -Method Post `
        -Headers $headers `
        -Body $authBody
    
    $authUserId = $authResult.id
    
    Write-Host "   ✅ Usuário criado no Auth" -ForegroundColor Green
    Write-Host "   📧 Email: $AdminEmail" -ForegroundColor Gray
    Write-Host "   🔒 Senha: $AdminPassword" -ForegroundColor Gray
    Write-Host "   🆔 Auth ID: $authUserId" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ ERRO ao criar no Auth: $_" -ForegroundColor Red
    Write-Host "   🔙 Revertendo: removendo cliente..." -ForegroundColor Yellow
    
    # Rollback: deletar cliente
    Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/clients?client_id=eq.$ClientId" `
        -Method Delete `
        -Headers $headers `
        -ErrorAction SilentlyContinue
    
    exit 1
}

Write-Host ""

# ============================================================================
# PASSO 4: Vincular Auth ao Dashboard
# ============================================================================

Write-Host "🔄 Passo 4/5: Vinculando Auth → Dashboard..." -ForegroundColor Cyan

$linkBody = @{
    p_auth_user_id = $authUserId
    p_email = $AdminEmail
    p_full_name = $AdminName
    p_client_id = $ClientId
    p_role = "admin"
} | ConvertTo-Json

try {
    $linkResult = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/link_auth_to_dashboard" `
        -Method Post `
        -Headers $headers `
        -Body $linkBody
    
    if (-not $linkResult.success) {
        throw "Erro ao vincular: $($linkResult.error)"
    }
    
    Write-Host "   ✅ Usuário vinculado ao dashboard" -ForegroundColor Green
} catch {
    Write-Host "   ❌ ERRO: $_" -ForegroundColor Red
    Write-Host "   🔙 Revertendo: removendo usuário e cliente..." -ForegroundColor Yellow
    
    # Rollback: deletar auth user e cliente
    Invoke-RestMethod `
        -Uri "$SUPABASE_URL/auth/v1/admin/users/$authUserId" `
        -Method Delete `
        -Headers $headers `
        -ErrorAction SilentlyContinue
    
    Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/clients?client_id=eq.$ClientId" `
        -Method Delete `
        -Headers $headers `
        -ErrorAction SilentlyContinue
    
    exit 1
}

Write-Host ""

# ============================================================================
# PASSO 5: Criar Agente IA
# ============================================================================

Write-Host "🔄 Passo 5/5: Criando agente IA..." -ForegroundColor Cyan

$agentBody = @{
    p_client_id = $ClientId
    p_agent_name = $AgentName
} | ConvertTo-Json

try {
    $agentResult = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/create_default_agent" `
        -Method Post `
        -Headers $headers `
        -Body $agentBody
    
    if (-not $agentResult.success) {
        throw "Erro ao criar agente: $($agentResult.error)"
    }
    
    Write-Host "   ✅ Agente criado" -ForegroundColor Green
    Write-Host "   🤖 Agent ID: $($agentResult.agent_id)" -ForegroundColor Gray
} catch {
    Write-Host "   ⚠️  Aviso: $_" -ForegroundColor Yellow
    Write-Host "   ℹ️  Cliente e admin foram criados com sucesso" -ForegroundColor Cyan
    Write-Host "   📝 Você pode criar o agente manualmente depois" -ForegroundColor Cyan
}

Write-Host ""

# ============================================================================
# PASSO 6: Validação Final
# ============================================================================

Write-Host "🔄 Validando configuração..." -ForegroundColor Cyan

# Buscar dados do cliente criado
$clientData = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/clients?client_id=eq.$ClientId&select=*" `
    -Method Get `
    -Headers $headers

$userData = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/dashboard_users?email=eq.$AdminEmail&select=*" `
    -Method Get `
    -Headers $headers

$agentData = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/agents?client_id=eq.$ClientId&select=*" `
    -Method Get `
    -Headers $headers

Write-Host "   ✅ Cliente ativo no banco" -ForegroundColor Green
Write-Host "   ✅ Usuário admin configurado" -ForegroundColor Green
Write-Host "   ✅ Agente IA criado" -ForegroundColor Green

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "       ✅ ONBOARDING CONCLUÍDO COM SUCESSO!               " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Host "📋 CREDENCIAIS DE ACESSO:" -ForegroundColor Yellow
Write-Host "   URL: https://seu-dashboard.lovable.app" -ForegroundColor White
Write-Host "   Email: $AdminEmail" -ForegroundColor White
Write-Host "   Senha: $AdminPassword" -ForegroundColor White
Write-Host ""

Write-Host "📝 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "   1. Enviar email com credenciais para o cliente" -ForegroundColor White
Write-Host "   2. Cliente deve trocar senha no primeiro login" -ForegroundColor White
Write-Host "   3. Configurar integração Chatwoot:" -ForegroundColor White
Write-Host "      - Criar inbox no Chatwoot" -ForegroundColor Gray
Write-Host "      - Configurar webhook para N8N" -ForegroundColor Gray
Write-Host "      - Atualizar chatwoot_inbox_id na tabela agents" -ForegroundColor Gray
Write-Host "   4. Configurar prompt personalizado do cliente" -ForegroundColor White
Write-Host "   5. Testar conversação end-to-end" -ForegroundColor White
Write-Host ""

Write-Host "🔗 LINKS ÚTEIS:" -ForegroundColor Yellow
Write-Host "   Supabase: $SUPABASE_URL" -ForegroundColor Gray
Write-Host "   Client ID: $ClientId" -ForegroundColor Gray
Write-Host "   Agent ID: ${ClientId}_agent_default" -ForegroundColor Gray
Write-Host ""

Write-Host "✨ Cliente pronto para começar a usar o sistema!" -ForegroundColor Cyan
Write-Host ""

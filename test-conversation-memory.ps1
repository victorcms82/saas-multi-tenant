# ============================================================================
# Script de Teste: Sistema de Memória de Conversação
# ============================================================================
# Testa se as funções RPC e tabela conversation_memory estão funcionando
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTE: Sistema de Memória de Conversação" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$supabaseUrl = "https://vnlfgnfaortdvmraoapq.supabase.co"
$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"

# ============================================================================
# Teste 1: Verificar se a tabela existe
# ============================================================================
Write-Host "[TESTE 1] Verificando se tabela conversation_memory existe..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/conversation_memory?select=count&limit=0" `
        -Method GET `
        -Headers @{
            "apikey" = $apiKey
            "Authorization" = "Bearer $apiKey"
        } `
        -ErrorAction Stop
    
    Write-Host "✅ Tabela conversation_memory existe!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ ERRO: Tabela conversation_memory não existe ou não está acessível!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ============================================================================
# Teste 2: Verificar se há mensagens na tabela
# ============================================================================
Write-Host "[TESTE 2] Verificando mensagens existentes..." -ForegroundColor Yellow

try {
    $messages = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/conversation_memory?select=*&order=message_timestamp.desc&limit=10" `
        -Method GET `
        -Headers @{
            "apikey" = $apiKey
            "Authorization" = "Bearer $apiKey"
        } `
        -ErrorAction Stop
    
    if ($messages.Count -eq 0) {
        Write-Host "⚠️  Nenhuma mensagem encontrada na tabela!" -ForegroundColor Yellow
        Write-Host "   Isso significa que o workflow não está salvando mensagens." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Encontradas $($messages.Count) mensagens na tabela!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Últimas 5 mensagens:" -ForegroundColor Cyan
        foreach ($msg in $messages | Select-Object -First 5) {
            Write-Host "   [$($msg.message_timestamp)] $($msg.message_role): $($msg.message_content.Substring(0, [Math]::Min(60, $msg.message_content.Length)))..." -ForegroundColor White
        }
    }
    Write-Host ""
} catch {
    Write-Host "❌ ERRO ao buscar mensagens: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# ============================================================================
# Teste 3: Testar função save_conversation_message
# ============================================================================
Write-Host "[TESTE 3] Testando função save_conversation_message..." -ForegroundColor Yellow

$testMessage = @{
    p_client_id = "estetica_bella_rede"
    p_conversation_id = 99999
    p_message_role = "user"
    p_message_content = "Teste de memória - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    p_contact_id = $null
    p_agent_id = "default"
    p_channel = "whatsapp"
    p_has_attachments = $false
    p_attachments = @()
    p_metadata = @{}
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/save_conversation_message" `
        -Method POST `
        -Headers @{
            "apikey" = $apiKey
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json"
        } `
        -Body $testMessage `
        -ErrorAction Stop
    
    Write-Host "✅ Função save_conversation_message funcionou!" -ForegroundColor Green
    Write-Host "   UUID retornado: $response" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "❌ ERRO ao chamar save_conversation_message!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# ============================================================================
# Teste 4: Testar função get_conversation_history
# ============================================================================
Write-Host "[TESTE 4] Testando função get_conversation_history..." -ForegroundColor Yellow

$testQuery = @{
    p_client_id = "estetica_bella_rede"
    p_conversation_id = 99999
    p_limit = 5
    p_hours_back = 24
} | ConvertTo-Json

try {
    $history = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/get_conversation_history" `
        -Method POST `
        -Headers @{
            "apikey" = $apiKey
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json"
        } `
        -Body $testQuery `
        -ErrorAction Stop
    
    Write-Host "✅ Função get_conversation_history funcionou!" -ForegroundColor Green
    Write-Host "   Mensagens retornadas: $($history.Count)" -ForegroundColor White
    
    if ($history.Count -gt 0) {
        Write-Host ""
        Write-Host "Histórico recuperado:" -ForegroundColor Cyan
        foreach ($msg in $history) {
            Write-Host "   [$($msg.message_timestamp)] $($msg.message_role): $($msg.message_content)" -ForegroundColor White
        }
    }
    Write-Host ""
} catch {
    Write-Host "❌ ERRO ao chamar get_conversation_history!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# ============================================================================
# Teste 5: Testar função get_memory_config (migration 021)
# ============================================================================
Write-Host "[TESTE 5] Testando função get_memory_config..." -ForegroundColor Yellow

$configQuery = @{
    p_client_id = "estetica_bella_rede"
    p_agent_id = "default"
} | ConvertTo-Json

try {
    $config = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/get_memory_config" `
        -Method POST `
        -Headers @{
            "apikey" = $apiKey
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json"
        } `
        -Body $configQuery `
        -ErrorAction Stop
    
    Write-Host "✅ Função get_memory_config funcionou!" -ForegroundColor Green
    Write-Host "   Config: $($config | ConvertTo-Json -Compress)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "❌ ERRO ao chamar get_memory_config!" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# ============================================================================
# Resumo Final
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESUMO DOS TESTES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Se algum teste falhou, verifique:" -ForegroundColor Yellow
Write-Host "1. Migration 019 foi executada? (conversation_memory)" -ForegroundColor White
Write-Host "2. Migration 020 foi executada? (p_hours_back)" -ForegroundColor White
Write-Host "3. Migration 021 foi executada? (memory_config)" -ForegroundColor White
Write-Host "4. RLS policies estão corretas?" -ForegroundColor White
Write-Host "5. Workflow n8n está executando os nodes de memória?" -ForegroundColor White
Write-Host ""

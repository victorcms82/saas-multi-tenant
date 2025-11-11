# ============================================================================
# VALIDAR FIXES APLICADOS - Executar apos SQL + n8n
# ============================================================================

$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
$BASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"

Write-Host "`n🔍 VALIDACAO COMPLETA DOS FIXES" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Gray

$allOk = $true

# 1. Validar system_prompt corrigido
Write-Host "`n[1/4] Validando system_prompt (encoding)..." -ForegroundColor Yellow

try {
    $agent = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/agents?client_id=eq.estetica_bella_rede&agent_id=eq.default&select=system_prompt" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    $prompt = $agent[0].system_prompt
    
    if ($prompt -like "*Ã*" -or $prompt -like "*©*") {
        Write-Host "   ❌ AINDA COM ENCODING ERRADO!" -ForegroundColor Red
        Write-Host "      $($prompt.Substring(0, 50))..." -ForegroundColor Gray
        $allOk = $false
    } else {
        Write-Host "   ✅ Encoding corrigido!" -ForegroundColor Green
        Write-Host "      $($prompt.Substring(0, 50))..." -ForegroundColor Gray
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
    $allOk = $false
}

# 2. Validar location Clinica Sorriso inserida
Write-Host "`n[2/4] Validando location Clinica Sorriso..." -ForegroundColor Yellow

try {
    $loc = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/locations?chatwoot_inbox_id=eq.1&select=client_id,name,location_id" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    if ($loc.Count -gt 0) {
        Write-Host "   ✅ Location encontrada!" -ForegroundColor Green
        Write-Host "      client_id: $($loc[0].client_id)" -ForegroundColor Gray
        Write-Host "      name: $($loc[0].name)" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Location NAO encontrada!" -ForegroundColor Red
        $allOk = $false
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
    $allOk = $false
}

# 3. Validar RPC retorna client_id correto
Write-Host "`n[3/4] Validando RPC para ambos os inboxes..." -ForegroundColor Yellow

try {
    # Bella (inbox_id=3)
    $bella = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/rpc/get_location_staff_summary" `
        -Method Post `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
            'Content-Type' = 'application/json'
        } `
        -Body '{"p_inbox_id":3}' `
        -ContentType 'application/json'
    
    if ($bella[0].client_id -eq 'estetica_bella_rede') {
        Write-Host "   ✅ inbox_id=3 → client_id correto (estetica_bella_rede)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ inbox_id=3 → client_id ERRADO: $($bella[0].client_id)" -ForegroundColor Red
        $allOk = $false
    }
    
    # Clinica Sorriso (inbox_id=1)
    $sorriso = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/rpc/get_location_staff_summary" `
        -Method Post `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
            'Content-Type' = 'application/json'
        } `
        -Body '{"p_inbox_id":1}' `
        -ContentType 'application/json'
    
    if ($sorriso[0].client_id -eq 'clinica_sorriso_001') {
        Write-Host "   ✅ inbox_id=1 → client_id correto (clinica_sorriso_001)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ inbox_id=1 → client_id ERRADO ou vazio: '$($sorriso[0].client_id)'" -ForegroundColor Red
        $allOk = $false
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
    $allOk = $false
}

# 4. Lembrete do fix n8n
Write-Host "`n[4/4] Checklist n8n..." -ForegroundColor Yellow
Write-Host "   ⚠️ IMPORTANTE: Verifique manualmente no n8n:" -ForegroundColor Yellow
Write-Host "      1. Node 'Construir Contexto Completo' foi editado?" -ForegroundColor Gray
Write-Host "      2. Codigo tem 'locationNode.client_id'?" -ForegroundColor Gray
Write-Host "      3. Workflow foi salvo e ativado?" -ForegroundColor Gray

# RESULTADO FINAL
Write-Host "`n" + ("=" * 80) -ForegroundColor Gray

if ($allOk) {
    Write-Host "🎉 TODOS OS FIXES APLICADOS COM SUCESSO!" -ForegroundColor Green
    Write-Host "`n📱 PROXIMO PASSO: Testar via WhatsApp" -ForegroundColor Cyan
    Write-Host "   Enviar: 'Quais profissionais voces tem?'" -ForegroundColor White
    Write-Host "   Esperado: Ana Paula Silva, Beatriz Costa, Carlos..." -ForegroundColor Gray
} else {
    Write-Host "⚠️ ALGUNS FIXES FALHARAM!" -ForegroundColor Red
    Write-Host "   Revise as mensagens acima e tente novamente." -ForegroundColor Yellow
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray

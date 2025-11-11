# ============================================================================
# TESTE DE SEGURANCA: Validar client_id Blindagem
# ============================================================================

$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
$BASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"

Write-Host "`n🔐 TESTE DE SEGURANCA: client_id Blindagem" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Gray

# Teste 1: RPC para inbox_id=3 (Bella Estetica)
Write-Host "`n[1/4] Testando RPC para inbox_id=3 (Bella Estetica)..." -ForegroundColor Yellow

try {
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
    
    Write-Host "   ✅ RPC respondeu!" -ForegroundColor Green
    Write-Host "   📍 client_id: " -NoNewline
    
    if ($bella[0].client_id -eq 'estetica_bella_rede') {
        Write-Host $bella[0].client_id -ForegroundColor Green
        Write-Host "   ✅ client_id CORRETO!" -ForegroundColor Green
    } else {
        Write-Host $bella[0].client_id -ForegroundColor Red
        Write-Host "   ❌ client_id ERRADO! Esperado: estetica_bella_rede" -ForegroundColor Red
    }
    
    Write-Host "   🏢 location_name: $($bella[0].location_name)" -ForegroundColor Gray
    Write-Host "   👥 total_staff: $($bella[0].total_staff)" -ForegroundColor Gray
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 2: RPC para inbox_id=1 (Clinica Sorriso)
Write-Host "`n[2/4] Testando RPC para inbox_id=1 (Clinica Sorriso)..." -ForegroundColor Yellow

try {
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
    
    Write-Host "   ✅ RPC respondeu!" -ForegroundColor Green
    Write-Host "   📍 client_id: " -NoNewline
    
    if ($sorriso[0].client_id -eq 'clinica_sorriso_001') {
        Write-Host $sorriso[0].client_id -ForegroundColor Green
        Write-Host "   ✅ client_id CORRETO!" -ForegroundColor Green
    } else {
        Write-Host $sorriso[0].client_id -ForegroundColor Red
        Write-Host "   ❌ client_id ERRADO! Esperado: clinica_sorriso_001" -ForegroundColor Red
    }
    
    Write-Host "   🏢 location_name: $($sorriso[0].location_name)" -ForegroundColor Gray
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 3: Buscar agent para Bella Estetica
Write-Host "`n[3/4] Testando busca de agent para Bella Estetica..." -ForegroundColor Yellow

try {
    $agent = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/agents?client_id=eq.estetica_bella_rede&agent_id=eq.default&select=client_id,agent_id,system_prompt" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    if ($agent.Count -gt 0) {
        Write-Host "   ✅ Agent encontrado!" -ForegroundColor Green
        Write-Host "   📍 client_id: $($agent[0].client_id)" -ForegroundColor Gray
        Write-Host "   🤖 agent_id: $($agent[0].agent_id)" -ForegroundColor Gray
        
        # Verificar se é o system prompt correto
        if ($agent[0].system_prompt -like "*Bella*Estética*" -or $agent[0].system_prompt -like "*Bella*Estetica*") {
            Write-Host "   ✅ System prompt correto (menciona Bella Estética)!" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ System prompt não menciona Bella Estética!" -ForegroundColor Yellow
            Write-Host "   Primeiras 100 chars: $($agent[0].system_prompt.Substring(0, [Math]::Min(100, $agent[0].system_prompt.Length)))..." -ForegroundColor Gray
        }
    } else {
        Write-Host "   ❌ Nenhum agent encontrado para estetica_bella_rede!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 4: Buscar staff para Bella Barra
Write-Host "`n[4/4] Testando busca de staff para Bella Barra..." -ForegroundColor Yellow

try {
    $staff = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/staff?client_id=eq.estetica_bella_rede&select=name,role" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    if ($staff.Count -gt 0) {
        Write-Host "   ✅ Staff encontrado: $($staff.Count) profissionais" -ForegroundColor Green
        foreach ($person in $staff) {
            Write-Host "      - $($person.name) ($($person.role))" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ❌ Nenhum staff encontrado!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

# RESUMO
Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "📊 RESUMO DO TESTE" -ForegroundColor Cyan
Write-Host "`n🔍 DIAGNOSTICO:" -ForegroundColor Yellow

Write-Host "`n1️⃣ RPC retorna client_id correto?" -ForegroundColor White
if ($bella[0].client_id -eq 'estetica_bella_rede' -and $sorriso[0].client_id -eq 'clinica_sorriso_001') {
    Write-Host "   ✅ SIM - Banco de dados funcionando corretamente" -ForegroundColor Green
} else {
    Write-Host "   ❌ NAO - Problema na Migration 013b!" -ForegroundColor Red
}

Write-Host "`n2️⃣ Agent tem system_prompt correto?" -ForegroundColor White
if ($agent.Count -gt 0) {
    Write-Host "   ✅ SIM - Agent configurado" -ForegroundColor Green
} else {
    Write-Host "   ❌ NAO - Agent não encontrado!" -ForegroundColor Red
}

Write-Host "`n3️⃣ Staff está cadastrado?" -ForegroundColor White
if ($staff.Count -gt 0) {
    Write-Host "   ✅ SIM - $($staff.Count) profissionais" -ForegroundColor Green
} else {
    Write-Host "   ❌ NAO - Staff não cadastrado!" -ForegroundColor Red
}

Write-Host "`n🚨 PROXIMA ACAO:" -ForegroundColor Yellow
Write-Host "   Se todos os testes passaram mas bot ainda responde errado," -ForegroundColor White
Write-Host "   o problema está no WORKFLOW do n8n!" -ForegroundColor White
Write-Host "`n   📝 SOLUCAO:" -ForegroundColor Cyan
Write-Host "   1. Abrir n8n → WF0-Gestor-Universal" -ForegroundColor Gray
Write-Host "   2. Editar node 'Construir Contexto Completo'" -ForegroundColor Gray
Write-Host "   3. Aplicar o código de FIX-CONSTRUIR-CONTEXTO-COMPLETO.js" -ForegroundColor Gray
Write-Host "   4. Salvar e ativar workflow" -ForegroundColor Gray

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "✨ Teste finalizado!" -ForegroundColor Cyan

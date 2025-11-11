# ============================================================================
# FIX URGENTE: Corrigir todos os problemas identificados
# ============================================================================

$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
$BASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"

Write-Host "`n🔧 FIX URGENTE: Corrigindo Problemas" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Gray

# FIX 1: Verificar dados da tabela locations
Write-Host "`n[1/3] Verificando tabela locations..." -ForegroundColor Yellow

try {
    $locations = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/locations?select=location_id,client_id,name,chatwoot_inbox_id,is_active&order=chatwoot_inbox_id" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    Write-Host "   ✅ Locations encontradas: $($locations.Count)" -ForegroundColor Green
    
    foreach ($loc in $locations) {
        Write-Host "`n   📍 Location: $($loc.name)" -ForegroundColor Cyan
        Write-Host "      client_id: $($loc.client_id)" -ForegroundColor Gray
        Write-Host "      location_id: $($loc.location_id)" -ForegroundColor Gray
        Write-Host "      inbox_id: $($loc.chatwoot_inbox_id)" -ForegroundColor Gray
        Write-Host "      is_active: $($loc.is_active)" -ForegroundColor Gray
        
        # Validar se inbox_id 1 tem client_id
        if ($loc.chatwoot_inbox_id -eq 1 -and [string]::IsNullOrEmpty($loc.client_id)) {
            Write-Host "      ❌ PROBLEMA: inbox_id=1 sem client_id!" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

# FIX 2: Verificar system_prompt com encoding errado
Write-Host "`n[2/3] Verificando system_prompt de Bella Estetica..." -ForegroundColor Yellow

try {
    $agent = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/agents?client_id=eq.estetica_bella_rede&agent_id=eq.default&select=client_id,agent_id,system_prompt" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    if ($agent.Count -gt 0) {
        $prompt = $agent[0].system_prompt
        
        # Verificar encoding
        if ($prompt -like "*VocÃª*" -or $prompt -like "*Ã©*") {
            Write-Host "   ❌ System prompt com encoding ERRADO!" -ForegroundColor Red
            Write-Host "   Primeira linha: $($prompt.Split("`n")[0].Substring(0, [Math]::Min(80, $prompt.Split("`n")[0].Length)))" -ForegroundColor Gray
            
            Write-Host "`n   📝 SOLUCAO: Precisa atualizar via SQL Editor" -ForegroundColor Yellow
            Write-Host "   1. Abrir: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql" -ForegroundColor Blue
            Write-Host "   2. Executar:" -ForegroundColor Gray
            Write-Host @"
            
   UPDATE agents
   SET system_prompt = 'Voce e um assistente de uma rede de clinicas de estetica chamada Bella Estetica...'
   WHERE client_id = 'estetica_bella_rede' AND agent_id = 'default';
   
"@ -ForegroundColor DarkGray
            
        } else {
            Write-Host "   ✅ System prompt OK" -ForegroundColor Green
        }
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

# FIX 3: Verificar media_rules (imagem enviada)
Write-Host "`n[3/3] Verificando media_rules para 'profissionais'..." -ForegroundColor Yellow

try {
    $media = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/media_rules?client_id=eq.estetica_bella_rede&select=rule_id,trigger_type,trigger_value,media_id,client_id" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    if ($media.Count -gt 0) {
        Write-Host "   ✅ Media rules encontradas: $($media.Count)" -ForegroundColor Green
        
        foreach ($rule in $media) {
            if ($rule.trigger_value -like "*profissiona*" -or $rule.trigger_value -like "*equipe*") {
                Write-Host "`n   📎 Regra: $($rule.trigger_type) - '$($rule.trigger_value)'" -ForegroundColor Cyan
                Write-Host "      client_id: $($rule.client_id)" -ForegroundColor Gray
                Write-Host "      media_id: $($rule.media_id)" -ForegroundColor Gray
                
                if ($rule.client_id -ne 'estetica_bella_rede') {
                    Write-Host "      ❌ PROBLEMA: Media com client_id errado!" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "   ⚠️ Nenhuma media rule encontrada" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "📋 RESUMO DOS PROBLEMAS ENCONTRADOS:" -ForegroundColor Cyan

Write-Host "`n1. Migration 013b incompleta" -ForegroundColor White
Write-Host "   - inbox_id=1 (Clinica Sorriso) retorna client_id vazio" -ForegroundColor Gray
Write-Host "   - Provavelmente location nao tem client_id preenchido" -ForegroundColor Gray

Write-Host "`n2. System prompt com encoding errado" -ForegroundColor White
Write-Host "   - 'VocÃª Ã©' ao inves de 'Voce e'" -ForegroundColor Gray
Write-Host "   - Precisa atualizar no banco via SQL Editor" -ForegroundColor Gray

Write-Host "`n3. Possivel problema de media_rules" -ForegroundColor White
Write-Host "   - Bot pode estar buscando media do client errado" -ForegroundColor Gray
Write-Host "   - Verificar RPC find_matching_media_rules" -ForegroundColor Gray

Write-Host "`n🎯 ACOES IMEDIATAS:" -ForegroundColor Yellow
Write-Host "   1. Atualizar client_id na tabela locations para inbox_id=1" -ForegroundColor White
Write-Host "   2. Corrigir encoding do system_prompt" -ForegroundColor White
Write-Host "   3. Verificar se FIX foi aplicado no node n8n" -ForegroundColor White

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray

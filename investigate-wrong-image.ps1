# ============================================================================
# INVESTIGAR: Por que imagem da Clinica Sorriso esta sendo enviada
# ============================================================================

$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
$BASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"

Write-Host "`n🔍 INVESTIGACAO: Imagem Errada sendo Enviada" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Gray

# HIPOTESE 1: Media cadastrada com client_id errado
Write-Host "`n[TESTE 1] Verificar client_media..." -ForegroundColor Yellow

try {
    $allMedia = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/client_media?select=media_id,client_id,title,file_name" `
        -Method Get `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
        }
    
    Write-Host "   Total de midias: $($allMedia.Count)" -ForegroundColor Cyan
    
    $problemFound = $false
    
    foreach ($m in $allMedia) {
        if ($m.title -like "*Equipe*" -or $m.title -like "*Clinica*" -or $m.title -like "*Sorriso*") {
            Write-Host "`n   📷 Titulo: $($m.title)" -ForegroundColor White
            Write-Host "      media_id: $($m.media_id)" -ForegroundColor Gray
            Write-Host "      file_name: $($m.file_name)" -ForegroundColor Gray
            Write-Host "      client_id: " -NoNewline
            
            if ($m.title -like "*Sorriso*" -and $m.client_id -ne 'clinica_sorriso_001') {
                Write-Host $m.client_id -ForegroundColor Red
                Write-Host "      ❌ PROBLEMA: Imagem da Sorriso com client_id errado!" -ForegroundColor Red
                $problemFound = $true
            } elseif ($m.title -like "*Bella*" -and $m.client_id -ne 'estetica_bella_rede') {
                Write-Host $m.client_id -ForegroundColor Red
                Write-Host "      ❌ PROBLEMA: Imagem da Bella com client_id errado!" -ForegroundColor Red
                $problemFound = $true
            } else {
                Write-Host $m.client_id -ForegroundColor Green
            }
        }
    }
    
    if (-not $problemFound) {
        Write-Host "`n   ✅ Todas as midias tem client_id correto" -ForegroundColor Green
    }
    
} catch {
    Write-Host "   ❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
}

# HIPOTESE 2: N8N buscando midia com client_id errado
Write-Host "`n[TESTE 2] Simular busca do n8n (com client_id errado)..." -ForegroundColor Yellow

# Simular o que o workflow PODE estar fazendo (usando client_id errado)
try {
    Write-Host "   Simulando: find_matching_media com client_id='clinica_sorriso_001'" -ForegroundColor Gray
    
    $wrongMedia = Invoke-RestMethod `
        -Uri "$BASE_URL/rest/v1/rpc/find_matching_media_rules" `
        -Method Post `
        -Headers @{
            'apikey' = $ANON_KEY
            'Authorization' = "Bearer $ANON_KEY"
            'Content-Type' = 'application/json'
        } `
        -Body '{"p_client_id":"clinica_sorriso_001","p_message":"Quais profissionais voces tem?"}' `
        -ContentType 'application/json'
    
    if ($wrongMedia) {
        Write-Host "   ❌ RPC RETORNOU MIDIA COM client_id ERRADO!" -ForegroundColor Red
        Write-Host "   Isso prova que o workflow esta usando client_id errado!" -ForegroundColor Red
        Write-Host "   Media retornada:" -ForegroundColor Yellow
        $wrongMedia | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Gray
    } else {
        Write-Host "   ✅ RPC nao retornou midia (correto)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "   ❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
}

# HIPOTESE 3: Workflow ainda nao aplicou o fix
Write-Host "`n[TESTE 3] Verificar se fix foi realmente aplicado..." -ForegroundColor Yellow
Write-Host "   ⚠️ MANUAL: Verificar no n8n se o codigo do node tem:" -ForegroundColor Yellow
Write-Host "   const locationNode = \$('💼 Construir Contexto Location + Staff1').first().json;" -ForegroundColor Gray
Write-Host "   const clientId = locationNode.client_id;" -ForegroundColor Gray

# DIAGNOSTICO FINAL
Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "📊 DIAGNOSTICO:" -ForegroundColor Cyan

Write-Host "`n🔍 CAUSAS POSSIVEIS:" -ForegroundColor Yellow
Write-Host "   1. Midia cadastrada com client_id errado no banco" -ForegroundColor White
Write-Host "   2. N8N usando client_id errado ao buscar midia (FIX NAO APLICADO)" -ForegroundColor White
Write-Host "   3. Cache do n8n/Redis usando dados antigos" -ForegroundColor White
Write-Host "   4. Workflow nao foi salvo corretamente" -ForegroundColor White

Write-Host "`n💡 PROXIMAS ACOES:" -ForegroundColor Cyan
Write-Host "   1. Verificar tabela client_media e corrigir client_id se necessario" -ForegroundColor White
Write-Host "   2. Confirmar que fix foi aplicado no n8n (ver logs do node)" -ForegroundColor White
Write-Host "   3. Reiniciar n8n para limpar cache" -ForegroundColor White

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray

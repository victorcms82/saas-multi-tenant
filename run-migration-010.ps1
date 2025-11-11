# EXECUTAR MIGRATION 010 - RPC check_media_triggers

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

Write-Host "`n🔧 MIGRATION 010: Criar RPC check_media_triggers" -ForegroundColor Cyan
Write-Host "=" * 70

# Ler SQL
$sqlPath = ".\database\migrations\010_create_rpc_check_media_triggers.sql"
$sql = Get-Content $sqlPath -Raw

Write-Host "`n📄 Executando SQL..." -ForegroundColor Yellow

try {
    # Executar via REST API (SQL direto)
    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers @{
            'apikey' = $SUPABASE_SERVICE_KEY
            'Authorization' = "Bearer $SUPABASE_SERVICE_KEY"
            'Content-Type' = 'application/json'
        } `
        -Body (@{ query = $sql } | ConvertTo-Json)
    
    Write-Host "✅ Function criada com sucesso!" -ForegroundColor Green
} catch {
    # Alternativa: Via SQL Editor manual
    Write-Host "⚠️  Não foi possível executar via API" -ForegroundColor Yellow
    Write-Host "📋 Execute manualmente no Supabase SQL Editor:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Abrir: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql" -ForegroundColor White
    Write-Host "2. Copiar conteúdo de: $sqlPath" -ForegroundColor White
    Write-Host "3. Colar no editor e executar (RUN)" -ForegroundColor White
    Write-Host ""
    
    Read-Host "Pressione ENTER após executar no Supabase SQL Editor"
}

Write-Host "`n🧪 Testando RPC..." -ForegroundColor Yellow

$testBody = @{
    p_client_id = "clinica_sorriso_001"
    p_agent_id = "default"
    p_message = "quero ver a clínica"
} | ConvertTo-Json

try {
    $testResult = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/check_media_triggers" `
        -Method POST `
        -Headers @{
            'apikey' = $SUPABASE_SERVICE_KEY
            'Authorization' = "Bearer $SUPABASE_SERVICE_KEY"
            'Content-Type' = 'application/json'
        } `
        -Body $testBody
    
    Write-Host "✅ RPC funcionando!" -ForegroundColor Green
    Write-Host "`n📊 Resultado:" -ForegroundColor Cyan
    $testResult | Format-List rule_id, media_id, title, file_url, trigger_value
    
    if ($testResult) {
        Write-Host "`n✅ SUCESSO! Mídia detectada:" -ForegroundColor Green
        Write-Host "   Título: $($testResult.title)" -ForegroundColor White
        Write-Host "   Trigger: $($testResult.trigger_value)" -ForegroundColor White
        Write-Host ""
        Write-Host "🚀 PRONTO PARA ADICIONAR AO WORKFLOW!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Nenhuma mídia encontrada (verificar triggers)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Erro ao testar RPC: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 70)
Write-Host "🏁 MIGRATION CONCLUÍDA" -ForegroundColor Cyan
Write-Host ""

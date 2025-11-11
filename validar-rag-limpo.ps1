# ============================================================================
# VALIDAR RAG LIMPO - Verificar se não há contaminação
# ============================================================================

Write-Host "`n🔍 VALIDANDO RAG APÓS LIMPEZA..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# Configuração
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
}

# Detectar tabela de vetores
$possibleTables = @("documents", "embeddings", "vectors", "knowledge_base", "rag_documents")
$VECTOR_TABLE = $null

foreach ($table in $possibleTables) {
    try {
        Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$table?select=*&limit=1" `
            -Method Get `
            -Headers $headers `
            -ErrorAction SilentlyContinue | Out-Null
        
        $VECTOR_TABLE = $table
        break
    } catch {}
}

if (-not $VECTOR_TABLE) {
    Write-Host "❌ Tabela não encontrada. Informe manualmente:" -ForegroundColor Red
    $VECTOR_TABLE = Read-Host "Nome da tabela"
}

Write-Host "`n📊 Tabela: $VECTOR_TABLE`n" -ForegroundColor Cyan

# ============================================================================
# TESTE 1: Buscar "Clinica Sorriso" em Bella Estética
# ============================================================================

Write-Host "[1/4] 🔍 Buscar 'Clinica Sorriso' em estetica_bella_rede..." -ForegroundColor Yellow

$filter = "client_id=eq.estetica_bella_rede&content=ilike.*Clinica*Sorriso*"
$response = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/$VECTOR_TABLE?select=id,content&$filter" `
    -Method Get `
    -Headers $headers

if ($response.Count -eq 0) {
    Write-Host "  ✅ PASSOU: Nenhum documento com 'Clinica Sorriso'" -ForegroundColor Green
} else {
    Write-Host "  ❌ FALHOU: Ainda há $($response.Count) documentos contaminados!" -ForegroundColor Red
    $response | ForEach-Object {
        Write-Host "    ID: $($_.id)" -ForegroundColor Yellow
    }
}

# ============================================================================
# TESTE 2: Buscar "odontologia" em Bella Estética
# ============================================================================

Write-Host "`n[2/4] 🔍 Buscar 'odontologia' em estetica_bella_rede..." -ForegroundColor Yellow

$filter = "client_id=eq.estetica_bella_rede&content=ilike.*odontologia*"
$response = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/$VECTOR_TABLE?select=id,content&$filter" `
    -Method Get `
    -Headers $headers

if ($response.Count -eq 0) {
    Write-Host "  ✅ PASSOU: Nenhum documento sobre odontologia" -ForegroundColor Green
} else {
    Write-Host "  ❌ FALHOU: Há $($response.Count) documentos sobre odontologia!" -ForegroundColor Red
}

# ============================================================================
# TESTE 3: Buscar "dentista" em Bella Estética
# ============================================================================

Write-Host "`n[3/4] 🔍 Buscar 'dentista' em estetica_bella_rede..." -ForegroundColor Yellow

$filter = "client_id=eq.estetica_bella_rede&content=ilike.*dentista*"
$response = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/$VECTOR_TABLE?select=id,content&$filter" `
    -Method Get `
    -Headers $headers

if ($response.Count -eq 0) {
    Write-Host "  ✅ PASSOU: Nenhum documento sobre dentistas" -ForegroundColor Green
} else {
    Write-Host "  ❌ FALHOU: Há $($response.Count) documentos sobre dentistas!" -ForegroundColor Red
}

# ============================================================================
# TESTE 4: Contar documentos válidos de Bella Estética
# ============================================================================

Write-Host "`n[4/4] 📊 Contar documentos válidos da Bella Estética..." -ForegroundColor Yellow

$filter = "client_id=eq.estetica_bella_rede"
$response = Invoke-RestMethod `
    -Uri "$SUPABASE_URL/rest/v1/$VECTOR_TABLE?select=id&$filter" `
    -Method Get `
    -Headers $headers

Write-Host "  📦 Total de documentos: $($response.Count)" -ForegroundColor Cyan

if ($response.Count -eq 0) {
    Write-Host "  ⚠️  ATENÇÃO: Não há documentos da Bella Estética!" -ForegroundColor Yellow
    Write-Host "  Você pode ter deletado TODOS os documentos." -ForegroundColor Yellow
    Write-Host "  Será necessário fazer re-upload de documentos válidos." -ForegroundColor White
}

# ============================================================================
# RELATÓRIO FINAL
# ============================================================================

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "📋 RELATÓRIO DE VALIDAÇÃO" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray

Write-Host "`n✅ RAG está limpo se todos os testes passaram" -ForegroundColor Green
Write-Host "⚠️  Se houver documentos contaminados, execute novamente:" -ForegroundColor Yellow
Write-Host "   .\limpar-rag-supabase.ps1" -ForegroundColor White

Write-Host "`n🎯 PRÓXIMO PASSO:" -ForegroundColor Cyan
Write-Host "   Testar no WhatsApp com mensagens reais!" -ForegroundColor White
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray

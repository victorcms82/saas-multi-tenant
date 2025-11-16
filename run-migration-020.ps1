# ============================================================================
# EXECUTAR MIGRATION 020: Sistema RAG com pgvector
# ============================================================================
# Descrição: Executa migration SQL via Supabase REST API
# Data: 16/11/2025
# ============================================================================

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "🚀 EXECUTANDO MIGRATION 020: Sistema RAG" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Ler arquivo SQL
$migrationPath = Join-Path $PSScriptRoot "database\migrations\020_create_rag_system.sql"
Write-Host "📄 Lendo arquivo: $migrationPath" -ForegroundColor Yellow

if (-not (Test-Path $migrationPath)) {
    Write-Host "❌ ERRO: Arquivo não encontrado!" -ForegroundColor Red
    exit 1
}

$sqlContent = Get-Content -Path $migrationPath -Raw -Encoding UTF8
Write-Host "✅ Arquivo lido com sucesso ($(($sqlContent.Length / 1024).ToString('0.0')) KB)" -ForegroundColor Green
Write-Host ""

# Headers para Supabase
$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

Write-Host "🔧 Executando SQL no Supabase..." -ForegroundColor Yellow
Write-Host ""

try {
    # Executar SQL via RPC exec_sql
    $body = @{
        query = $sqlContent
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -ContentType "application/json"

    Write-Host "✅ SQL executado com sucesso!" -ForegroundColor Green
    Write-Host ""
    
    if ($response) {
        Write-Host "📊 Resposta:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 10 | Write-Host
    }
    
} catch {
    $errorMessage = $_.Exception.Message
    $errorDetails = $_.ErrorDetails.Message
    
    Write-Host "❌ ERRO ao executar SQL!" -ForegroundColor Red
    Write-Host "Mensagem: $errorMessage" -ForegroundColor Red
    
    if ($errorDetails) {
        Write-Host "Detalhes:" -ForegroundColor Red
        $errorDetails | Write-Host
    }
    
    Write-Host ""
    Write-Host "💡 Tentando execução direta via SQL Editor..." -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# Verificar resultado
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "🔍 VERIFICANDO INSTALAÇÃO" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar extensão vector
Write-Host "1️⃣ Verificando extensão vector..." -ForegroundColor Yellow
try {
    $checkExtension = @{
        query = "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector') as exists;"
    } | ConvertTo-Json

    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body $checkExtension `
        -ContentType "application/json"

    Write-Host "   ✅ Extensão vector instalada" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Não foi possível verificar extensão" -ForegroundColor Yellow
}

# Verificar tabela rag_documents
Write-Host "2️⃣ Verificando tabela rag_documents..." -ForegroundColor Yellow
try {
    $checkTable = @{
        query = "SELECT COUNT(*) as count FROM rag_documents;"
    } | ConvertTo-Json

    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body $checkTable `
        -ContentType "application/json"

    Write-Host "   ✅ Tabela rag_documents criada (documentos: $($result.count))" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Tabela rag_documents não encontrada" -ForegroundColor Red
}

# Verificar function query_rag_documents
Write-Host "3️⃣ Verificando function query_rag_documents..." -ForegroundColor Yellow
try {
    $checkFunction = @{
        query = "SELECT EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'query_rag_documents') as exists;"
    } | ConvertTo-Json

    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body $checkFunction `
        -ContentType "application/json"

    Write-Host "   ✅ Function query_rag_documents criada" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Function query_rag_documents não encontrada" -ForegroundColor Red
}

# Verificar function save_rag_document
Write-Host "4️⃣ Verificando function save_rag_document..." -ForegroundColor Yellow
try {
    $checkSave = @{
        query = "SELECT EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'save_rag_document') as exists;"
    } | ConvertTo-Json

    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body $checkSave `
        -ContentType "application/json"

    Write-Host "   ✅ Function save_rag_document criada" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Function save_rag_document não encontrada" -ForegroundColor Red
}

# Verificar view rag_statistics
Write-Host "5️⃣ Verificando view rag_statistics..." -ForegroundColor Yellow
try {
    $checkView = @{
        query = "SELECT * FROM rag_statistics LIMIT 1;"
    } | ConvertTo-Json

    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body $checkView `
        -ContentType "application/json"

    Write-Host "   ✅ View rag_statistics criada" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ View rag_statistics não verificada" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "✅ MIGRATION 020 CONCLUÍDA!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Atualizar node Query RAG no workflow principal" -ForegroundColor White
Write-Host "   2. Importar workflow RAG-INGESTION-WORKFLOW.json no n8n" -ForegroundColor White
Write-Host "   3. Testar upload de documento de teste" -ForegroundColor White
Write-Host ""
Write-Host "📖 Ver guia completo: workflows\GUIA-IMPLEMENTACAO-RAG.md" -ForegroundColor Cyan
Write-Host ""

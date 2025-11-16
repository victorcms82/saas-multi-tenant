# ============================================================================
# EXECUTAR MIGRATION 020: Sistema RAG com pgvector (Direto)
# ============================================================================
# Executa SQL dividido em blocos via SQL Editor do Supabase
# ============================================================================

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
}

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "🚀 MIGRATION 020: Sistema RAG - Execução Manual" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# BLOCO 1: Criar extensão vector
# ============================================================================

Write-Host "1️⃣ Criando extensão pgvector..." -ForegroundColor Yellow

$sql1 = "CREATE EXTENSION IF NOT EXISTS vector;"

try {
    $response = Invoke-WebRequest `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $headers `
        -Body (@{ query = $sql1 } | ConvertTo-Json) `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "   ✅ Extensão vector criada" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Executar manualmente no SQL Editor do Supabase:" -ForegroundColor Yellow
    Write-Host "   $sql1" -ForegroundColor White
}

Write-Host ""

# ============================================================================
# Instruções para execução manual
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "📋 INSTRUÇÕES PARA EXECUÇÃO MANUAL" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "A API REST do Supabase não suporta execução de DDL complexo." -ForegroundColor Yellow
Write-Host "Por favor, execute manualmente seguindo os passos:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣ Acesse o SQL Editor do Supabase:" -ForegroundColor White
Write-Host "   https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql" -ForegroundColor Cyan
Write-Host ""

Write-Host "2️⃣ Copie o conteúdo do arquivo:" -ForegroundColor White
Write-Host "   database\migrations\020_create_rag_system.sql" -ForegroundColor Cyan
Write-Host ""

Write-Host "3️⃣ Cole no SQL Editor e clique em 'Run'" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ Aguarde a execução (pode levar 10-20 segundos)" -ForegroundColor White
Write-Host ""

Write-Host "5️⃣ Verifique as mensagens de sucesso:" -ForegroundColor White
Write-Host "   ✅ Extensão vector: OK" -ForegroundColor Green
Write-Host "   ✅ Tabela rag_documents: OK" -ForegroundColor Green
Write-Host "   ✅ Function query_rag_documents: OK" -ForegroundColor Green
Write-Host "   ✅ Function save_rag_document: OK" -ForegroundColor Green
Write-Host "   ✅ View rag_statistics: OK" -ForegroundColor Green
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "⏸️  AGUARDANDO EXECUÇÃO MANUAL..." -ForegroundColor Yellow
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "Pressione ENTER após executar o SQL no Supabase (ou 'n' para cancelar)"

if ($continue -eq 'n') {
    Write-Host "❌ Cancelado pelo usuário" -ForegroundColor Red
    exit 0
}

# ============================================================================
# Verificar instalação
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "🔍 VERIFICANDO INSTALAÇÃO" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar tabela via REST API
Write-Host "1️⃣ Verificando tabela rag_documents..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rag_documents?select=id&limit=1" `
        -Method GET `
        -Headers $headers `
        -ErrorAction Stop

    Write-Host "   ✅ Tabela rag_documents criada e acessível" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Erro ao acessar tabela: $($_.Exception.Message)" -ForegroundColor Red
}

# Verificar RPC query_rag_documents
Write-Host "2️⃣ Verificando RPC query_rag_documents..." -ForegroundColor Yellow
try {
    # Criar embedding fake para teste
    $fakeEmbedding = @(0.0) * 1536
    
    $testBody = @{
        p_client_id = "test"
        p_agent_id = "default"
        p_query_embedding = $fakeEmbedding
        p_limit = 1
        p_threshold = 0.7
    } | ConvertTo-Json -Compress

    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/query_rag_documents" `
        -Method POST `
        -Headers $headers `
        -Body $testBody `
        -ContentType "application/json" `
        -ErrorAction Stop

    Write-Host "   ✅ RPC query_rag_documents funcionando" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ RPC pode não estar acessível via REST: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Verificar RPC save_rag_document
Write-Host "3️⃣ Verificando RPC save_rag_document..." -ForegroundColor Yellow
try {
    # Criar embedding fake para teste
    $fakeEmbedding = @(0.0) * 1536
    
    $testBody = @{
        p_client_id = "test-migration"
        p_agent_id = "default"
        p_content = "Teste de migration RAG"
        p_embedding = $fakeEmbedding
        p_file_name = "teste.txt"
    } | ConvertTo-Json -Compress

    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/save_rag_document" `
        -Method POST `
        -Headers $headers `
        -Body $testBody `
        -ContentType "application/json" `
        -ErrorAction Stop

    Write-Host "   ✅ RPC save_rag_document funcionando (doc_id: $response)" -ForegroundColor Green
    
    # Limpar teste
    Write-Host "   🧹 Limpando documento de teste..." -ForegroundColor Gray
    Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rag_documents?client_id=eq.test-migration" `
        -Method DELETE `
        -Headers $headers `
        -ErrorAction SilentlyContinue | Out-Null
        
} catch {
    Write-Host "   ⚠️ Erro ao testar RPC: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "✅ VERIFICAÇÃO CONCLUÍDA" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Atualizar node Query RAG no n8n" -ForegroundColor White
Write-Host "      Copiar: workflows\CODIGO-QUERY-RAG-REAL.js" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. Importar workflow de ingestion" -ForegroundColor White
Write-Host "      Arquivo: workflows\RAG-INGESTION-WORKFLOW.json" -ForegroundColor Cyan
Write-Host ""
Write-Host "   3. Testar com documento real" -ForegroundColor White
Write-Host "      Ver: workflows\GUIA-IMPLEMENTACAO-RAG.md" -ForegroundColor Cyan
Write-Host ""

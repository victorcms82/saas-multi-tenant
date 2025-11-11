# ============================================================================
# DESCOBRIR TABELA DE RAG NO SUPABASE
# ============================================================================

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
}

Write-Host "`n🔍 DESCOBRINDO TABELAS NO SUPABASE..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# Método 1: Tentar RPC para listar tabelas
Write-Host "`n[Método 1] Consultando schema do PostgreSQL...`n" -ForegroundColor Yellow

try {
    $sql = @"
SELECT 
    tablename as nome_tabela,
    schemaname as schema
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
"@

    $body = @{
        query = $sql
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop

    if ($response) {
        Write-Host "✅ Tabelas encontradas:`n" -ForegroundColor Green
        $response | ForEach-Object {
            Write-Host "  • $($_.nome_tabela)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "⚠️  RPC exec_sql não disponível" -ForegroundColor Yellow
}

# Método 2: Tentar tabelas comuns uma por uma
Write-Host "`n[Método 2] Testando tabelas comuns...`n" -ForegroundColor Yellow

$possibleTables = @(
    "documents",
    "embeddings", 
    "vectors",
    "knowledge_base",
    "rag_documents",
    "agent_documents",
    "rag",
    "knowledge",
    "document_embeddings",
    "vector_store",
    "ai_documents"
)

$foundTables = @()

foreach ($table in $possibleTables) {
    try {
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$table?select=*&limit=1" `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop
        
        Write-Host "  ✅ $table" -ForegroundColor Green
        $foundTables += $table
        
        # Mostrar estrutura da tabela
        if ($response -and $response.Count -gt 0) {
            $columns = $response[0].PSObject.Properties.Name
            Write-Host "     Colunas: $($columns -join ', ')" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ❌ $table" -ForegroundColor DarkGray
    }
}

# Método 3: Buscar em client_media (se houver referências)
Write-Host "`n[Método 3] Verificando storage client-media...`n" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/storage/v1/bucket/client-media" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    Write-Host "  ✅ Bucket client-media existe" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Bucket não encontrado ou sem permissão" -ForegroundColor Yellow
}

# Relatório Final
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "📊 RELATÓRIO" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray

if ($foundTables.Count -gt 0) {
    Write-Host "`n✅ Tabelas de RAG encontradas:" -ForegroundColor Green
    $foundTables | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor White
    }
    
    Write-Host "`n🎯 Use uma dessas tabelas no script de limpeza!" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Nenhuma tabela de RAG encontrada." -ForegroundColor Red
    Write-Host "`nPossíveis causas:" -ForegroundColor Yellow
    Write-Host "  1. O RAG está em outro banco de dados (Redis?)" -ForegroundColor White
    Write-Host "  2. A tabela tem um nome diferente" -ForegroundColor White
    Write-Host "  3. Não há permissão de acesso" -ForegroundColor White
    Write-Host "`n💡 Verifique no n8n qual database está configurado no node de RAG" -ForegroundColor Cyan
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray

# ============================================================================
# DESCOBRIR ESTRUTURA DO RAG NO SUPABASE
# ============================================================================

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

Write-Host "`n🔍 DESCOBRINDO ESTRUTURA DO RAG NO SUPABASE..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# PASSO 1: Procurar função search_rag_hybrid
Write-Host "`n[1/4] Verificando função search_rag_hybrid...`n" -ForegroundColor Yellow

$sql1 = @"
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%rag%'
ORDER BY routine_name;
"@

try {
    $body = @{ query = $sql1 } | ConvertTo-Json
    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop
    
    if ($response) {
        Write-Host "✅ Funções RAG encontradas:`n" -ForegroundColor Green
        $response | ForEach-Object {
            Write-Host "  • $($_.routine_name) ($($_.routine_type))" -ForegroundColor White
        }
    }
} catch {
    Write-Host "⚠️  Erro ao consultar funções: $($_.Exception.Message)" -ForegroundColor Yellow
}

# PASSO 2: Procurar tabelas relacionadas a RAG/documentos
Write-Host "`n[2/4] Procurando tabelas de documentos/embeddings...`n" -ForegroundColor Yellow

$sql2 = @"
SELECT 
    tablename,
    schemaname
FROM pg_tables
WHERE schemaname = 'public'
  AND (
    tablename LIKE '%rag%' OR
    tablename LIKE '%document%' OR
    tablename LIKE '%embedding%' OR
    tablename LIKE '%vector%' OR
    tablename LIKE '%chunk%' OR
    tablename LIKE '%knowledge%'
  )
ORDER BY tablename;
"@

try {
    $body = @{ query = $sql2 } | ConvertTo-Json
    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop
    
    if ($response) {
        Write-Host "✅ Tabelas encontradas:`n" -ForegroundColor Green
        $global:RAG_TABLES = @()
        $response | ForEach-Object {
            Write-Host "  • $($_.tablename)" -ForegroundColor White
            $global:RAG_TABLES += $_.tablename
        }
    } else {
        Write-Host "⚠️  Nenhuma tabela encontrada" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Erro ao consultar tabelas: $($_.Exception.Message)" -ForegroundColor Yellow
}

# PASSO 3: Descobrir estrutura da primeira tabela encontrada
if ($global:RAG_TABLES -and $global:RAG_TABLES.Count -gt 0) {
    $firstTable = $global:RAG_TABLES[0]
    Write-Host "`n[3/4] Estrutura da tabela '$firstTable'...`n" -ForegroundColor Yellow
    
    $sql3 = @"
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = '$firstTable'
ORDER BY ordinal_position;
"@
    
    try {
        $body = @{ query = $sql3 } | ConvertTo-Json
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
            -Method Post `
            -Headers $headers `
            -Body $body `
            -ErrorAction Stop
        
        if ($response) {
            Write-Host "✅ Colunas da tabela '$firstTable':`n" -ForegroundColor Green
            $response | ForEach-Object {
                $nullable = if ($_.is_nullable -eq "YES") { "NULL" } else { "NOT NULL" }
                Write-Host "  • $($_.column_name) - $($_.data_type) $nullable" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "⚠️  Erro ao consultar colunas: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # PASSO 4: Contar documentos por namespace
    Write-Host "`n[4/4] Contando documentos por namespace...`n" -ForegroundColor Yellow
    
    $sql4 = @"
SELECT 
    namespace,
    COUNT(*) as total_documentos
FROM $firstTable
GROUP BY namespace
ORDER BY namespace;
"@
    
    try {
        $body = @{ query = $sql4 } | ConvertTo-Json
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
            -Method Post `
            -Headers $headers `
            -Body $body `
            -ErrorAction Stop
        
        if ($response) {
            Write-Host "✅ Documentos por namespace:`n" -ForegroundColor Green
            $response | ForEach-Object {
                $color = if ($_.namespace -eq "estetica_bella_rede/default") { "Cyan" } 
                        elseif ($_.namespace -eq "clinica_sorriso_001/default") { "Yellow" }
                        else { "White" }
                Write-Host "  • $($_.namespace): $($_.total_documentos) docs" -ForegroundColor $color
            }
        }
    } catch {
        Write-Host "⚠️  Erro ao contar documentos: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Relatório Final
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "📊 PRÓXIMOS PASSOS" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray

if ($global:RAG_TABLES -and $global:RAG_TABLES.Count -gt 0) {
    Write-Host "`n✅ RAG identificado no Supabase (PostgreSQL + pgvector)" -ForegroundColor Green
    Write-Host "`n🎯 Agora posso criar script para:" -ForegroundColor Cyan
    Write-Host "  1. Buscar documentos contaminados" -ForegroundColor White
    Write-Host "  2. Listar documentos da Bella que mencionam Clínica Sorriso" -ForegroundColor White
    Write-Host "  3. Deletar apenas os contaminados" -ForegroundColor White
    Write-Host "`n💡 Use: .\limpar-rag-supabase-pgvector.ps1" -ForegroundColor Yellow
} else {
    Write-Host "`n⚠️  Não foi possível identificar estrutura do RAG" -ForegroundColor Yellow
    Write-Host "`n💡 Alternativas:" -ForegroundColor Cyan
    Write-Host "  1. Desabilitar RAG temporariamente no n8n" -ForegroundColor White
    Write-Host "  2. Verificar logs do n8n para ver queries executadas" -ForegroundColor White
    Write-Host "  3. Conectar diretamente no Supabase via psql" -ForegroundColor White
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray

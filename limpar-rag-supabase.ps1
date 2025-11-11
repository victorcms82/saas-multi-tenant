# ============================================================================
# LIMPAR RAG CONTAMINADO - Supabase pgvector
# ============================================================================

Write-Host "`n🔍 LIMPANDO VETORES CONTAMINADOS NO SUPABASE..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# Configuração
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
}

# ============================================================================
# PASSO 1: IDENTIFICAR TABELA DE VETORES
# ============================================================================

Write-Host "`n[1/5] Identificando tabela de vetores..." -ForegroundColor Yellow

# Possíveis nomes de tabela
$possibleTables = @(
    "documents",
    "embeddings", 
    "vectors",
    "knowledge_base",
    "rag_documents",
    "agent_documents"
)

Write-Host "`nProcurando tabelas no Supabase..." -ForegroundColor Gray

foreach ($table in $possibleTables) {
    try {
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$table?select=*&limit=1" `
            -Method Get `
            -Headers $headers `
            -ErrorAction SilentlyContinue
        
        Write-Host "✅ Encontrada: $table" -ForegroundColor Green
        $VECTOR_TABLE = $table
        break
    } catch {
        Write-Host "⚠️  Não encontrada: $table" -ForegroundColor DarkGray
    }
}

if (-not $VECTOR_TABLE) {
    Write-Host "`n❌ Tabela de vetores não encontrada!" -ForegroundColor Red
    Write-Host "Por favor, informe o nome da tabela manualmente:" -ForegroundColor Yellow
    $VECTOR_TABLE = Read-Host "Nome da tabela"
}

Write-Host "`n📊 Usando tabela: $VECTOR_TABLE" -ForegroundColor Cyan

# ============================================================================
# PASSO 2: BUSCAR DOCUMENTOS CONTAMINADOS
# ============================================================================

Write-Host "`n[2/5] Buscando documentos contaminados..." -ForegroundColor Yellow

# Buscar documentos da Bella Estética que mencionam Clínica Sorriso
$searchPatterns = @(
    "Clinica Sorriso",
    "Clínica Sorriso",
    "odontologia",
    "dentista",
    "Rua das Flores"
)

$contaminatedDocs = @()

foreach ($pattern in $searchPatterns) {
    Write-Host "  Buscando: '$pattern'..." -ForegroundColor Gray
    
    try {
        # URL encode do pattern
        $encodedPattern = [System.Web.HttpUtility]::UrlEncode($pattern)
        
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$VECTOR_TABLE?select=id,content,metadata,client_id&client_id=eq.estetica_bella_rede&content=ilike.*$encodedPattern*" `
            -Method Get `
            -Headers $headers
        
        if ($response -and $response.Count -gt 0) {
            Write-Host "    ❌ Encontrados: $($response.Count) documentos" -ForegroundColor Red
            $contaminatedDocs += $response
        } else {
            Write-Host "    ✅ Nenhum documento com '$pattern'" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ⚠️  Erro ao buscar: $_" -ForegroundColor Yellow
    }
}

# Remover duplicatas
$contaminatedDocs = $contaminatedDocs | Sort-Object -Property id -Unique

Write-Host "`n📊 TOTAL DE DOCUMENTOS CONTAMINADOS: $($contaminatedDocs.Count)" -ForegroundColor Cyan

# ============================================================================
# PASSO 3: EXIBIR PREVIEW DOS DOCUMENTOS
# ============================================================================

Write-Host "`n[3/5] Preview dos documentos a deletar..." -ForegroundColor Yellow

if ($contaminatedDocs.Count -eq 0) {
    Write-Host "`n✅ PARABÉNS! Nenhum documento contaminado encontrado!" -ForegroundColor Green
    Write-Host "O RAG já está limpo. 🎉" -ForegroundColor Cyan
    exit 0
}

foreach ($doc in $contaminatedDocs | Select-Object -First 5) {
    Write-Host "`n  ID: $($doc.id)" -ForegroundColor Yellow
    Write-Host "  Client: $($doc.client_id)" -ForegroundColor Gray
    
    $preview = $doc.content
    if ($preview.Length -gt 100) {
        $preview = $preview.Substring(0, 100) + "..."
    }
    Write-Host "  Texto: $preview" -ForegroundColor White
}

if ($contaminatedDocs.Count -gt 5) {
    Write-Host "`n  ... e mais $($contaminatedDocs.Count - 5) documentos" -ForegroundColor Gray
}

# ============================================================================
# PASSO 4: CONFIRMAR DELEÇÃO
# ============================================================================

Write-Host "`n[4/5] Confirmação de deleção..." -ForegroundColor Yellow
Write-Host "`n⚠️  ATENÇÃO: Esta operação é IRREVERSÍVEL!" -ForegroundColor Red
Write-Host "Serão deletados $($contaminatedDocs.Count) documentos da tabela '$VECTOR_TABLE'" -ForegroundColor Yellow

$confirmation = Read-Host "`nDigite 'SIM' para confirmar a deleção"

if ($confirmation -ne "SIM") {
    Write-Host "`n❌ Operação cancelada pelo usuário." -ForegroundColor Yellow
    exit 0
}

# ============================================================================
# PASSO 5: DELETAR DOCUMENTOS
# ============================================================================

Write-Host "`n[5/5] Deletando documentos contaminados..." -ForegroundColor Yellow

$deletedCount = 0
$errorCount = 0

foreach ($doc in $contaminatedDocs) {
    try {
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$VECTOR_TABLE?id=eq.$($doc.id)" `
            -Method Delete `
            -Headers $headers
        
        $deletedCount++
        Write-Host "  ✅ Deletado: $($doc.id)" -ForegroundColor Green
    } catch {
        $errorCount++
        Write-Host "  ❌ Erro ao deletar $($doc.id): $_" -ForegroundColor Red
    }
}

# ============================================================================
# RELATÓRIO FINAL
# ============================================================================

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "✅ LIMPEZA CONCLUÍDA!" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Gray

Write-Host "`n📊 ESTATÍSTICAS:" -ForegroundColor Cyan
Write-Host "  • Documentos encontrados: $($contaminatedDocs.Count)" -ForegroundColor White
Write-Host "  • Deletados com sucesso: $deletedCount" -ForegroundColor Green
Write-Host "  • Erros: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

Write-Host "`n🎯 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "  1. Testar no WhatsApp: 'Qual o endereço da clínica?'" -ForegroundColor White
Write-Host "  2. Verificar se responde apenas dados da Bella Estética" -ForegroundColor White
Write-Host "  3. Executar: .\validar-rag-limpo.ps1" -ForegroundColor Yellow

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray

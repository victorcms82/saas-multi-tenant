# ============================================================================
# TESTE RAG: Upload de Documento e Query
# ============================================================================

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY
$OPENAI_KEY = $env:OPENAI_API_KEY

if (-not $SUPABASE_KEY) {
    Write-Host "❌ ERRO: Variável SUPABASE_SERVICE_ROLE_KEY não definida" -ForegroundColor Red
    exit 1
}

if (-not $OPENAI_KEY) {
    Write-Host "❌ ERRO: Variável OPENAI_API_KEY não definida" -ForegroundColor Red
    exit 1
}

$headers = @{
    "apikey" = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Content-Type" = "application/json"
}

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "🧪 TESTE RAG END-TO-END" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PASSO 1: Criar documento de teste
# ============================================================================

$testContent = @"
Horário de Funcionamento da Clínica Sorriso:
- Segunda a Sexta: 8h às 18h
- Sábado: 8h às 12h
- Domingo: Fechado

Serviços Oferecidos:
- Limpeza dentária: R$ 150,00
- Clareamento dental: R$ 800,00
- Extração de dente: R$ 200,00
- Canal: R$ 1.200,00
- Implante dentário: R$ 3.500,00

Profissionais Disponíveis:
- Dra. Maria Silva - Dentista Clínico Geral (CRO 12345)
- Dr. João Santos - Ortodontista (CRO 67890)
- Dra. Ana Costa - Endodontista (CRO 11223)

Formas de Pagamento:
- Dinheiro, Cartão de Crédito/Débito
- Parcelamento em até 12x sem juros
- Aceitamos todos os planos odontológicos

Localização:
Rua das Flores, 123 - Centro
São Paulo - SP
Telefone: (11) 3333-4444
WhatsApp: (11) 99999-8888
"@

Write-Host "📄 Documento de teste criado ($(($testContent.Length)) caracteres)" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# PASSO 2: Gerar embedding do documento com OpenAI
# ============================================================================

Write-Host "🔄 Gerando embedding do documento..." -ForegroundColor Yellow

$embeddingPayload = @{
    model = "text-embedding-ada-002"
    input = $testContent
} | ConvertTo-Json

try {
    $embeddingResponse = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/embeddings" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $OPENAI_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $embeddingPayload

    $embedding = $embeddingResponse.data[0].embedding
    
    Write-Host "✅ Embedding gerado: $($embedding.Count) dimensões" -ForegroundColor Green
    Write-Host "💰 Custo: ~`$0.00001" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ ERRO ao gerar embedding: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# PASSO 3: Salvar documento no Supabase via RPC
# ============================================================================

Write-Host "💾 Salvando documento no Supabase..." -ForegroundColor Yellow

$savePayload = @{
    p_client_id = "clinica_sorriso_001"
    p_agent_id = "default"
    p_content = $testContent
    p_embedding = $embedding
    p_metadata = @{
        tags = @("horarios", "precos", "servicos", "profissionais")
        author = "sistema"
        version = "1.0"
    }
    p_source_type = "manual"
    p_file_name = "teste-rag-clinica-sorriso.txt"
} | ConvertTo-Json -Depth 10

try {
    $saveResponse = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/save_rag_document" `
        -Method POST `
        -Headers $headers `
        -Body $savePayload

    Write-Host "✅ Documento salvo! ID: $saveResponse" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ ERRO ao salvar documento: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Detalhes: $($_.ErrorDetails.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# PASSO 4: Aguardar 2 segundos (garantir indexação)
# ============================================================================

Write-Host "⏳ Aguardando 2s para indexação..." -ForegroundColor Gray
Start-Sleep -Seconds 2
Write-Host ""

# ============================================================================
# PASSO 5: Testar query RAG
# ============================================================================

$queries = @(
    "Qual o horário de funcionamento?",
    "Quanto custa um clareamento dental?",
    "Quais profissionais atendem na clínica?",
    "Aceita cartão de crédito?",
    "Quanto custa uma consulta de emergência?" # Não está no documento
)

foreach ($query in $queries) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔍 QUERY: $query" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    # Gerar embedding da query
    $queryEmbeddingPayload = @{
        model = "text-embedding-ada-002"
        input = $query
    } | ConvertTo-Json
    
    try {
        $queryEmbeddingResponse = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/embeddings" `
            -Method POST `
            -Headers @{
                "Authorization" = "Bearer $OPENAI_KEY"
                "Content-Type" = "application/json"
            } `
            -Body $queryEmbeddingPayload
        
        $queryEmbedding = $queryEmbeddingResponse.data[0].embedding
        
        # Buscar no RAG
        $ragQueryPayload = @{
            p_client_id = "clinica_sorriso_001"
            p_agent_id = "default"
            p_query_embedding = $queryEmbedding
            p_limit = 3
            p_threshold = 0.7
        } | ConvertTo-Json -Depth 10
        
        $ragResults = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/rpc/query_rag_documents" `
            -Method POST `
            -Headers $headers `
            -Body $ragQueryPayload
        
        if ($ragResults.Count -gt 0) {
            Write-Host "✅ Documentos encontrados: $($ragResults.Count)" -ForegroundColor Green
            Write-Host ""
            
            foreach ($doc in $ragResults) {
                $similarity = [math]::Round($doc.similarity * 100, 0)
                Write-Host "📄 [$($doc.file_name)] - Similaridade: $similarity%" -ForegroundColor White
                Write-Host "   Preview: $($doc.content.Substring(0, [Math]::Min(150, $doc.content.Length)))..." -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "⚠️ Nenhum documento encontrado (similaridade < 70%)" -ForegroundColor Yellow
            Write-Host ""
        }
        
    } catch {
        Write-Host "❌ ERRO na query: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
    }
}

# ============================================================================
# PASSO 6: Verificar estatísticas
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 ESTATÍSTICAS RAG" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

try {
    $stats = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rag_statistics?client_id=eq.clinica_sorriso_001" `
        -Method GET `
        -Headers $headers
    
    if ($stats.Count -gt 0) {
        $stat = $stats[0]
        Write-Host "Cliente: $($stat.client_id)" -ForegroundColor White
        Write-Host "Agente: $($stat.agent_id)" -ForegroundColor White
        Write-Host "Total de documentos: $($stat.total_documents)" -ForegroundColor White
        Write-Host "Fontes únicas: $($stat.unique_sources)" -ForegroundColor White
        Write-Host "Tamanho médio do chunk: $([math]::Round($stat.avg_chunk_size, 0)) chars" -ForegroundColor White
        Write-Host "Primeiro upload: $($stat.first_upload)" -ForegroundColor White
        Write-Host "Último upload: $($stat.last_upload)" -ForegroundColor White
    } else {
        Write-Host "Nenhuma estatística encontrada" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao buscar estatísticas: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "✅ TESTE CONCLUÍDO!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan

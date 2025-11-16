# ============================================================================
# SCRIPT: Upload de Documento para RAG
# ============================================================================
# Uso: .\upload-documento-rag.ps1
# Descrição: Faz upload de documentos para o sistema RAG via RPC direto
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId = "clinica_sorriso_001",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentId = "default"
)

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY
$OPENAI_KEY = $env:OPENAI_API_KEY

if (-not $SUPABASE_KEY) {
    Write-Host "❌ ERRO: Variável SUPABASE_SERVICE_ROLE_KEY não definida" -ForegroundColor Red
    Write-Host "Execute: `$env:SUPABASE_SERVICE_ROLE_KEY = 'sua-key'" -ForegroundColor Yellow
    exit 1
}

if (-not $OPENAI_KEY) {
    Write-Host "❌ ERRO: Variável OPENAI_API_KEY não definida" -ForegroundColor Red
    Write-Host "Execute: `$env:OPENAI_API_KEY = 'sua-key'" -ForegroundColor Yellow
    exit 1
}

# ============================================================================
# MENU DE OPÇÕES
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "📚 UPLOAD DE DOCUMENTO PARA RAG" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $FilePath) {
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Fazer upload de arquivo TXT/MD" -ForegroundColor White
    Write-Host "2. Digitar conteúdo manualmente" -ForegroundColor White
    Write-Host "3. Fazer upload de múltiplos arquivos de uma pasta" -ForegroundColor White
    Write-Host ""
    
    $opcao = Read-Host "Digite o número da opção"
    
    switch ($opcao) {
        "1" {
            $FilePath = Read-Host "Digite o caminho completo do arquivo"
            if (-not (Test-Path $FilePath)) {
                Write-Host "❌ Arquivo não encontrado: $FilePath" -ForegroundColor Red
                exit 1
            }
        }
        "2" {
            Write-Host ""
            Write-Host "Digite o conteúdo (pressione Ctrl+Z e Enter para finalizar):" -ForegroundColor Yellow
            $content = @()
            while ($true) {
                $line = Read-Host
                if ($line -eq $null) { break }
                $content += $line
            }
            $documentContent = $content -join "`n"
            
            $fileName = Read-Host "Digite um nome para o documento (ex: manual.txt)"
        }
        "3" {
            $folderPath = Read-Host "Digite o caminho da pasta"
            if (-not (Test-Path $folderPath)) {
                Write-Host "❌ Pasta não encontrada: $folderPath" -ForegroundColor Red
                exit 1
            }
            
            $files = Get-ChildItem -Path $folderPath -Include *.txt,*.md -Recurse
            
            if ($files.Count -eq 0) {
                Write-Host "❌ Nenhum arquivo TXT/MD encontrado na pasta" -ForegroundColor Red
                exit 1
            }
            
            Write-Host ""
            Write-Host "📁 Encontrados $($files.Count) arquivos:" -ForegroundColor Green
            $files | ForEach-Object { Write-Host "   • $($_.Name)" -ForegroundColor Gray }
            Write-Host ""
            
            $confirm = Read-Host "Fazer upload de todos? (S/N)"
            if ($confirm -ne "S" -and $confirm -ne "s") {
                Write-Host "❌ Cancelado pelo usuário" -ForegroundColor Yellow
                exit 0
            }
            
            # Processar cada arquivo
            foreach ($file in $files) {
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "📄 Processando: $($file.Name)" -ForegroundColor Cyan
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                
                & $PSCommandPath -FilePath $file.FullName -ClientId $ClientId -AgentId $AgentId
            }
            
            Write-Host ""
            Write-Host "✅ UPLOAD EM LOTE CONCLUÍDO!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "❌ Opção inválida" -ForegroundColor Red
            exit 1
        }
    }
}

# ============================================================================
# PROCESSAR ARQUIVO
# ============================================================================

if ($FilePath -and (Test-Path $FilePath)) {
    $documentContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $fileName = Split-Path $FilePath -Leaf
}

if (-not $documentContent -or $documentContent.Trim() -eq "") {
    Write-Host "❌ Conteúdo vazio" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📄 Documento: $fileName" -ForegroundColor White
Write-Host "📏 Tamanho: $($documentContent.Length) caracteres" -ForegroundColor Gray
Write-Host "🏢 Cliente: $ClientId" -ForegroundColor Gray
Write-Host "🤖 Agente: $AgentId" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# FUNÇÃO: Dividir em Chunks
# ============================================================================

function Split-IntoChunks {
    param(
        [string]$text,
        [int]$chunkSize = 2000,
        [int]$overlap = 200
    )
    
    $chunks = @()
    $start = 0
    
    while ($start -lt $text.Length) {
        $end = [Math]::Min($start + $chunkSize, $text.Length)
        $chunk = $text.Substring($start, $end - $start)
        $chunks += $chunk
        $start += ($chunkSize - $overlap)
    }
    
    return $chunks
}

# ============================================================================
# DIVIDIR EM CHUNKS
# ============================================================================

$chunks = Split-IntoChunks -text $documentContent -chunkSize 2000 -overlap 200

Write-Host "✂️ Dividido em $($chunks.Count) chunk(s)" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PROCESSAR CADA CHUNK
# ============================================================================

$successCount = 0
$failCount = 0

for ($i = 0; $i -lt $chunks.Count; $i++) {
    $chunk = $chunks[$i]
    $chunkIndex = $i
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📦 Chunk $($chunkIndex + 1)/$($chunks.Count)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    # Gerar embedding
    Write-Host "🔄 Gerando embedding..." -ForegroundColor Yellow
    
    $embeddingBody = @{
        model = "text-embedding-ada-002"
        input = $chunk
    } | ConvertTo-Json -Depth 10
    
    try {
        $embeddingResponse = Invoke-RestMethod -Uri "https://api.openai.com/v1/embeddings" `
            -Method POST `
            -Headers @{
                "Authorization" = "Bearer $OPENAI_KEY"
                "Content-Type" = "application/json"
            } `
            -Body $embeddingBody
        
        $embedding = $embeddingResponse.data[0].embedding
        
        Write-Host "✅ Embedding gerado: $($embedding.Count) dimensões" -ForegroundColor Green
        Write-Host "💰 Custo: ~`$0.00001" -ForegroundColor Gray
        
        # Salvar no Supabase
        Write-Host "💾 Salvando no Supabase..." -ForegroundColor Yellow
        
        $contentHash = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($chunk))
        $contentHashString = [System.BitConverter]::ToString($contentHash).Replace("-", "").ToLower()
        
        $rpcBody = @{
            p_client_id = $ClientId
            p_agent_id = $AgentId
            p_content = $chunk
            p_content_hash = $contentHashString
            p_embedding = $embedding
            p_metadata = @{
                tags = @("uploaded_via_script")
                upload_date = (Get-Date -Format "yyyy-MM-dd")
            }
            p_source_type = "manual"
            p_source_id = $fileName
            p_source_url = $null
            p_file_name = $fileName
            p_chunk_index = $chunkIndex
            p_total_chunks = $chunks.Count
        } | ConvertTo-Json -Depth 10
        
        $saveResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/save_rag_document" `
            -Method POST `
            -Headers @{
                "apikey" = $SUPABASE_KEY
                "Authorization" = "Bearer $SUPABASE_KEY"
                "Content-Type" = "application/json"
                "Prefer" = "return=representation"
            } `
            -Body $rpcBody
        
        Write-Host "✅ Chunk salvo! ID: $saveResponse" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host "❌ Erro ao processar chunk: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
    Start-Sleep -Milliseconds 500
}

# ============================================================================
# RESUMO FINAL
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "📊 RESUMO DO UPLOAD" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📄 Arquivo: $fileName" -ForegroundColor White
Write-Host "🏢 Cliente: $ClientId" -ForegroundColor White
Write-Host "🤖 Agente: $AgentId" -ForegroundColor White
Write-Host ""
Write-Host "✅ Chunks enviados com sucesso: $successCount" -ForegroundColor Green
Write-Host "❌ Chunks com erro: $failCount" -ForegroundColor Red
Write-Host "📦 Total de chunks: $($chunks.Count)" -ForegroundColor White
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "🎉 UPLOAD CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Upload concluído com alguns erros" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 Teste o RAG enviando uma mensagem no Chatwoot!" -ForegroundColor Cyan
Write-Host ""

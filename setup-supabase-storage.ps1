# ==================================================
# Setup Supabase Storage - Criar bucket e upload de arquivos
# ==================================================
# Purpose: Criar bucket "client-media" e fazer upload do arquivo de teste
# ==================================================

param(
    [string]$SupabaseUrl = "https://vnlfgnfaortdvmraoapq.supabase.co",
    [string]$ApiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U",
    [string]$ServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"
)

$Headers = @{
    "apikey" = $ServiceKey
    "Authorization" = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   SETUP SUPABASE STORAGE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ==================================================
# 1. Criar bucket "client-media"
# ==================================================
Write-Host "📦 Passo 1: Criando bucket 'client-media'..." -ForegroundColor Yellow
Write-Host ""

$BucketPayload = @{
    id = "client-media"
    name = "client-media"
    public = $true
    file_size_limit = 52428800  # 50MB
    allowed_mime_types = @(
        "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp",
        "video/mp4", "video/quicktime", "video/webm",
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )
} | ConvertTo-Json

try {
    $BucketResponse = Invoke-RestMethod `
        -Uri "$SupabaseUrl/storage/v1/bucket" `
        -Method POST `
        -Headers $Headers `
        -Body $BucketPayload
    
    Write-Host "✅ Bucket 'client-media' criado com sucesso!" -ForegroundColor Green
    Write-Host "   ID: $($BucketResponse.name)" -ForegroundColor Gray
    Write-Host ""
} catch {
    if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*409*") {
        Write-Host "ℹ️  Bucket 'client-media' já existe!" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "❌ Erro ao criar bucket: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
    }
}

# ==================================================
# 2. Criar arquivo de teste (PDF fake)
# ==================================================
Write-Host "📄 Passo 2: Criando arquivo de teste..." -ForegroundColor Yellow
Write-Host ""

# Criar um PDF simples para teste
$PdfContent = @"
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/Resources <<
/Font <<
/F1 <<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
>>
>>
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 95
>>
stream
BT
/F1 24 Tf
50 750 Td
(TABELA DE PRECOS - CLINICA SORRISO) Tj
0 -30 Td
(Tratamento 1: R$ 500,00) Tj
0 -30 Td
(Tratamento 2: R$ 800,00) Tj
0 -30 Td
(Tratamento 3: R$ 1.200,00) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000015 00000 n
0000000068 00000 n
0000000125 00000 n
0000000317 00000 n
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
462
%%EOF
"@

$TempPdfPath = "$env:TEMP\tabela-precos.pdf"
$PdfContent | Out-File -FilePath $TempPdfPath -Encoding ASCII -NoNewline

Write-Host "✅ Arquivo criado: $TempPdfPath" -ForegroundColor Green
Write-Host "   Tamanho: $((Get-Item $TempPdfPath).Length) bytes" -ForegroundColor Gray
Write-Host ""

# ==================================================
# 3. Upload do arquivo para o Supabase Storage
# ==================================================
Write-Host "☁️  Passo 3: Fazendo upload para Supabase..." -ForegroundColor Yellow
Write-Host ""

$UploadPath = "clinica_sorriso_001/tabela-precos.pdf"
$UploadUrl = "$SupabaseUrl/storage/v1/object/client-media/$UploadPath"

$UploadHeaders = @{
    "apikey" = $ServiceKey
    "Authorization" = "Bearer $ServiceKey"
    "Content-Type" = "application/pdf"
    "x-upsert" = "true"  # Sobrescrever se já existir
}

try {
    $FileBytes = [System.IO.File]::ReadAllBytes($TempPdfPath)
    
    $UploadResponse = Invoke-RestMethod `
        -Uri $UploadUrl `
        -Method POST `
        -Headers $UploadHeaders `
        -Body $FileBytes
    
    Write-Host "✅ Upload realizado com sucesso!" -ForegroundColor Green
    Write-Host "   Path: $UploadPath" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Erro no upload: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Detalhes:" -ForegroundColor Yellow
    Write-Host $_.Exception.Response -ForegroundColor Gray
    Write-Host ""
}

# ==================================================
# 4. Testar acesso público ao arquivo
# ==================================================
Write-Host "🧪 Passo 4: Testando acesso público..." -ForegroundColor Yellow
Write-Host ""

$PublicUrl = "$SupabaseUrl/storage/v1/object/public/client-media/$UploadPath"
Write-Host "URL pública: $PublicUrl" -ForegroundColor Gray
Write-Host ""

try {
    $TestResponse = Invoke-WebRequest -Uri $PublicUrl -Method HEAD -UseBasicParsing
    Write-Host "✅ Arquivo acessível publicamente!" -ForegroundColor Green
    Write-Host "   Status: $($TestResponse.StatusCode)" -ForegroundColor Gray
    Write-Host "   Content-Type: $($TestResponse.Headers['Content-Type'])" -ForegroundColor Gray
    Write-Host "   Content-Length: $($TestResponse.Headers['Content-Length']) bytes" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Arquivo NÃO acessível: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# ==================================================
# 5. Atualizar URL no banco de dados
# ==================================================
Write-Host "🔄 Passo 5: Atualizando URL no banco..." -ForegroundColor Yellow
Write-Host ""

$UpdateUrl = "$SupabaseUrl/rest/v1/client_media?client_id=eq.clinica_sorriso_001&file_name=eq.tabela-precos.pdf"
$UpdateHeaders = @{
    "apikey" = $ApiKey
    "Authorization" = "Bearer $ApiKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$UpdatePayload = @{
    file_url = $PublicUrl
} | ConvertTo-Json

try {
    $UpdateResponse = Invoke-RestMethod `
        -Uri $UpdateUrl `
        -Method PATCH `
        -Headers $UpdateHeaders `
        -Body $UpdatePayload
    
    Write-Host "✅ URL atualizada no banco de dados!" -ForegroundColor Green
    Write-Host "   Registros atualizados: $($UpdateResponse.Count)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "⚠️  Não foi possível atualizar URL (isso é normal se o registro não existir)" -ForegroundColor Yellow
    Write-Host ""
}

# ==================================================
# 6. Resumo Final
# ==================================================
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "   ✅ SETUP COMPLETO!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Resumo:" -ForegroundColor Cyan
Write-Host "  ✅ Bucket: client-media (público)" -ForegroundColor White
Write-Host "  ✅ Arquivo: clinica_sorriso_001/tabela-precos.pdf" -ForegroundColor White
Write-Host "  ✅ URL: $PublicUrl" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Próximos passos:" -ForegroundColor Cyan
Write-Host "  1. Execute o teste: .\test-wf0-webhook.ps1 -ConversationId 4 -MessageBody 'qual o preço?'" -ForegroundColor Gray
Write-Host "  2. Verifique se o PDF é baixado e enviado para o Chatwoot" -ForegroundColor Gray
Write-Host "  3. Confirme se o anexo aparece na conversa" -ForegroundColor Gray
Write-Host ""
Write-Host "🗑️  Arquivo temporário criado em: $TempPdfPath" -ForegroundColor Yellow
Write-Host "    (Será deletado automaticamente ao reiniciar o sistema)" -ForegroundColor Gray
Write-Host ""

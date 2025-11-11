# TESTE: Enviar attachment via URL no Chatwoot API
# Valida se Chatwoot aceita URLs públicas em attachments[]

$conversationId = 6  # Conversa aberta atual
$apiToken = "zL8FNtrajZjGv4LP9BrZiCif"
$baseUrl = "https://chatwoot.evolutedigital.com.br/api/v1/accounts/1"

# URL pública do arquivo no Supabase Storage
$fileUrl = "https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/consultorio-recepcao.jpg"

Write-Host "`n🧪 TESTE: Enviar Attachment via URL" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host "Conversation ID: $conversationId"
Write-Host "File URL: $fileUrl"
Write-Host ""

# MÉTODO 1: Tentar com multipart/form-data
Write-Host "📤 Método 1: Multipart Form-Data com URL..." -ForegroundColor Yellow

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"message_type`"$LF",
    "outgoing",
    "--$boundary",
    "Content-Disposition: form-data; name=`"private`"$LF",
    "false",
    "--$boundary",
    "Content-Disposition: form-data; name=`"attachments[]`"$LF",
    $fileUrl,
    "--$boundary--$LF"
) -join $LF

try {
    $response1 = Invoke-RestMethod `
        -Uri "$baseUrl/conversations/$conversationId/messages" `
        -Method POST `
        -Headers @{
            "api_access_token" = $apiToken
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        } `
        -Body $bodyLines
    
    Write-Host "✅ SUCESSO Método 1!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    $response1 | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ FALHOU Método 1" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Start-Sleep -Seconds 2

# MÉTODO 2: Tentar com JSON + attachments array
Write-Host "`n📤 Método 2: JSON Body com attachments..." -ForegroundColor Yellow

$body2 = @{
    message_type = "outgoing"
    private = $false
    content = "Teste de envio de arquivo"
    attachments = @($fileUrl)
} | ConvertTo-Json

try {
    $response2 = Invoke-RestMethod `
        -Uri "$baseUrl/conversations/$conversationId/messages" `
        -Method POST `
        -Headers @{
            "api_access_token" = $apiToken
            "Content-Type" = "application/json"
        } `
        -Body $body2
    
    Write-Host "✅ SUCESSO Método 2!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    $response2 | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ FALHOU Método 2" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Start-Sleep -Seconds 2

# MÉTODO 3: Baixar arquivo e enviar como file binary
Write-Host "`n📤 Método 3: Download + Upload Binary..." -ForegroundColor Yellow

try {
    # Download do arquivo
    $tempFile = Join-Path $env:TEMP "test-attachment.jpg"
    Invoke-WebRequest -Uri $fileUrl -OutFile $tempFile
    
    Write-Host "Arquivo baixado: $tempFile ($(Get-Item $tempFile).Length bytes)"
    
    # Criar multipart com arquivo real
    $boundary3 = [System.Guid]::NewGuid().ToString()
    $fileContent = [System.IO.File]::ReadAllBytes($tempFile)
    $fileContentBase64 = [Convert]::ToBase64String($fileContent)
    
    $bodyLines3 = (
        "--$boundary3",
        "Content-Disposition: form-data; name=`"message_type`"$LF",
        "outgoing",
        "--$boundary3",
        "Content-Disposition: form-data; name=`"private`"$LF",
        "false",
        "--$boundary3",
        "Content-Disposition: form-data; name=`"attachments[]`"; filename=`"consultorio.jpg`"",
        "Content-Type: image/jpeg$LF",
        $fileContentBase64,
        "--$boundary3--$LF"
    ) -join $LF
    
    $response3 = Invoke-RestMethod `
        -Uri "$baseUrl/conversations/$conversationId/messages" `
        -Method POST `
        -Headers @{
            "api_access_token" = $apiToken
            "Content-Type" = "multipart/form-data; boundary=$boundary3"
        } `
        -Body $bodyLines3
    
    Write-Host "✅ SUCESSO Método 3!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    $response3 | ConvertTo-Json -Depth 3
    
    # Limpar
    Remove-Item $tempFile -Force
    
} catch {
    Write-Host "❌ FALHOU Método 3" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Write-Host "`n" + ("=" * 60)
Write-Host "🏁 TESTE CONCLUÍDO" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 RESULTADO:"
Write-Host "  - Verifique no WhatsApp se algum arquivo chegou"
Write-Host "  - Conversation ID: $conversationId"
Write-Host "  - Inbox: WhatsApp (55 21 99950 1444)"
Write-Host ""

# ==================================================
# Test Chatwoot Attachment Upload
# ==================================================
# Purpose: Testar upload direto de arquivo para Chatwoot API
# ==================================================

param(
    [int]$ConversationId = 4,
    [string]$FilePath = "$env:TEMP\tabela-precos.pdf"
)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   TEST CHATWOOT ATTACHMENT UPLOAD" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Configurações
$ChatwootUrl = "https://chatwoot.evolutedigital.com.br"
$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif"
$AccountId = 1

Write-Host "📁 Arquivo: $FilePath" -ForegroundColor White
Write-Host "💬 Conversation ID: $ConversationId" -ForegroundColor White
Write-Host ""

# Verificar se arquivo existe
if (-not (Test-Path $FilePath)) {
    Write-Host "❌ Arquivo não encontrado: $FilePath" -ForegroundColor Red
    exit 1
}

$FileInfo = Get-Item $FilePath
Write-Host "✅ Arquivo encontrado:" -ForegroundColor Green
Write-Host "   Nome: $($FileInfo.Name)" -ForegroundColor Gray
Write-Host "   Tamanho: $($FileInfo.Length) bytes" -ForegroundColor Gray
Write-Host ""

# Preparar multipart/form-data
$Boundary = [System.Guid]::NewGuid().ToString()
$FileBytes = [System.IO.File]::ReadAllBytes($FilePath)
$FileName = $FileInfo.Name

# Construir body manualmente
$BodyLines = @()
$BodyLines += "--$Boundary"
$BodyLines += 'Content-Disposition: form-data; name="content"'
$BodyLines += ''
$BodyLines += 'Segue a tabela de preços solicitada'
$BodyLines += "--$Boundary"
$BodyLines += 'Content-Disposition: form-data; name="message_type"'
$BodyLines += ''
$BodyLines += 'outgoing'
$BodyLines += "--$Boundary"
$BodyLines += 'Content-Disposition: form-data; name="private"'
$BodyLines += ''
$BodyLines += 'false'
$BodyLines += "--$Boundary"
$BodyLines += "Content-Disposition: form-data; name=`"attachments[]`"; filename=`"$FileName`""
$BodyLines += 'Content-Type: application/pdf'
$BodyLines += ''

# Converter para bytes
$Encoding = [System.Text.Encoding]::UTF8
$BodyStart = $Encoding.GetBytes(($BodyLines -join "`r`n") + "`r`n")
$BodyEnd = $Encoding.GetBytes("`r`n--$Boundary--`r`n")

# Combinar tudo
$Body = $BodyStart + $FileBytes + $BodyEnd

Write-Host "📦 Payload preparado:" -ForegroundColor White
Write-Host "   Content-Type: multipart/form-data; boundary=$Boundary" -ForegroundColor Gray
Write-Host "   Body size: $($Body.Length) bytes" -ForegroundColor Gray
Write-Host ""

# Fazer requisição
$Url = "$ChatwootUrl/api/v1/accounts/$AccountId/conversations/$ConversationId/messages"

Write-Host "🚀 Enviando para: $Url" -ForegroundColor White
Write-Host ""

try {
    $Response = Invoke-RestMethod -Uri $Url `
        -Method POST `
        -Headers @{
            "api_access_token" = $ApiToken
            "Content-Type" = "multipart/form-data; boundary=$Boundary"
        } `
        -Body $Body

    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   ✅ SUCESSO!" -ForegroundColor Green
    Write-Host "============================================`n" -ForegroundColor Green

    Write-Host "📊 Response:" -ForegroundColor White
    Write-Host ($Response | ConvertTo-Json -Depth 10) -ForegroundColor Gray
    Write-Host ""

    if ($Response.attachments) {
        Write-Host "✅ Attachment presente na resposta!" -ForegroundColor Green
        Write-Host "   Attachments: $($Response.attachments.Count)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Attachment NÃO presente na resposta" -ForegroundColor Yellow
    }

} catch {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   ❌ ERRO!" -ForegroundColor Red
    Write-Host "============================================`n" -ForegroundColor Red

    Write-Host "❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $ResponseBody = $Reader.ReadToEnd()
        Write-Host "`n📄 Response Body:" -ForegroundColor Yellow
        Write-Host $ResponseBody -ForegroundColor Gray
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   📋 TESTE COMPLETO" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

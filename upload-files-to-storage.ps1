# UPLOAD DE ARQUIVOS PARA SUPABASE STORAGE
# Os arquivos estão registrados na tabela mas não estão no bucket!

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

Write-Host "`n📤 UPLOAD DE ARQUIVOS PARA SUPABASE STORAGE" -ForegroundColor Cyan
Write-Host "=" * 70

# Arquivo 1: Recepção do Consultório (JPG)
Write-Host "`n1️⃣ Recepção do Consultório..." -ForegroundColor Yellow
$recepcaoPath = "clinica_sorriso_001/consultorio-recepcao.jpg"

# Criar imagem de exemplo (placeholder)
Add-Type -AssemblyName System.Drawing
$bmp1 = New-Object System.Drawing.Bitmap 800, 600
$graphics1 = [System.Drawing.Graphics]::FromImage($bmp1)
$graphics1.Clear([System.Drawing.Color]::LightBlue)
$font = New-Object System.Drawing.Font("Arial", 40, [System.Drawing.FontStyle]::Bold)
$brush = [System.Drawing.Brushes]::White
$graphics1.DrawString("Recepção", $font, $brush, 200, 250)
$graphics1.DrawString("Clínica Sorriso", $font, $brush, 100, 300)
$tempFile1 = Join-Path $env:TEMP "consultorio-recepcao.jpg"
$bmp1.Save($tempFile1, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics1.Dispose()
$bmp1.Dispose()

Write-Host "Arquivo criado: $tempFile1"

try {
    $fileBytes1 = [System.IO.File]::ReadAllBytes($tempFile1)
    $response1 = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/storage/v1/object/client-media/$recepcaoPath" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = $SERVICE_KEY
            "Content-Type" = "image/jpeg"
            "x-upsert" = "true"
        } `
        -Body $fileBytes1
    
    Write-Host "✅ Upload realizado com sucesso!" -ForegroundColor Green
    Write-Host "URL: $SUPABASE_URL/storage/v1/object/public/client-media/$recepcaoPath"
} catch {
    Write-Host "❌ Erro no upload: $($_.Exception.Message)" -ForegroundColor Red
}

Remove-Item $tempFile1 -Force

# Arquivo 2: Equipe Clínica (JPG)
Write-Host "`n2️⃣ Equipe Clínica Sorriso..." -ForegroundColor Yellow
$equipePath = "clinica_sorriso_001/equipe-completa.jpg"

$bmp2 = New-Object System.Drawing.Bitmap 800, 600
$graphics2 = [System.Drawing.Graphics]::FromImage($bmp2)
$graphics2.Clear([System.Drawing.Color]::LightGreen)
$graphics2.DrawString("Equipe", $font, $brush, 280, 250)
$graphics2.DrawString("Clínica Sorriso", $font, $brush, 100, 300)
$tempFile2 = Join-Path $env:TEMP "equipe-completa.jpg"
$bmp2.Save($tempFile2, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics2.Dispose()
$bmp2.Dispose()

Write-Host "Arquivo criado: $tempFile2"

try {
    $fileBytes2 = [System.IO.File]::ReadAllBytes($tempFile2)
    $response2 = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/storage/v1/object/client-media/$equipePath" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = $SERVICE_KEY
            "Content-Type" = "image/jpeg"
            "x-upsert" = "true"
        } `
        -Body $fileBytes2
    
    Write-Host "✅ Upload realizado com sucesso!" -ForegroundColor Green
    Write-Host "URL: $SUPABASE_URL/storage/v1/object/public/client-media/$equipePath"
} catch {
    Write-Host "❌ Erro no upload: $($_.Exception.Message)" -ForegroundColor Red
}

Remove-Item $tempFile2 -Force

# Arquivo 3: Tabela de Preços (PDF simples via texto)
Write-Host "`n3️⃣ Tabela de Preços (PDF)..." -ForegroundColor Yellow
$tabelaPath = "clinica_sorriso_001/tabela-precos.pdf"

# PDF mínimo válido (simplificado)
$pdfContent = @"
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /Resources 4 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>
endobj
4 0 obj
<< /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >>
endobj
5 0 obj
<< /Length 120 >>
stream
BT
/F1 24 Tf
100 700 Td
(TABELA DE PRECOS) Tj
0 -50 Td
(Limpeza: R$ 150) Tj
0 -30 Td
(Clareamento: R$ 800) Tj
ET
endstream
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000227 00000 n 
0000000319 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
492
%%EOF
"@

$tempFile3 = Join-Path $env:TEMP "tabela-precos.pdf"
[System.IO.File]::WriteAllText($tempFile3, $pdfContent)

Write-Host "Arquivo criado: $tempFile3"

try {
    $fileBytes3 = [System.IO.File]::ReadAllBytes($tempFile3)
    $response3 = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/storage/v1/object/client-media/$tabelaPath" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = $SERVICE_KEY
            "Content-Type" = "application/pdf"
            "x-upsert" = "true"
        } `
        -Body $fileBytes3
    
    Write-Host "✅ Upload realizado com sucesso!" -ForegroundColor Green
    Write-Host "URL: $SUPABASE_URL/storage/v1/object/public/client-media/$tabelaPath"
} catch {
    Write-Host "❌ Erro no upload: $($_.Exception.Message)" -ForegroundColor Red
}

Remove-Item $tempFile3 -Force

Write-Host "`n" + ("=" * 70)
Write-Host "🎉 UPLOAD CONCLUÍDO!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:"
Write-Host "  1. Testar URLs no navegador"
Write-Host "  2. Executar test-chatwoot-send-attachment.ps1 novamente"
Write-Host "  3. Verificar se arquivos aparecem no WhatsApp"
Write-Host ""

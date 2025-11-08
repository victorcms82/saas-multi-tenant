# ============================================================================
# TEST: Chamada direta ao RPC via HTTP (igual ao n8n)
# ============================================================================

$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

$body = @{
    p_client_id = "clinica_sorriso_001"
    p_agent_id = "default"
    p_message_body = "qual o preço?"
    p_conversation_id = "99999"
} | ConvertTo-Json

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TEST RPC: search_client_media_rules" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL:" -ForegroundColor Yellow
Write-Host "  https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/search_client_media_rules"
Write-Host ""
Write-Host "Body:" -ForegroundColor Yellow
Write-Host $body
Write-Host ""
Write-Host "Enviando requisição..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-RestMethod `
        -Uri "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/search_client_media_rules" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -ContentType "application/json"
    
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   ✅ SUCESSO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
    Write-Host ""
    
    if ($response.Count -eq 0) {
        Write-Host "⚠️ ATENÇÃO: RPC retornou array vazio!" -ForegroundColor Yellow
        Write-Host "   Isso significa que nenhuma regra foi encontrada." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Encontrou $($response.Count) mídia(s)!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Arquivo: $($response[0].file_name)" -ForegroundColor Cyan
        Write-Host "URL: $($response[0].file_url)" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   ❌ ERRO!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Response Body:" -ForegroundColor Red
    $_.ErrorDetails.Message
}

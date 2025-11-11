# ============================================
# Teste de mensagem WhatsApp via Meta Cloud API
# ============================================
# Envia uma mensagem de teste para verificar o fluxo completo:
# Meta WhatsApp → Chatwoot → n8n → LLM → Chatwoot
# ============================================

param(
    [string]$PhoneNumberId = "851688391353928",
    [string]$AccessToken = "EAAV64FVdoGMBPwM5oE51iads4AbuNaZCzHgCvYjvwM1kj1f0csJ6cM0cJY7uXvpQLFy2OMpchSesLM95m8ziRsaBCWQe045k7hr2YkKZCOufZB1zZAxxZAZA6fUfrrfOdiWLWrMHzmbAAkLLZBoh0Uc9jfdL5YqKNyvqyQvv1rE9OQcJ1Hjlr40TrsSzkcwkwooowZDZD",
    [string]$ToPhoneNumber = "5511999999999", # Seu número de WhatsApp para receber a mensagem
    [string]$Message = "Olá! Este é um teste do sistema"
)

$headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type" = "application/json"
}

$body = @{
    messaging_product = "whatsapp"
    to = $ToPhoneNumber
    type = "text"
    text = @{
        body = $Message
    }
} | ConvertTo-Json -Depth 5

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📱 Enviando mensagem de teste via WhatsApp Cloud API" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para: $ToPhoneNumber" -ForegroundColor White
Write-Host "Mensagem: $Message" -ForegroundColor White
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "https://graph.facebook.com/v14.0/$PhoneNumberId/messages" -Method Post -Headers $headers -Body $body
    
    Write-Host "✅ Mensagem enviada com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Message ID: $($response.messages[0].id)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Verifique:" -ForegroundColor Cyan
    Write-Host "   1. Seu WhatsApp deve receber a mensagem" -ForegroundColor White
    Write-Host "   2. Responda a mensagem no WhatsApp" -ForegroundColor White
    Write-Host "   3. A resposta deve aparecer no Chatwoot" -ForegroundColor White
    Write-Host "   4. O workflow n8n deve disparar automaticamente" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Links para monitorar:" -ForegroundColor Cyan
    Write-Host "   Chatwoot: https://chatwoot.evolutedigital.com.br" -ForegroundColor White
    Write-Host "   n8n: https://n8n.evolutedigital.com.br/workflow/1/executions" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Erro ao enviar mensagem:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Detalhes:" -ForegroundColor Yellow
    Write-Host $_.ErrorDetails.Message -ForegroundColor Red
}

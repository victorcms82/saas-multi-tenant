# ==================================================
# Enviar mensagem REAL como CLIENTE via Chatwoot API
# ==================================================
# Purpose: Simular mensagem de cliente para testar webhook end-to-end
# ==================================================

param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [int]$AccountId = 1,
    [int]$ConversationId = 4,
    [string]$MessageBody = "qual o preço?"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   ENVIAR MENSAGEM COMO CLIENTE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "💬 Conversation ID: $ConversationId" -ForegroundColor White
Write-Host "📝 Mensagem: '$MessageBody'" -ForegroundColor White
Write-Host ""

# Criar mensagem como INCOMING (do cliente)
$MessagePayload = @{
    content = $MessageBody
    message_type = "incoming"  # CRÍTICO: incoming = mensagem do cliente
    private = $false
} | ConvertTo-Json

Write-Host "📤 Enviando mensagem como CLIENTE..." -ForegroundColor Yellow
Write-Host ""

try {
    $Response = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/conversations/$ConversationId/messages" `
        -Method POST `
        -Headers $Headers `
        -Body $MessagePayload
    
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   ✅ MENSAGEM ENVIADA COM SUCESSO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Detalhes da mensagem:" -ForegroundColor White
    Write-Host "  Message ID: $($Response.id)" -ForegroundColor Gray
    Write-Host "  Content: $($Response.content)" -ForegroundColor Gray
    Write-Host "  Type: $($Response.message_type)" -ForegroundColor Gray
    Write-Host "  Sender: $($Response.sender.name) (type: $($Response.sender.type))" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🎯 O que deve acontecer agora:" -ForegroundColor Cyan
    Write-Host "  1. Chatwoot enviará webhook para n8n" -ForegroundColor White
    Write-Host "  2. n8n processará a mensagem (WF0)" -ForegroundColor White
    Write-Host "  3. LLM gerará resposta" -ForegroundColor White
    Write-Host "  4. PDF será enviado como anexo (se detectado)" -ForegroundColor White
    Write-Host "  5. Resposta aparecerá na conversa" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔍 Verificar em:" -ForegroundColor Yellow
    Write-Host "  - Chatwoot: $ChatwootUrl/app/accounts/$AccountId/conversations/$ConversationId" -ForegroundColor Gray
    Write-Host "  - n8n Executions: https://n8n.evolutedigital.com.br/executions" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "⏱️  Aguarde 5-10 segundos para o processamento..." -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   ❌ ERRO AO ENVIAR MENSAGEM" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        try {
            $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $ResponseBody = $Reader.ReadToEnd()
            Write-Host "Response Body:" -ForegroundColor Yellow
            Write-Host $ResponseBody -ForegroundColor Gray
        } catch {}
    }
    
    exit 1
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   📋 TESTE COMPLETO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

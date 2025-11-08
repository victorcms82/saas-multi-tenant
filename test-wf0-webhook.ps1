# ==================================================
# Test WF0 Webhook - Simular Chatwoot
# ==================================================
# Purpose: Enviar payload de teste para o webhook do WF0
# Usage: .\test-wf0-webhook.ps1 -WebhookUrl "https://seu-n8n.com/webhook/chatwoot-webhook"
# ==================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$WebhookUrl = "https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook",
    
    [Parameter(Mandatory=$false)]
    [string]$MessageBody = "qual o preço?",
    
    [Parameter(Mandatory=$false)]
    [int]$ConversationId = 1
)

# Colors
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host ""
Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host "   TEST WF0 WEBHOOK - CHATWOOT SIMULATOR" -ForegroundColor $InfoColor
Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host ""

# WebhookUrl já tem valor padrão, apenas informar
if ([string]::IsNullOrEmpty($WebhookUrl)) {
    Write-Host "❌ Erro: WebhookUrl não pode estar vazia!" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host "🌐 Webhook URL:" -ForegroundColor $InfoColor
Write-Host "   $WebhookUrl" -ForegroundColor $WarningColor
Write-Host ""

Write-Host "📝 Message Body:" -ForegroundColor $InfoColor
Write-Host "   '$MessageBody'" -ForegroundColor $WarningColor
Write-Host ""
Write-Host "💬 Conversation ID:" -ForegroundColor $InfoColor
Write-Host "   $ConversationId" -ForegroundColor $WarningColor
Write-Host ""

# Payload simulando Chatwoot
$payload = @{
    event = "message_created"
    message_type = "incoming"
    content = $MessageBody
    content_type = "text"
    conversation = @{
        id = $ConversationId
        status = "open"
        custom_attributes = @{
            client_id = "clinica_sorriso_001"
            agent_id = "default"
        }
    }
    sender = @{
        id = 12345
        name = "Cliente Teste"
        phone_number = "+5511999999999"
        type = "contact"
    }
    inbox = @{
        id = 1
        name = "WhatsApp Teste"
        channel_type = "whatsapp"
    }
    attachments = @()
    created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

$payloadJson = $payload | ConvertTo-Json -Depth 10

Write-Host "📦 Payload (preview):" -ForegroundColor $InfoColor
Write-Host $payloadJson.Substring(0, [Math]::Min(300, $payloadJson.Length)) -ForegroundColor Gray
if ($payloadJson.Length -gt 300) {
    Write-Host "   ... (truncated)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "🚀 Enviando requisição..." -ForegroundColor $InfoColor
Write-Host ""

try {
    $response = Invoke-WebRequest `
        -Uri $WebhookUrl `
        -Method POST `
        -Body $payloadJson `
        -ContentType "application/json" `
        -UseBasicParsing `
        -TimeoutSec 30
    
    Write-Host "============================================" -ForegroundColor $SuccessColor
    Write-Host "   ✅ SUCESSO!" -ForegroundColor $SuccessColor
    Write-Host "============================================" -ForegroundColor $SuccessColor
    Write-Host ""
    Write-Host "📊 Status Code: $($response.StatusCode)" -ForegroundColor $SuccessColor
    Write-Host "📏 Response Length: $($response.Content.Length) bytes" -ForegroundColor $InfoColor
    Write-Host ""
    
    # Tentar parsear resposta
    try {
        $responseObj = $response.Content | ConvertFrom-Json
        Write-Host "📄 Response Body:" -ForegroundColor $InfoColor
        Write-Host ($responseObj | ConvertTo-Json -Depth 5) -ForegroundColor Gray
    } catch {
        Write-Host "📄 Response Body (raw):" -ForegroundColor $InfoColor
        Write-Host $response.Content -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor $SuccessColor
    Write-Host "   🎉 WEBHOOK RECEBEU E PROCESSOU!" -ForegroundColor $SuccessColor
    Write-Host "============================================" -ForegroundColor $SuccessColor
    Write-Host ""
    Write-Host "✅ Próximos passos:" -ForegroundColor $InfoColor
    Write-Host "   1. Verifique o n8n (Executions) para ver o workflow rodando" -ForegroundColor $WarningColor
    Write-Host "   2. Verifique se o LLM respondeu corretamente" -ForegroundColor $WarningColor
    Write-Host "   3. Verifique se a mídia foi detectada (keyword: preço)" -ForegroundColor $WarningColor
    Write-Host ""
    
} catch {
    Write-Host "============================================" -ForegroundColor $ErrorColor
    Write-Host "   ❌ ERRO NA REQUISIÇÃO" -ForegroundColor $ErrorColor
    Write-Host "============================================" -ForegroundColor $ErrorColor
    Write-Host ""
    Write-Host "📛 Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor $ErrorColor
    Write-Host "📛 Error Message:" -ForegroundColor $ErrorColor
    Write-Host $_.Exception.Message -ForegroundColor $ErrorColor
    Write-Host ""
    
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "📄 Response Body:" -ForegroundColor $ErrorColor
            Write-Host $responseBody -ForegroundColor Gray
        } catch {
            Write-Host "   (não foi possível ler o corpo da resposta)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "🔍 Troubleshooting:" -ForegroundColor $WarningColor
    Write-Host "   1. Verifique se a URL está correta" -ForegroundColor $InfoColor
    Write-Host "   2. Verifique se o workflow WF0 está ATIVO no n8n" -ForegroundColor $InfoColor
    Write-Host "   3. Verifique se o webhook path está correto: /webhook/chatwoot-webhook" -ForegroundColor $InfoColor
    Write-Host "   4. Teste a URL no navegador (deve retornar erro 411 ou 404, não timeout)" -ForegroundColor $InfoColor
    Write-Host ""
    
    exit 1
}

Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host "   📋 TESTE COMPLETO" -ForegroundColor $InfoColor
Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host ""

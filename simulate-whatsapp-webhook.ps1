# ============================================
# Simula webhook do WhatsApp para o Chatwoot
# ============================================
# Envia um payload simulado como se fosse o Meta enviando
# uma mensagem recebida para o Chatwoot
# ============================================

param(
    [string]$ChatwootWebhookUrl = "https://chatwoot.evolutedigital.com.br/webhooks/whatsapp/+15558354441",
    [string]$MessageText = "Olá! Este é um teste simulado do webhook",
    [string]$SenderPhone = "5521968167730",
    [string]$SenderName = "Victor Castro"
)

# Payload que simula o formato do Meta WhatsApp Cloud API
$payload = @{
    object = "whatsapp_business_account"
    entry = @(
        @{
            id = "32179527034978928"
            changes = @(
                @{
                    value = @{
                        messaging_product = "whatsapp"
                        metadata = @{
                            display_phone_number = "15558354441"
                            phone_number_id = "851688391353928"
                        }
                        contacts = @(
                            @{
                                profile = @{
                                    name = $SenderName
                                }
                                wa_id = $SenderPhone
                            }
                        )
                        messages = @(
                            @{
                                from = $SenderPhone
                                id = "wamid.$(Get-Random)"
                                timestamp = [int][double]::Parse((Get-Date -UFormat %s))
                                text = @{
                                    body = $MessageText
                                }
                                type = "text"
                            }
                        )
                    }
                    field = "messages"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔗 Simulando webhook WhatsApp → Chatwoot" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL: $ChatwootWebhookUrl" -ForegroundColor White
Write-Host "Sender: $SenderName ($SenderPhone)" -ForegroundColor White
Write-Host "Message: $MessageText" -ForegroundColor White
Write-Host ""

try {
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-WebRequest -Uri $ChatwootWebhookUrl -Method Post -Headers $headers -Body $payload
    
    Write-Host "✅ Webhook enviado com sucesso!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Verifique:" -ForegroundColor Cyan
    Write-Host "   1. Chatwoot deve criar uma nova conversa" -ForegroundColor White
    Write-Host "   2. Mensagem deve aparecer como incoming" -ForegroundColor White
    Write-Host "   3. Webhook deve disparar para n8n" -ForegroundColor White
    Write-Host "   4. n8n deve processar e responder" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Links para monitorar:" -ForegroundColor Cyan
    Write-Host "   Chatwoot: https://chatwoot.evolutedigital.com.br" -ForegroundColor White
    Write-Host "   n8n: https://n8n.evolutedigital.com.br/workflow/1/executions" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Erro ao enviar webhook:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    if ($_.ErrorDetails.Message) {
        Write-Host "Detalhes:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}

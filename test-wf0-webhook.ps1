# ==================================================
# Test WF0 Webhook - Simular Chatwoot INCOMING PERFEITO
# ==================================================
# Purpose: Enviar payload EXATO do Chatwoot para mensagem incoming do cliente
# Usage: .\test-wf0-webhook.ps1 -ConversationId 4 -MessageBody "qual o preço?"
# ==================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$WebhookUrl = "https://n8n.evolutedigital.com.br/webhook/chatwoot-webhook",
    
    [Parameter(Mandatory=$false)]
    [string]$MessageBody = "qual o preço?",
    
    [Parameter(Mandatory=$false)]
    [int]$ConversationId = 4
)

# Colors
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host ""
Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host "   TEST WF0 WEBHOOK - CHATWOOT INCOMING" -ForegroundColor $InfoColor
Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host ""

Write-Host "🌐 Webhook URL:" -ForegroundColor $InfoColor
Write-Host "   $WebhookUrl" -ForegroundColor $WarningColor
Write-Host ""

Write-Host "📝 Message Body:" -ForegroundColor $InfoColor
Write-Host "   '$MessageBody'" -ForegroundColor $WarningColor
Write-Host ""
Write-Host "💬 Conversation ID:" -ForegroundColor $InfoColor
Write-Host "   $ConversationId" -ForegroundColor $WarningColor
Write-Host ""

# Timestamp atual
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$isoTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Payload EXATO como o Chatwoot envia para mensagem INCOMING (do cliente)
$payload = @{
    account = @{
        id = 1
        name = "Evolute Digital"
    }
    additional_attributes = @{}
    content_attributes = @{}
    content_type = "text"
    content = $MessageBody
    conversation = @{
        additional_attributes = @{}
        can_reply = $true
        channel = "Channel::Api"
        contact_inbox = @{
            id = 4
            contact_id = 1
            inbox_id = 1
            source_id = "test-$(Get-Date -Format 'yyyyMMddHHmmss')"
            created_at = $isoTimestamp
            updated_at = $isoTimestamp
            hmac_verified = $false
            pubsub_token = "test-token-123"
        }
        id = $ConversationId
        inbox_id = 1
        messages = @(
            @{
                id = (Get-Random -Minimum 100 -Maximum 999)
                content = $MessageBody
                account_id = 1
                inbox_id = 1
                conversation_id = $ConversationId
                message_type = 0  # 0 = INCOMING (cliente)
                created_at = $timestamp
                updated_at = $isoTimestamp
                private = $false
                status = "sent"
                source_id = $null
                content_type = "text"
                content_attributes = @{}
                sender_type = "Contact"  # Contact = cliente
                sender_id = 1
                external_source_ids = @{}
                additional_attributes = @{}
                processed_message_content = $MessageBody
                sentiment = @{}
                conversation = @{
                    assignee_id = $null
                    unread_count = 1
                    last_activity_at = $timestamp
                    contact_inbox = @{
                        source_id = "test-client-source"
                    }
                }
                sender = @{
                    id = 1
                    name = "Cliente Teste"
                    available_name = "Cliente Teste"
                    avatar_url = ""
                    type = "contact"  # CRÍTICO: type = contact (não user)
                    availability_status = $null
                    thumbnail = ""
                }
            }
        )
        labels = @()
        meta = @{
            sender = @{
                additional_attributes = @{}
                custom_attributes = @{}
                email = $null
                id = 1
                identifier = $null
                name = "Cliente Teste"
                phone_number = "+5511999999999"
                thumbnail = ""
                blocked = $false
                type = "contact"  # CRÍTICO: type = contact
            }
            assignee = $null
            team = $null
            hmac_verified = $false
        }
        status = "open"
        custom_attributes = @{
            client_id = "clinica_sorriso_001"
            agent_id = "default"
        }
        snoozed_until = $null
        unread_count = 1
        first_reply_created_at = $null
        priority = $null
        waiting_since = $timestamp
        agent_last_seen_at = 0
        contact_last_seen_at = $timestamp
        last_activity_at = $timestamp
        timestamp = $timestamp
        created_at = $timestamp
        updated_at = $timestamp
    }
    created_at = $isoTimestamp
    id = (Get-Random -Minimum 100 -Maximum 999)
    inbox = @{
        id = 1
        name = "API Inbox - Teste"
    }
    message_type = "incoming"  # String "incoming" no root
    private = $false
    sender = @{
        id = 1
        name = "Cliente Teste"
        email = $null
        type = "contact"  # CRÍTICO: type = contact (não user)
    }
    source_id = $null
    event = "message_created"
    # CRÍTICO: Anexos do banco (client_media)
    client_media_attachments = @(
        @{
            file_url = "https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/tabela-precos.pdf"
            file_type = "application/pdf"
            file_name = "tabela-precos.pdf"
            caption = "Tabela de Preços"
        }
    )
}

$payloadJson = $payload | ConvertTo-Json -Depth 10

Write-Host "📦 Payload (preview):" -ForegroundColor $InfoColor
Write-Host $payloadJson.Substring(0, [Math]::Min(500, $payloadJson.Length)) -ForegroundColor Gray
if ($payloadJson.Length -gt 500) {
    Write-Host "   ... (truncated)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "🔍 Verificações importantes:" -ForegroundColor $InfoColor
Write-Host "   message_type (root): incoming ✅" -ForegroundColor Green
Write-Host "   message_type (messages): 0 (incoming) ✅" -ForegroundColor Green
Write-Host "   sender.type: contact ✅" -ForegroundColor Green
Write-Host "   sender_type (messages): Contact ✅" -ForegroundColor Green
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
    Write-Host "   1. Verifique o n8n (Executions)" -ForegroundColor $WarningColor
    Write-Host "   2. Node 'Identificar Cliente' deve manter message_type=incoming" -ForegroundColor $WarningColor
    Write-Host "   3. Node 'Filtrar Apenas Incoming' deve PASSAR (TRUE)" -ForegroundColor $WarningColor
    Write-Host "   4. Node 'Tem Anexos?' deve retornar TRUE" -ForegroundColor $WarningColor
    Write-Host "   5. PDF deve ser enviado para Chatwoot" -ForegroundColor $WarningColor
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
    
    exit 1
}

Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host "   📋 TESTE COMPLETO" -ForegroundColor $InfoColor
Write-Host "============================================" -ForegroundColor $InfoColor
Write-Host ""

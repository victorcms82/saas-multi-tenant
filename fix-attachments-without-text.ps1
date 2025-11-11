# Script para atualizar workflow no n8n
# Correção: Aceitar mensagens com anexo mesmo sem texto

Write-Host "🔄 Atualizando workflow no n8n..." -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  INSTRUÇÕES:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Abra n8n: https://n8n.evolutedigital.com.br" -ForegroundColor White
Write-Host "2. Abra o workflow: WF0-Gestor-Universal-REORGANIZADO" -ForegroundColor White
Write-Host "3. Clique no node 'Identificar Cliente e Agente'" -ForegroundColor White
Write-Host "4. Substitua o código pelo seguinte:" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

$code = @"
// Identifica cliente, agente e canal
const payload = `$input.item.json;

// Extrair informações do webhook Chatwoot
const conversationId = payload.body?.conversation?.id || payload.conversation?.id;
const contactId = payload.body?.sender?.id || payload.sender?.id;

// Extrair message_body com fallbacks
let messageBody = 
  payload.content ||              // Webhook n8n (nivel raiz)
  payload.body?.content ||        // Chatwoot direto
  payload.body?.body?.content ||  // Chatwoot encapsulado
  '';

// Canal e attachments
const channel = payload.inbox?.channel_type || payload.body?.inbox?.channel_type || 'whatsapp';
const attachments = payload.attachments || payload.body?.attachments || [];

// VALIDAÇÃO: Abortar se message_body vazio E sem attachments
if ((!messageBody || messageBody.trim() === '') && attachments.length === 0) {
  console.error('❌ ERRO: message_body vazio E sem attachments. Payload keys:', Object.keys(payload));
  throw new Error('Mensagem vazia sem anexos');
}

// Se só tem attachment sem texto, criar mensagem padrão
if ((!messageBody || messageBody.trim() === '') && attachments.length > 0) {
  messageBody = '[Arquivo enviado]';
  console.log('📎 Attachment sem texto. Message_body definido como:', messageBody);
}

// Converter message_type de número para string
// Chatwoot envia: 0=incoming, 1=outgoing, 2=activity
let messageType = payload.message_type || payload.body?.message_type || 'incoming';
if (typeof messageType === 'number') {
  messageType = messageType === 0 ? 'incoming' : messageType === 1 ? 'outgoing' : 'activity';
}

const contentType = payload.content_type || payload.body?.content_type || 'text';

// Extrair custom attributes
const customAttributes = payload.conversation?.custom_attributes || payload.body?.conversation?.custom_attributes || {};
const clientId = customAttributes.client_id || 'clinica_sorriso_001';
const agentId = customAttributes.agent_id || 'default';

const sender = payload.sender || payload.body?.sender || { type: 'contact' };

// Extrair client_media_attachments (mídias do banco Supabase)
const clientMediaAttachments = payload.client_media_attachments || payload.body?.client_media_attachments || [];

return {
  json: {
    client_id: clientId,
    agent_id: agentId,
    conversation_id: conversationId,
    contact_id: contactId,
    channel: channel,
    message_body: messageBody,
    message_type: messageType,
    content_type: contentType,
    attachments: attachments,
    has_attachments: attachments.length > 0,
    client_media_attachments: clientMediaAttachments,
    sender: sender,
    body: payload.body || payload,
    timestamp: new Date().toISOString(),
    original_payload: payload
  }
};
"@

Write-Host $code -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Clique em 'Execute Node' para testar" -ForegroundColor White
Write-Host "6. Salve o workflow (Ctrl+S)" -ForegroundColor White
Write-Host "7. Ative o workflow" -ForegroundColor White
Write-Host ""
Write-Host "✅ MUDANÇA:" -ForegroundColor Green
Write-Host "   Agora aceita mensagens com APENAS anexo (sem texto)" -ForegroundColor White
Write-Host "   Define message_body como '[Arquivo enviado]' nesses casos" -ForegroundColor White
Write-Host ""
Write-Host "🧪 TESTE:" -ForegroundColor Cyan
Write-Host "   Envie uma foto sem legenda no WhatsApp" -ForegroundColor White
Write-Host "   Bot deve responder normalmente" -ForegroundColor White
Write-Host ""

Read-Host "Pressione ENTER quando terminar"
"@

Set-Content -Path "update-workflow-attachments.ps1" -Value $code -Encoding UTF8

Write-Host "✅ Código salvo em: update-workflow-attachments.ps1" -ForegroundColor Green

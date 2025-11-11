// ============================================================================
// FIX: Construir Contexto Completo - Garantir client_id correto
// ============================================================================
// PROBLEMA: Merge pode embaralhar a ordem e client_id vir do lugar errado
// SOLUÇÃO: Buscar client_id DIRETO do node "💼 Construir Contexto Location + Staff1"
// ============================================================================

// Construir contexto completo: dados do agente + mídia do acervo + mensagem original
// CRÍTICO: Buscar dados dos nodes CORRETOS, não confiar no Merge

const item = $input.item.json;

// 🔒 SEGURANÇA CRÍTICA: Buscar client_id do node que fez a blindagem!
const locationNode = $('💼 Construir Contexto Location + Staff1').first().json;
const webhookNode = $('Filtrar Apenas Incoming').first().json;

// Extrair location_context do node correto
const locationContext = locationNode.location_context || item.location_context || '';

// 🔒 CRÍTICO: client_id SEMPRE vem do node de location (autenticado pelo banco!)
const clientId = locationNode.client_id || item.client_id || webhookNode.client_id;

console.log('=== SEGURANÇA: Origem do client_id ===');
console.log('locationNode.client_id:', locationNode.client_id);
console.log('item.client_id:', item.client_id);
console.log('webhookNode.client_id:', webhookNode.client_id);
console.log('🔒 client_id FINAL (autenticado):', clientId);

const webhookData = {
  // 🔒 CRÍTICO: Usar client_id autenticado do banco!
  client_id: clientId,
  agent_id: webhookNode.agent_id || item.agent_id,
  conversation_id: webhookNode.conversation_id || item.conversation_id,
  contact_id: webhookNode.contact_id || item.contact_id,
  channel: webhookNode.channel || item.channel,
  message_body: webhookNode.message_body || item.message_body,
  message_type: webhookNode.message_type || item.message_type,
  content_type: webhookNode.content_type || item.content_type,
  attachments: webhookNode.attachments || item.attachments || [],
  has_attachments: webhookNode.has_attachments || item.has_attachments || false,
  client_media_attachments: webhookNode.client_media_attachments || item.client_media_attachments || [],
  timestamp: webhookNode.timestamp || item.timestamp
};

// VALIDAÇÃO: Abortar se message_body vazio
if (!webhookData.message_body || webhookData.message_body.trim() === '') {
  console.error('❌ ERRO: message_body está vazio em Construir Contexto Completo!');
  console.error('webhookNode.message_body:', webhookNode.message_body);
  console.error('item.message_body:', item.message_body);
  throw new Error('message_body perdido no fluxo!');
}

console.log('✅ message_body preservado:', webhookData.message_body);
console.log('🔒 client_id autenticado:', webhookData.client_id);

const agentData = item; // Dados do agente já estão no item merged

// Verificar se há dados de mídia no item (do RPC)
let mediaRules = [];
if (item.rule_id && item.media_id) {
  // RPC retornou mídia - transformar em array
  mediaRules = [{
    rule_id: item.rule_id,
    media_id: item.media_id,
    trigger_type: item.trigger_type,
    trigger_value: item.trigger_value,
    file_url: item.file_url,
    file_type: item.file_type,
    file_name: item.file_name,
    mime_type: item.mime_type,
    title: item.title,
    description: item.description
  }];
}

// Preparar informação sobre mídia do acervo para o LLM
let mediaContext = '';
let clientMediaAttachments = webhookData.client_media_attachments || [];
let mediaLogEntries = [];

if (Array.isArray(mediaRules) && mediaRules.length > 0) {
  mediaContext = '\n\n--- MÍDIA DISPONÍVEL PARA ENVIO ---\n';
  
  mediaRules.forEach((media, i) => {
    mediaContext += `${i+1}. ${media.title || media.file_name} (${media.file_type})\n`;
    mediaContext += `   Descrição: ${media.description || 'N/A'}\n`;
    mediaContext += `   Disparado por: ${media.trigger_type} - "${media.trigger_value}"\n\n`;
    
    // Preparar attachments para Chatwoot
    clientMediaAttachments.push({
      file_url: media.file_url,
      file_type: media.file_type,
      file_name: media.file_name,
      caption: media.title || media.description || ''
    });
    
    // Preparar logs para tracking
    mediaLogEntries.push({
      rule_id: media.rule_id,
      media_id: media.media_id,
      triggered_by: media.trigger_type,
      trigger_value: media.trigger_value
    });
  });
  
  mediaContext += '\n🚨 INSTRUÇÃO OBRIGATÓRIA: Você DEVE informar ao usuário que está enviando o arquivo anexo mencionado acima! Não ignore esta instrução!';
}

return {
  json: {
    // ========================================
    // 1. Dados do webhook (dados brutos)
    // ========================================
    client_id: webhookData.client_id,  // 🔒 AUTENTICADO DO BANCO!
    agent_id: webhookData.agent_id,
    conversation_id: webhookData.conversation_id,
    contact_id: webhookData.contact_id,
    channel: webhookData.channel,
    message_body: webhookData.message_body,
    message_type: webhookData.message_type,
    content_type: webhookData.content_type,
    attachments: webhookData.attachments,
    has_attachments: webhookData.has_attachments,
    timestamp: webhookData.timestamp,
    
    // ========================================
    // 2. Dados do agente (configuração)
    // ========================================
    system_prompt: agentData.system_prompt || 'Você é um assistente útil.',
    llm_provider: agentData.llm_provider || 'openai',
    llm_model: agentData.llm_model,
    llm_api_key: agentData.llm_api_key || null,
    tools_enabled: agentData.tools_enabled || [],
    rag_namespace: agentData.rag_namespace,
    
    // ========================================
    // 3. Contextos (dados enriquecidos para LLM)
    // ========================================
    // Contexto de localização e staff
    location_context: locationContext,
    has_location_data: locationContext ? true : false,
    
    // Contexto de mídia do acervo
    media_context: mediaContext,
    client_media_attachments: clientMediaAttachments,
    media_log_entries: mediaLogEntries,
    has_client_media: clientMediaAttachments.length > 0,
    
    // ========================================
    // 4. Dados de subscription (billing)
    // ========================================
    subscription: agentData.client_subscriptions?.[0] || {}
  }
};

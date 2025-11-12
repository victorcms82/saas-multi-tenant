// ============================================================================
// NODE: 📦 Preparar Mensagens para Memória
// ============================================================================
// Preparar DUAS mensagens para salvar: usuário + assistente
const data = $input.item.json;

// Mensagem 1: Usuário (input)
const userMessage = {
  p_client_id: data.client_id,
  p_conversation_id: data.conversation_id,
  p_message_role: 'user',
  p_message_content: data.message_body,
  p_contact_id: data.contact_id,
  p_agent_id: data.agent_id,
  p_channel: data.channel,
  p_has_attachments: data.has_attachments || false,
  p_attachments: data.attachments || [],
  p_metadata: {
    timestamp: data.timestamp
  }
};

// Mensagem 2: Assistente (output)
const assistantMessage = {
  p_client_id: data.client_id,
  p_conversation_id: data.conversation_id,
  p_message_role: 'assistant',
  p_message_content: data.final_response,
  p_contact_id: data.contact_id,
  p_agent_id: data.agent_id,
  p_channel: data.channel,
  p_has_attachments: data.has_client_media || false,
  p_attachments: data.client_media_attachments || [],
  p_metadata: {
    llm_model: data.llm_model || 'gpt-4o-mini',
    had_tool_calls: data.tool_results && data.tool_results.length > 0,
    history_count: data.history_messages_count || 0
  }
};

console.log('💾 Preparando para salvar 2 mensagens na memória');
console.log('User message:', userMessage.p_message_content.substring(0, 50));
console.log('Assistant message:', assistantMessage.p_message_content.substring(0, 50));

// Retornar ambas as mensagens como array
// n8n vai processar cada uma separadamente devido ao batching
return [
  { json: userMessage },
  { json: assistantMessage }
];

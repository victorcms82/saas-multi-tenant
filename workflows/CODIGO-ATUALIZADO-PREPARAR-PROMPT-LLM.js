// ============================================================================
// CÓDIGO ATUALIZADO PARA O NODE: "Preparar Prompt LLM"
// ============================================================================
// AÇÃO: SUBSTITUIR o código existente por este
// ============================================================================

// Preparar prompt completo para o LLM COM HISTÓRICO DE CONVERSA
let systemPrompt = $input.item.json.system_prompt;
const messageBody = $input.item.json.message_body;
const ragContext = $input.item.json.rag_context || '';
const mediaContext = $input.item.json.media_context || '';

// 🆕 NOVO: Buscar histórico de conversa
const conversationHistory = $input.item.json.conversation_history || '';

// CRÍTICO: Se há mídia disponível, injetar instrução no SYSTEM PROMPT
if (mediaContext && mediaContext.includes('MÍDIA DISPONÍVEL')) {
  systemPrompt += '\n\n--- INSTRUÇÃO CRÍTICA SOBRE MÍDIA ---\n';
  systemPrompt += 'Se houver arquivos de mídia disponíveis mencionados no contexto do usuário, você DEVE informar que está enviando esses arquivos como anexo. Não ignore esta instrução!';
}

// 🆕 MODIFICADO: Adicionar histórico ao prompt final
const fullPrompt = systemPrompt + 
  (ragContext ? '\n\n--- CONTEXTO DO RAG ---\n' + ragContext : '') +
  mediaContext +
  conversationHistory +  // ⬅️ NOVO: Histórico de conversa
  '\n\n--- MENSAGEM ATUAL DO USUÁRIO ---\n' + messageBody;

return {
  json: {
    ...($input.item.json),
    system_prompt: systemPrompt,  // Atualizado com instrução de mídia
    llm_prompt: fullPrompt
  }
};

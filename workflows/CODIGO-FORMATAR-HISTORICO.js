// ============================================================================
// NODE: 📝 Formatar Histórico para LLM
// ============================================================================
// Formatar histórico de conversa para contexto do LLM
const previousData = $('Query RAG (Namespace Isolado)').first().json;
const historyData = $input.item.json;

// Verificar se há histórico
let conversationHistory = '';

if (Array.isArray(historyData) && historyData.length > 0) {
  conversationHistory = '\n\n--- HISTÓRICO DA CONVERSA ---\n';
  
  // Ordenar do mais antigo para mais recente (invertido)
  const sortedHistory = [...historyData].reverse();
  
  sortedHistory.forEach(msg => {
    const role = msg.message_role === 'user' ? '👤 Cliente' : '🤖 Assistente';
    const timestamp = new Date(msg.message_timestamp).toLocaleString('pt-BR');
    
    conversationHistory += `\n[${timestamp}] ${role}:\n${msg.message_content}\n`;
  });
  
  conversationHistory += '\n--- FIM DO HISTÓRICO ---\n';
  conversationHistory += '\n📌 IMPORTANTE: Use o histórico acima para manter consistência nas respostas e entender o contexto da conversa atual.\n';
  
  console.log('✅ Histórico carregado:', historyData.length, 'mensagens');
} else {
  conversationHistory = '\n\n--- NOVA CONVERSA (sem histórico anterior) ---\n';
  console.log('ℹ️ Primeira mensagem da conversa');
}

return {
  json: {
    ...previousData,
    conversation_history: conversationHistory,
    history_messages_count: historyData.length || 0
  }
};

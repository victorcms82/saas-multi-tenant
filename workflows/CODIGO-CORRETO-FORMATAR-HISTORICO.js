// ============================================================================
// CÓDIGO CORRIGIDO: Node "📝 Formatar Histórico para LLM"
// ============================================================================
// PROBLEMA: $input.first().json pega apenas 1 mensagem
// SOLUÇÃO: Usar $input.all() para pegar todas as mensagens
// ============================================================================

const previousData = $('Query RAG (Namespace Isolado)').first().json;

// ✅ CORREÇÃO: Buscar TODAS as mensagens do input
const allInputs = $input.all();

// Extrair array de mensagens
let historyData = [];

console.log('🔍 DEBUG Formatar Histórico:');
console.log('allInputs.length:', allInputs.length);

if (allInputs.length > 0) {
  // Extrair .json de cada input
  historyData = allInputs.map(input => input.json);
  
  console.log('✅ Histórico extraído:', historyData.length, 'mensagens');
} else {
  console.log('⚠️ Nenhuma mensagem no input');
}

// Verificar se há histórico
let conversationHistory = '';

if (historyData.length > 0) {
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
  
  console.log('✅ Histórico formatado com', historyData.length, 'mensagens');
} else {
  conversationHistory = '\n\n--- NOVA CONVERSA (sem histórico anterior) ---\n';
  console.log('ℹ️ Primeira mensagem da conversa (sem histórico)');
}

return {
  json: {
    ...previousData,
    conversation_history: conversationHistory,
    history_messages_count: historyData.length
  }
};

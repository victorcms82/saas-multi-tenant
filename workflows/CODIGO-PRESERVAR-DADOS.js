// ============================================================================
// NODE: 🔄 Preservar Dados Após Memória
// ============================================================================
// Preservar dados originais após salvar na memória
const originalData = $('Construir Resposta Final').first().json;
const memorySaveResults = $input.all();

console.log('✅ Mensagens salvas na memória:', memorySaveResults.length);

// Extrair IDs salvos (se retornados pela função RPC)
const savedIds = memorySaveResults.map(r => r.json || r).filter(id => id);

return {
  json: {
    ...originalData,
    memory_saved: true,
    memory_message_ids: savedIds,
    memory_save_count: memorySaveResults.length
  }
};

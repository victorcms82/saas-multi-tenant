// ============================================================================
// 🔍 DEBUG SIMPLES - TESTAR SE NODE EXECUTA
// ============================================================================
// Cole este código no node para confirmar que ele está executando
// ============================================================================

console.log('========================================');
console.log('🔍 DEBUG: Node executando!');
console.log('========================================');

const items = $input.all();
console.log('📦 Total de items recebidos:', items.length);

const processedItems = [];

for (const item of items) {
  const data = item.json;
  
  console.log('📋 Item:', JSON.stringify(data, null, 2).substring(0, 500));
  console.log('📎 Attachments:', data.attachments ? data.attachments.length : 0);
  
  // Modifica o message_body para confirmar que o código está processando
  const modifiedData = {
    ...data,
    message_body: data.message_body + '\n\n[🔍 DEBUG: NODE EXECUTOU COM SUCESSO!]',
    debug_processed: true,
    debug_timestamp: new Date().toISOString()
  };
  
  processedItems.push({ json: modifiedData });
  
  console.log('✅ Item processado com sucesso');
}

console.log('========================================');
console.log('✅ DEBUG: Processamento completo!');
console.log('📦 Items processados:', processedItems.length);
console.log('========================================');

return processedItems;

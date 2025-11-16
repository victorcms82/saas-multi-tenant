// ============================================================================
// NODE: Query RAG (Namespace Isolado) - IMPLEMENTAÇÃO REAL
// ============================================================================
// Descrição: Busca documentos similares usando vector search no Supabase
// Substitui: Placeholder que retornava array vazio
// Data: 16/11/2025
// ============================================================================

const data = $input.item.json;

// Extrair dados necessários
const clientId = data.client_id;
const agentId = data.agent_id || 'default';
const messageBody = data.message_body || '';
const openaiApiKey = data.llm_api_key || process.env.OPENAI_API_KEY;

console.log('=== QUERY RAG INICIADO ===');
console.log('Client ID:', clientId);
console.log('Agent ID:', agentId);
console.log('Query:', messageBody.substring(0, 100) + '...');

// Validações
if (!clientId || !agentId) {
  console.error('❌ ERRO: client_id ou agent_id ausente!');
  return {
    json: {
      ...data,
      rag_results: [],
      rag_context: '',
      rag_error: 'client_id ou agent_id ausente'
    }
  };
}

if (!messageBody || messageBody.trim() === '') {
  console.log('⚠️ Mensagem vazia, pulando RAG');
  return {
    json: {
      ...data,
      rag_results: [],
      rag_context: ''
    }
  };
}

try {
  // ============================================================================
  // PASSO 1: Gerar Embedding da Pergunta do Usuário
  // ============================================================================
  
  console.log('🔄 Gerando embedding da query...');
  
  const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'text-embedding-ada-002',
      input: messageBody
    })
  });
  
  if (!embeddingResponse.ok) {
    const errorText = await embeddingResponse.text();
    console.error('❌ Erro ao gerar embedding:', errorText);
    throw new Error(`OpenAI Embeddings falhou: ${embeddingResponse.status}`);
  }
  
  const embeddingData = await embeddingResponse.json();
  const queryEmbedding = embeddingData.data[0].embedding;
  
  console.log('✅ Embedding gerado:', queryEmbedding.length, 'dimensões');
  console.log('💰 Custo embedding: ~$0.00001');
  
  // ============================================================================
  // PASSO 2: Buscar Documentos Similares no Supabase
  // ============================================================================
  
  console.log('🔍 Buscando documentos similares no Supabase...');
  
  const supabaseUrl = 'https://vnlfgnfaortdvmraoapq.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U';
  
  const ragResponse = await fetch(`${supabaseUrl}/rest/v1/rpc/query_rag_documents`, {
    method: 'POST',
    headers: {
      'apikey': supabaseKey,
      'Authorization': `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      p_client_id: clientId,
      p_agent_id: agentId,
      p_query_embedding: queryEmbedding,
      p_limit: 5,           // Top 5 documentos
      p_threshold: 0.7      // Similaridade mínima 70%
    })
  });
  
  if (!ragResponse.ok) {
    const errorText = await ragResponse.text();
    console.error('❌ Erro ao buscar RAG:', errorText);
    
    // Se tabela não existe ainda, retornar vazio (não é erro crítico)
    if (errorText.includes('relation "rag_documents" does not exist')) {
      console.warn('⚠️ Tabela rag_documents ainda não foi criada. Execute migration 020.');
      return {
        json: {
          ...data,
          rag_results: [],
          rag_context: '',
          rag_warning: 'RAG não configurado (tabela não existe)'
        }
      };
    }
    
    throw new Error(`Supabase RAG falhou: ${ragResponse.status}`);
  }
  
  const ragResults = await ragResponse.json();
  
  console.log('📊 Documentos encontrados:', ragResults.length);
  
  // ============================================================================
  // PASSO 3: Formatar Contexto para o LLM
  // ============================================================================
  
  let ragContext = '';
  
  if (ragResults.length > 0) {
    console.log('✅ RAG ativo! Formatando contexto...');
    
    ragContext = '\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    ragContext += '📚 INFORMAÇÕES DA BASE DE CONHECIMENTO\n';
    ragContext += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
    
    ragResults.forEach((doc, index) => {
      const similarity = (doc.similarity * 100).toFixed(0);
      const source = doc.file_name || doc.source_type || 'documento';
      
      ragContext += `${index + 1}. [${source}] (relevância: ${similarity}%)\n`;
      ragContext += `${doc.content}\n\n`;
      
      // Adicionar metadados se existir
      if (doc.metadata && Object.keys(doc.metadata).length > 0) {
        ragContext += `   📎 Tags: ${doc.metadata.tags ? doc.metadata.tags.join(', ') : 'N/A'}\n\n`;
      }
      
      console.log(`   • Doc ${index + 1}: ${similarity}% similar - "${doc.content.substring(0, 50)}..."`);
    });
    
    ragContext += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    ragContext += '💡 IMPORTANTE: Use as informações acima para responder com precisão. ';
    ragContext += 'Se a resposta estiver no contexto, cite a fonte.\n';
    ragContext += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    
    console.log('✅ Contexto RAG formatado:', ragContext.length, 'caracteres');
  } else {
    console.log('ℹ️ Nenhum documento relevante encontrado (similaridade < 70%)');
    ragContext = '';
  }
  
  // ============================================================================
  // PASSO 4: Retornar Dados Enriquecidos
  // ============================================================================
  
  return {
    json: {
      ...data,
      rag_results: ragResults,
      rag_context: ragContext,
      rag_found: ragResults.length > 0,
      rag_count: ragResults.length,
      rag_query_embedding: queryEmbedding, // Salvar para cache futuro
      rag_executed: true
    }
  };
  
} catch (error) {
  console.error('❌ ERRO no Query RAG:', error.message);
  console.error('Stack:', error.stack);
  
  // Retornar sem RAG (não bloquear o fluxo)
  return {
    json: {
      ...data,
      rag_results: [],
      rag_context: '',
      rag_error: error.message,
      rag_executed: false
    }
  };
}

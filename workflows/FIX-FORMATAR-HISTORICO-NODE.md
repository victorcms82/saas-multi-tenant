# 🔧 FIX: Node "📝 Formatar Histórico para LLM"

## 🔴 PROBLEMA IDENTIFICADO

O node está recebendo 50 mensagens do "🧠 Buscar Histórico", mas processando como array vazio.

---

## 📊 DEBUG

**Input recebido (do node anterior):**
```json
[
  {
    "message_role": "user",
    "message_content": "pode me chamar pelo primeiro nome?",
    "message_timestamp": "2025-11-12T21:08:43.739699+00:00",
    ...
  },
  {
    "message_role": "assistant",
    "message_content": "Desculpe, mas não tenho acesso...",
    ...
  },
  // ... 48 mensagens mais
]
```

**Output atual (ERRADO):**
```json
{
  "conversation_history": "\n\n--- NOVA CONVERSA (sem histórico anterior) ---\n",
  "history_messages_count": 0
}
```

---

## 🐛 CÓDIGO ATUAL (BUGADO)

```javascript
// ❌ CÓDIGO BUGADO
const previousData = $('Query RAG (Namespace Isolado)').first().json;
const historyResponse = $input.first().json;  // ← PROBLEMA!
const historyData = Array.isArray(historyResponse) ? historyResponse : [];

// Se historyResponse for um OBJETO, vira []
```

---

## ✅ CÓDIGO CORRIGIDO

```javascript
// ✅ CÓDIGO CORRETO
const previousData = $('Query RAG (Namespace Isolado)').first().json;

// Buscar do INPUT (que vem do HTTP Request)
const historyResponse = $input.first().json;

// Extrair array de mensagens (pode estar em .data ou direto)
let historyData = [];

if (Array.isArray(historyResponse)) {
  // HTTP retornou array direto
  historyData = historyResponse;
} else if (historyResponse && Array.isArray(historyResponse.data)) {
  // HTTP retornou { data: [...] }
  historyData = historyResponse.data;
} else if (historyResponse && typeof historyResponse === 'object') {
  // HTTP retornou objeto único - transformar em array
  historyData = [historyResponse];
} else {
  // Fallback: array vazio
  historyData = [];
}

console.log('🔍 DEBUG Formatar Histórico:');
console.log('historyResponse type:', typeof historyResponse);
console.log('historyResponse isArray:', Array.isArray(historyResponse));
console.log('historyData.length:', historyData.length);

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
  
  console.log('✅ Histórico carregado:', historyData.length, 'mensagens');
} else {
  conversationHistory = '\n\n--- NOVA CONVERSA (sem histórico anterior) ---\n';
  console.log('ℹ️ Primeira mensagem da conversa (ou histórico não encontrado)');
}

return {
  json: {
    ...previousData,
    conversation_history: conversationHistory,
    history_messages_count: historyData.length
  }
};
```

---

## 🎯 AÇÃO IMEDIATA

1. Abra o workflow no n8n
2. Edite o node **"📝 Formatar Histórico para LLM"**
3. Substitua o código pelo código corrigido acima
4. Clique em **Save**
5. Teste enviando nova mensagem

---

## 🧪 TESTE

Após corrigir, envie:

**Mensagem 1:** "Olá, meu nome é [SEU NOME]"  
**Mensagem 2:** "Qual é o meu nome?"

**Resultado esperado:** Bot deve responder com seu nome! ✅

---

## 📝 NOTAS

- O problema estava na extração do array de mensagens
- HTTP Request do Supabase RPC retorna array direto
- Código antigo não lidava com isso corretamente
- Adicionei logs de debug para facilitar troubleshooting futuro

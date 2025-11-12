# 🧠 Implementação de Memória de Conversa - Instruções para n8n

## ✅ Parte 1: Migration Executada

- ✅ Tabela `conversation_memory` criada
- ✅ Índices de performance criados
- ✅ RLS policies aplicadas
- ✅ Função `get_conversation_history()` criada
- ✅ Função `save_conversation_message()` criada

---

## 📝 Parte 2: Adicionar 3 Nodes no Workflow

Abra o workflow **"[PLATAFORMA SaaS] WF 0: Gestor (Chatwoot) [DINÂMICO] Versão Final"** no n8n e adicione os seguintes nodes:

---

### 🔹 NODE 1: Buscar Histórico de Conversa (HTTP Request)

**Posição:** Após o node `Query RAG (Namespace Isolado)`, antes de `Preparar Prompt LLM`

**Configuração:**

```
Nome: 🧠 Buscar Histórico de Conversa (RPC)
Tipo: HTTP Request
Método: POST
URL: https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/get_conversation_history
```

**Headers:**
```
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U

Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U

Content-Type: application/json
```

**Body (JSON):**
```json
{
  "p_client_id": "{{ $json.client_id }}",
  "p_conversation_id": {{ $json.conversation_id }},
  "p_limit": 10
}
```

**Opções:**
- Response → Full Response: `false`

**Credenciais:** Use `Supabase API` (httpCustomAuth)

---

### 🔹 NODE 2: Formatar Histórico para LLM (Code)

**Posição:** Após `🧠 Buscar Histórico de Conversa`, antes de `Preparar Prompt LLM`

**Configuração:**

```
Nome: 📝 Formatar Histórico para LLM
Tipo: Code (JavaScript)
```

**Código:**
```javascript
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
```

---

### 🔹 NODE 3: Modificar "Preparar Prompt LLM"

**Ação:** EDITAR o node existente `Preparar Prompt LLM`

**Localizar linha:**
```javascript
const fullPrompt = systemPrompt + 
  (ragContext ? '\n\n--- CONTEXTO DO RAG ---\n' + ragContext : '') +
  mediaContext +
  '\n\n--- MENSAGEM DO USUÁRIO ---\n' + messageBody;
```

**SUBSTITUIR por:**
```javascript
// NOVA VERSÃO COM HISTÓRICO
const conversationHistory = $input.item.json.conversation_history || '';

const fullPrompt = systemPrompt + 
  (ragContext ? '\n\n--- CONTEXTO DO RAG ---\n' + ragContext : '') +
  mediaContext +
  conversationHistory +  // ⬅️ NOVO: Adicionar histórico
  '\n\n--- MENSAGEM ATUAL DO USUÁRIO ---\n' + messageBody;
```

---

### 🔹 NODE 4: Salvar Mensagens na Memória (HTTP Request)

**Posição:** Após `Construir Resposta Final`, antes de `Tem Mídia do Acervo?`

**Configuração:**

```
Nome: 💾 Salvar em Memória (User + Assistant)
Tipo: HTTP Request
Método: POST
URL: https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/save_conversation_message
```

**Headers:**
```
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U

Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U

Content-Type: application/json
```

**Body (Code - JavaScript):**

⚠️ **IMPORTANTE:** Selecionar **"Define using JavaScript"** para o Body

```javascript
// Salvar DUAS mensagens: a do usuário e a do assistente
const data = $input.item.json;

// Mensagem 1: Usuário
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

// Mensagem 2: Assistente (resposta do bot)
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
    had_tool_calls: data.tool_results && data.tool_results.length > 0
  }
};

// Retornar ambas as mensagens como array
// n8n vai fazer 2 requisições (uma por item)
return [
  { json: userMessage },
  { json: assistantMessage }
];
```

**Opções:**
- Batching: Habilitado
- Batch Size: 1
- Response → Always Output Data: `true`

---

### 🔹 NODE 5: Preservar Dados Após Salvar Memória (Code)

**Posição:** Após `💾 Salvar em Memória`, conectar ao `Tem Mídia do Acervo?`

**Configuração:**

```
Nome: 🔄 Preservar Dados Após Memória
Tipo: Code (JavaScript)
```

**Código:**
```javascript
// Preservar dados originais após salvar na memória
const originalData = $('Construir Resposta Final').first().json;
const memorySaveResult = $input.all();

console.log('✅ Mensagens salvas na memória:', memorySaveResult.length);

return {
  json: {
    ...originalData,
    memory_saved: true,
    memory_ids: memorySaveResult.map(r => r.json.id || r.json)
  }
};
```

---

## 🔗 Parte 3: Conectar os Nodes

### Fluxo Atual:
```
Query RAG → Preparar Prompt LLM
```

### Fluxo NOVO:
```
Query RAG 
  ↓
🧠 Buscar Histórico de Conversa (RPC)
  ↓
📝 Formatar Histórico para LLM
  ↓
Preparar Prompt LLM (MODIFICADO)
  ↓
... (resto do fluxo)
  ↓
Construir Resposta Final
  ↓
💾 Salvar em Memória (User + Assistant)
  ↓
🔄 Preservar Dados Após Memória
  ↓
Tem Mídia do Acervo?
```

---

## 🧪 Parte 4: Testar a Memória

### Teste 1: Primeira Mensagem
Envie via WhatsApp:
```
Olá! Meu nome é João
```

**Esperado:** Bot responde normalmente (sem histórico ainda)

### Teste 2: Segunda Mensagem
Envie:
```
Qual é o meu nome?
```

**Esperado:** Bot responde "João" (lembrou do histórico!)

### Teste 3: Contexto de Conversa
```
1ª msg: "Quero agendar uma consulta"
2ª msg: "Pode ser quinta-feira?"
3ª msg: "De manhã, por favor"
```

**Esperado:** Bot mantém contexto de que está agendando uma consulta

---

## 🔍 Verificar no Banco

Após os testes, verificar memória salva:

```sql
SELECT 
  message_role,
  LEFT(message_content, 50) as content,
  message_timestamp
FROM conversation_memory
WHERE client_id = 'estetica_bella_rede'
  AND conversation_id = 6
ORDER BY message_timestamp DESC
LIMIT 20;
```

---

## ⚠️ Notas Importantes

1. **Limite de Histórico:** Atualmente busca últimas 10 mensagens (p_limit=10). Ajuste se necessário.

2. **Performance:** A busca de histórico adiciona ~200-500ms ao tempo de resposta (aceitável).

3. **Limpeza:** Mensagens antigas são mantidas indefinidamente. Para limpar:
   ```sql
   -- Limpar mensagens com mais de 30 dias
   DELETE FROM conversation_memory 
   WHERE created_at < NOW() - INTERVAL '30 days';
   ```

4. **Storage:** Cada conversa armazena ~2 mensagens por interação (user + assistant).

5. **Custo de Tokens:** O histórico aumenta o número de tokens enviados ao OpenAI (~100-300 tokens por histórico).

---

## ✅ Checklist de Implementação

- [ ] Node 1: Buscar Histórico criado
- [ ] Node 2: Formatar Histórico criado
- [ ] Node 3: Preparar Prompt LLM modificado
- [ ] Node 4: Salvar em Memória criado
- [ ] Node 5: Preservar Dados criado
- [ ] Conexões atualizadas
- [ ] Workflow ativado
- [ ] Teste 1 executado (primeira mensagem)
- [ ] Teste 2 executado (segunda mensagem com memória)
- [ ] Teste 3 executado (contexto multi-turno)
- [ ] Verificação no banco realizada

---

**Pronto! Agora o bot tem memória de conversa! 🧠✨**

# 🔧 CORREÇÃO CRÍTICA: Salvar Mensagem do Usuário ANTES de Buscar Histórico

## ❌ Problema Atual:
```
🧠 Buscar Histórico → Bot responde → 💾 Salvar (user + assistant)
```
**Resultado:** Bot busca histórico ANTES da mensagem atual ser salva = não lembra!

---

## ✅ Solução:
```
💾 Salvar User ANTES → 🧠 Buscar Histórico → Bot responde → 💾 Salvar Assistant
```
**Resultado:** Bot busca histórico COM a mensagem atual = lembra! 🧠✨

---

## 📋 PASSO A PASSO:

### **PASSO 1: Adicionar Node "💾 Salvar Mensagem do Usuário"**

**Posição:** ANTES do "🧠 Buscar Histórico de Conversa (RPC)"

**Tipo:** HTTP Request

**Configuração:**
- **Nome:** `💾 Salvar Mensagem do Usuário`
- **Método:** `POST`
- **URL:** `https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/save_conversation_message`

**Headers** (mesmos do node Buscar Histórico):
```
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U

Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U

Content-Type: application/json
```

**Body** → JSON:
```json
{
  "p_client_id": "{{ $json.client_id }}",
  "p_conversation_id": {{ $json.conversation_id }},
  "p_message_role": "user",
  "p_message_content": "{{ $json.message_body }}",
  "p_contact_id": {{ $json.contact_id }},
  "p_agent_id": "{{ $json.agent_id }}",
  "p_channel": "{{ $json.channel }}",
  "p_has_attachments": {{ $json.has_attachments }},
  "p_attachments": {{ $json.attachments || '[]' }},
  "p_metadata": {}
}
```

**Options → Response:**
- ✅ **Always Output Data:** `true`
- **Response Format:** `Text` (retorna UUID)

**Options → Batching:**
- ❌ **DESABILITAR** (não precisa)

---

### **PASSO 2: Adicionar Node "🔄 Preservar Dados Originais"**

**Posição:** Logo APÓS o "💾 Salvar Mensagem do Usuário"

**Tipo:** Code (JavaScript)

**Código:**
```javascript
// Preservar dados originais após salvar mensagem do usuário
const originalData = $('Query RAG (Namespace Isolado)').first().json;
const userMessageId = $input.first().json.data; // UUID retornado

return {
  json: {
    ...originalData,
    user_message_saved_id: userMessageId,
    user_message_saved: true
  }
};
```

---

### **PASSO 3: Modificar Node "📦 Preparar Mensagens para Memória"**

**Ação:** EDITAR node existente

**Problema:** Atualmente salva user + assistant juntos

**Solução:** Salvar APENAS assistant (user já foi salvo!)

**Novo código:**
```javascript
// Preparar apenas mensagem do ASSISTANT para salvar (user já foi salvo antes!)
const originalData = $input.item.json;

const assistantMessage = {
  p_client_id: originalData.client_id,
  p_conversation_id: originalData.conversation_id,
  p_message_role: 'assistant',
  p_message_content: originalData.final_response,
  p_contact_id: originalData.contact_id || null,
  p_agent_id: originalData.agent_id || 'default',
  p_channel: originalData.channel || 'whatsapp',
  p_has_attachments: originalData.has_client_media || false,
  p_attachments: JSON.stringify(originalData.client_media_attachments || []),
  p_metadata: JSON.stringify({
    llm_model: originalData.llm_model || 'gpt-4o-mini',
    llm_provider: originalData.llm_provider || 'openai',
    tools_used: originalData.tools_enabled || []
  })
};

return {
  json: assistantMessage
};
```

---

### **PASSO 4: Modificar Node "💾 Salvar em Memória (User + Assistant)"**

**Ação:** RENOMEAR para `💾 Salvar Resposta do Assistant`

**Configuração:**
- **Options → Batching:** ❌ **DESABILITAR** (agora salva só 1 mensagem)
- Resto igual

---

### **PASSO 5: Adicionar Node "⚙️ Buscar Configuração de Memória"**

**Posição:** ANTES do "🧠 Buscar Histórico de Conversa (RPC)"

**Tipo:** Code (JavaScript)

**Código:** Copiar de `workflows/CODIGO-BUSCAR-CONFIG-MEMORIA.js`

**Função:** Busca configurações dinâmicas (memory_limit + memory_hours_back) da tabela memory_config

---

### **PASSO 6: Atualizar Node "🧠 Buscar Histórico" com Configurações Dinâmicas**

**Body atualizado (DINÂMICO!):**
```json
{
  "p_client_id": "{{ $json.client_id }}",
  "p_conversation_id": {{ $json.conversation_id }},
  "p_limit": {{ $json.memory_limit }},
  "p_hours_back": {{ $json.memory_hours_back }}
}
```

**Agora os valores vêm da tabela memory_config!** 🎯

---

### **PASSO 7: Verificar Novo Fluxo Completo**

```
Query RAG (Namespace Isolado)
  ↓
💾 Salvar Mensagem do Usuário (NOVO!)
  ↓
🔄 Preservar Dados Originais (NOVO!)
  ↓
⚙️ Buscar Configuração de Memória (NOVO! - Dinâmico)
  ↓
🧠 Buscar Histórico de Conversa (RPC) [agora com config dinâmica]
  ↓
📝 Formatar Histórico para LLM
  ↓
Preparar Prompt LLM [MODIFICADO]
  ↓
LLM (GPT-4o-mini + Tools)
  ↓
... (resto do fluxo) ...
  ↓
Construir Resposta Final
  ↓
📦 Preparar Mensagens para Memória [MODIFICADO - só assistant]
  ↓
💾 Salvar Resposta do Assistant [RENOMEADO]
  ↓
🔄 Preservar Dados Após Memória
  ↓
Tem Mídia do Acervo?
```

---

## 🧪 TESTE FINAL:

1. **Mensagem 1:** "Olá! Meu nome é João Silva e sou de São Paulo"
   - Bot: Responde normalmente
   - Salva: user (antes) + assistant (depois)

2. **Mensagem 2:** "Qual é o meu nome e de onde eu sou?"
   - Bot busca histórico (encontra msg 1!)
   - Bot: **"Seu nome é João Silva e você é de São Paulo"** ✅

---

## ✅ Checklist de Implementação:

### **Banco de Dados:**
- [ ] Executar migration 021 (tabela memory_config)
- [ ] Configurar memória para cada cliente (ver queries/manage_memory_config.sql)

### **Workflow n8n:**
- [ ] Adicionar node "💾 Salvar Mensagem do Usuário" ANTES do Buscar Histórico
- [ ] Adicionar node "🔄 Preservar Dados Originais" logo após
- [ ] Adicionar node "⚙️ Buscar Configuração de Memória" (código em CODIGO-BUSCAR-CONFIG-MEMORIA.js)
- [ ] Atualizar Body do "🧠 Buscar Histórico" com `{{ $json.memory_limit }}` e `{{ $json.memory_hours_back }}`
- [ ] Modificar "📦 Preparar Mensagens" para salvar só assistant
- [ ] Renomear "💾 Salvar em Memória" para "💾 Salvar Resposta do Assistant"
- [ ] Desabilitar Batching no node Salvar Assistant
- [ ] Verificar todas as conexões
- [ ] Salvar workflow

### **Teste:**
- [ ] Testar com configuração padrão (50 msgs, 24h)
- [ ] Alterar configuração via SQL
- [ ] Testar novamente para validar mudança dinâmica
- [ ] SUCESSO! 🎯

---

**Pronto! Agora o bot vai lembrar de TUDO na primeira resposta!** 🧠✨

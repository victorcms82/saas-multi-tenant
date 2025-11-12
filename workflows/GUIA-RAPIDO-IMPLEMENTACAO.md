# 🚀 Guia Rápido: Adicionar Memória ao Workflow

## 📦 Arquivos Gerados:
1. ✅ `NODES-MEMORIA-PARA-IMPORTAR.json` - 5 nodes prontos
2. ✅ `CODIGO-ATUALIZADO-PREPARAR-PROMPT-LLM.js` - Código atualizado

---

## 🎯 Passo a Passo Simplificado

### **PASSO 1: Abrir Workflow no n8n**
```
https://n8n.evolutedigital.com.br
→ Abrir workflow: "[PLATAFORMA SaaS] WF 0: Gestor (Chatwoot) [DINÂMICO] Versão Final"
```

---

### **PASSO 2: Adicionar Node "🧠 Buscar Histórico"**

**Posição:** Entre `Query RAG (Namespace Isolado)` → `Preparar Prompt LLM`

1. Clicar no **+** entre os dois nodes
2. Buscar: **HTTP Request**
3. Configurar:
   - Nome: `🧠 Buscar Histórico de Conversa (RPC)`
   - Método: `POST`
   - URL: `https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/get_conversation_history`
   
4. **Headers** (adicionar 3):
   ```
   apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U
   
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U
   
   Content-Type: application/json
   ```

5. **Body** → JSON:
   ```json
   {
     "p_client_id": "{{ $json.client_id }}",
     "p_conversation_id": {{ $json.conversation_id }},
     "p_limit": 10
   }
   ```

6. **Options** → Response:
   - ✅ **Always Output Data: `true`** ⚠️ IMPORTANTE para funcionar quando não há histórico

7. **Credenciais:** Selecionar `Supabase API`

---

### **PASSO 3: Adicionar Node "📝 Formatar Histórico"**

**Posição:** Após `🧠 Buscar Histórico`

1. Clicar no **+** 
2. Buscar: **Code**
3. Configurar:
   - Nome: `📝 Formatar Histórico para LLM`
   - Copiar código do arquivo: **`workflows/CODIGO-FORMATAR-HISTORICO.js`** (vou criar abaixo)

---

### **PASSO 4: Modificar Node "Preparar Prompt LLM"**

**Ação:** EDITAR node existente

1. Clicar no node `Preparar Prompt LLM`
2. **SUBSTITUIR** todo o código pelo conteúdo de:
   - **`workflows/CODIGO-ATUALIZADO-PREPARAR-PROMPT-LLM.js`**

---

### **PASSO 5: Adicionar Node "📦 Preparar Mensagens"**

**Posição:** Após `Construir Resposta Final`, antes de `Tem Mídia do Acervo?`

1. Desconectar: `Construir Resposta Final` → `Tem Mídia do Acervo?`
2. Adicionar node **Code**:
   - Nome: `📦 Preparar Mensagens para Memória`
   - Copiar código do arquivo: **`workflows/CODIGO-PREPARAR-MENSAGENS.js`** (vou criar abaixo)

---

### **PASSO 6: Adicionar Node "💾 Salvar em Memória"**

**Posição:** Após `📦 Preparar Mensagens`

1. Adicionar **HTTP Request**:
   - Nome: `💾 Salvar em Memória (User + Assistant)`
   - Método: `POST`
   - URL: `https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/save_conversation_message`

2. **Headers** (mesmos do Passo 2)

3. **Body** → JSON → Expression:
   ```
   {{ $json }}
   ```

4. **Options** → Batching:
   - ✅ Enable Batching
   - Batch Size: `1`

5. **Options** → Response:
   - ✅ Always Output Data: `true`
   - **Response Format: `Text`** ⚠️ IMPORTANTE: RPC retorna UUID como texto, não JSON

---

### **PASSO 7: Adicionar Node "🔄 Preservar Dados"**

**Posição:** Após `💾 Salvar em Memória`

1. Adicionar **Code**:
   - Nome: `🔄 Preservar Dados Após Memória`
   - Copiar código do arquivo: **`workflows/CODIGO-PRESERVAR-DADOS.js`** (vou criar abaixo)

2. **Conectar** saída deste node para → `Tem Mídia do Acervo?`

---

### **PASSO 8: Verificar Conexões Finais**

Fluxo completo deve ser:

```
Query RAG (Namespace Isolado)
  ↓
🧠 Buscar Histórico de Conversa (RPC)
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
📦 Preparar Mensagens para Memória
  ↓
💾 Salvar em Memória (User + Assistant)
  ↓
🔄 Preservar Dados Após Memória
  ↓
Tem Mídia do Acervo?
```

---

### **PASSO 9: Salvar e Ativar**

1. Clicar em **Save** (topo direito)
2. Verificar que workflow está **ACTIVE** (toggle verde)

---

### **PASSO 10: Testar! 🧪**

**Teste 1 - Primeira mensagem:**
```
Enviar: "Olá! Meu nome é João Silva"
Resultado: Bot responde normalmente
```

**Teste 2 - Segunda mensagem (CRÍTICO):**
```
Enviar: "Qual é o meu nome completo?"
Resultado esperado: "Seu nome é João Silva" ✅
```

Se bot lembrar do nome = **SUCESSO!** 🎉

---

## 📂 Arquivos de Código

Vou criar os 3 arquivos JavaScript que você precisa:

1. `CODIGO-FORMATAR-HISTORICO.js`
2. `CODIGO-PREPARAR-MENSAGENS.js`
3. `CODIGO-PRESERVAR-DADOS.js`

---

## 🆘 Se Der Erro

### Erro: "Cannot read property 'client_id'"
- Verificar se conexões estão corretas
- Node anterior deve passar dados com client_id

### Erro: "PGRST203 - Could not choose the best candidate function"
**Problema:** Existe função duplicada no banco
**Solução executada:** ✅ Função antiga removida
Se o erro persistir, executar:
```sql
DROP FUNCTION IF EXISTS get_conversation_history(VARCHAR, VARCHAR, INTEGER);
```

### Erro: "Response body is not valid JSON"
**Problema:** Node "💾 Salvar em Memória" esperando JSON mas RPC retorna texto (UUID)
**Solução:** 
- Options → Response → **Response Format: `Text`** (não JSON)
- ✅ Corrigido no guia

### Erro: "Function get_conversation_history does not exist"
- Migration não foi executada
- Executar: `psql -f database/migrations/019_create_conversation_memory.sql`

### Bot não lembra contexto
- Verificar no banco: `SELECT * FROM conversation_memory WHERE client_id = 'estetica_bella_rede'`
- Se vazio = mensagens não estão sendo salvas
- Verificar node "💾 Salvar em Memória"

---

## ✅ Checklist Final

- [ ] 5 nodes adicionados
- [ ] Node "Preparar Prompt LLM" modificado
- [ ] Conexões verificadas
- [ ] Workflow salvo e ativo
- [ ] Teste 1 executado
- [ ] Teste 2 executado
- [ ] Bot lembra contexto ✅

---

**Pronto! Workflow com memória implementado! 🧠✨**

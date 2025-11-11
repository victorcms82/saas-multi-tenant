# 📦 NODES PARA ADICIONAR NO N8N

## ✅ RPC VALIDADO - FUNCIONANDO!

Teste bem-sucedido:
- Mensagem: "quero ver a clínica"
- Retornou: Recepção do Consultório (consultorio-recepcao.jpg)
- file_url acessível

---

## 🔧 PASSO A PASSO NO N8N

### 1️⃣ ADICIONAR NODE: Buscar Mídia Triggers (RPC)

1. Clicar entre "Filtrar Apenas Incoming" e "Construir Contexto Completo"
2. Adicionar node: **HTTP Request**
3. Configurar:

**Name:** `Buscar Mídia Triggers (RPC)`

**Parameters:**
- **Method:** `POST`
- **URL:** `https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/check_media_triggers`
- **Authentication:** Generic Credential Type → HTTP Custom Auth
  - **Credential:** Selecionar "Supabase API" (já existe)

**Send Query Parameters:** OFF

**Send Headers:** ON
- Header 1:
  - Name: `apikey`
  - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U`
- Header 2:
  - Name: `Authorization`
  - Value: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U`
- Header 3:
  - Name: `Content-Type`
  - Value: `application/json`
- Header 4:
  - Name: `Prefer`
  - Value: `return=representation`

**Send Body:** ON
- **Body Content Type:** JSON
- **Specify Body:** Using JSON
- **JSON:**
```json
{
  "p_client_id": "{{ $json.client_id }}",
  "p_agent_id": "{{ $json.agent_id }}",
  "p_message": "{{ $json.message_body }}"
}
```

**Position:** Colocar paralelo ao "Buscar Dados do Agente (HTTP)" (um pouco abaixo)

---

### 2️⃣ ADICIONAR NODE: Merge (Agente + Mídia)

1. Adicionar entre RPC e "Construir Contexto Completo"
2. Node type: **Merge**
3. Configurar:

**Name:** `Merge: Agente + Mídia`

**Parameters:**
- **Mode:** `Combine`
- **Combination Mode:** `Merge By Position`

**Inputs:** Este node terá 2 inputs (n8n detecta automaticamente)

---

### 3️⃣ RECONECTAR FLUXO

**REMOVER CONEXÃO:**
- ❌ "Buscar Dados do Agente (HTTP)" → "Construir Contexto Completo"

**ADICIONAR CONEXÕES:**

1. **Filtrar Apenas Incoming → Buscar Mídia Triggers (RPC)**
   - Arrastar do output de "Filtrar Apenas Incoming"
   - Conectar ao input do novo node RPC

2. **Buscar Dados do Agente → Merge (Input 1)**
   - Já está conectado

3. **Buscar Mídia Triggers → Merge (Input 2)**
   - Arrastar do output do RPC
   - Conectar ao segundo input do Merge

4. **Merge → Construir Contexto Completo**
   - Arrastar do output do Merge
   - Conectar ao input de "Construir Contexto Completo"

---

### 4️⃣ TESTAR

1. **Salvar workflow** (Ctrl+S)
2. **Clicar em "Execute Workflow"** (com pinData existente)
3. **Verificar node "Construir Contexto Completo":**
   - Deve ter `item.rule_id`
   - Deve ter `item.media_id`
   - Deve ter `item.file_url`
   - `client_media_attachments` deve ter 1 item

**Logs esperados:**
```
mediaRules.length: 1
client_media_attachments.length: 1
```

---

## 🎯 RESULTADO ESPERADO

Após adicionar os 2 nodes:

✅ RPC busca mídia do banco  
✅ Merge combina Agente + Mídia  
✅ "Construir Contexto Completo" recebe tudo  
✅ `client_media_attachments` populado  
✅ Bot detecta que tem mídia para enviar  

**MAS:** Bot ainda não envia (só detecta)

**PRÓXIMO PASSO:** Adicionar 10 nodes de envio de mídia

---

## 📸 VISUAL DO FLUXO (APÓS CORREÇÃO)

```
Filtrar Apenas Incoming
  ├─→ Buscar Dados do Agente (HTTP)
  │     ↓
  │   Merge: Agente + Mídia (Input 1)
  │     ↓
  └─→ Buscar Mídia Triggers (RPC)  ← NOVO!
        ↓
      Merge: Agente + Mídia (Input 2)
        ↓
      Construir Contexto Completo
```

---

**IMPORTANTE:** Use `Ctrl+Z` se algo der errado! O n8n tem undo.

**DÚVIDAS?** Grite "HELP!" que eu ajudo! 😄

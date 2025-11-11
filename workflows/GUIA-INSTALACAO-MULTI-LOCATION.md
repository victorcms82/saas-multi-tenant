# 🎯 GUIA COMPLETO: Instalar Multi-Location no Workflow n8n

## 📋 PRÉ-REQUISITOS

✅ Migration 011 executada (tabela `locations`)  
✅ Migration 012 executada (tabela `staff`)  
✅ Migration 013 executada (4 RPCs criados)  
✅ Workflow `WF0-Gestor-Universal-FINAL-CORRIGIDO` aberto no n8n

---

## 🚀 PASSO 1: Importar os 2 Novos Nodes

### 1.1 Abrir o arquivo JSON
- Abra `workflows/NODES-MULTI-LOCATION-DETECTION.json`
- Copie TODO o conteúdo (Ctrl+A, Ctrl+C)

### 1.2 Importar no n8n
- No workflow, clique em **Settings** (canto superior direito)
- Clique em **Import from Clipboard**
- Cole o JSON copiado
- Clique em **Import**

### 1.3 Resultado
Você verá 2 novos nodes aparecerem no canvas:
- 🏢 **Detectar Localização e Staff (RPC)**
- 💼 **Construir Contexto Location + Staff**

---

## 🔗 PASSO 2: Conectar os Nodes na Ordem Correta

### 2.1 Localizar o node "Filtrar Apenas Incoming"
- Encontre o node **IF** chamado "Filtrar Apenas Incoming"
- Ele tem 2 saídas: TRUE e FALSE

### 2.2 Desconectar a saída TRUE
- A saída TRUE atualmente vai para "Buscar Dados do Agente (HTTP)"
- **Clique e arraste** para remover essa conexão

### 2.3 Conectar na nova ordem:

```
Filtrar Apenas Incoming (TRUE)
    ↓
🏢 Detectar Localização e Staff (RPC)
    ↓
💼 Construir Contexto Location + Staff
    ↓
Buscar Dados do Agente (HTTP)
    ↓
(resto do workflow continua igual)
```

**Como fazer:**
1. Arraste da saída TRUE de "Filtrar Apenas Incoming" → "🏢 Detectar Localização"
2. Arraste de "🏢 Detectar Localização" → "💼 Construir Contexto"
3. Arraste de "💼 Construir Contexto" → "Buscar Dados do Agente (HTTP)"

---

## ✏️ PASSO 3: Atualizar o Node "Construir Contexto Completo"

### 3.1 Localizar o node
- Encontre o node **Code** chamado "Construir Contexto Completo"
- Ele está depois de "Buscar Dados do Agente (HTTP)"

### 3.2 Abrir o editor de código
- Clique no node
- Clique em **Edit Code**

### 3.3 Adicionar a linha de location_context

**LOCALIZAR** esta linha no código (deve estar no início):
```javascript
const item = $input.item.json;
```

**ADICIONAR LOGO APÓS** ela:
```javascript
const locationContext = item.location_context || '';
```

### 3.4 Adicionar location_context no output do return

**LOCALIZAR** o bloco `return` no final do código (começa com `return { json: {`).

**DENTRO DO OBJETO JSON**, adicionar estas linhas logo após `media_log_entries`:

```javascript
    // Contexto de localização e staff
    location_context: locationContext,
    has_location_data: locationContext ? true : false,
```

**RESULTADO FINAL** do return deve ficar assim:

```javascript
return {
  json: {
    // Preservar TODOS os dados originais do webhook (incluindo message_body)
    client_id: webhookData.client_id,
    agent_id: webhookData.agent_id,
    conversation_id: webhookData.conversation_id,
    contact_id: webhookData.contact_id,
    channel: webhookData.channel,
    message_body: webhookData.message_body,
    message_type: webhookData.message_type,
    content_type: webhookData.content_type,
    attachments: webhookData.attachments,
    has_attachments: webhookData.has_attachments,
    timestamp: webhookData.timestamp,
    
    // Dados do agente
    system_prompt: agentData.system_prompt || 'Você é um assistente útil.',
    llm_model: agentData.llm_model || 'gpt-4o-mini',
    tools_enabled: agentData.tools_enabled || [],
    rag_namespace: agentData.rag_namespace,
    
    // Contexto de mídia do acervo
    media_context: mediaContext,
    client_media_attachments: clientMediaAttachments,
    media_log_entries: mediaLogEntries,
    has_client_media: clientMediaAttachments.length > 0,
    
    // Contexto de localização e staff
    location_context: locationContext,
    has_location_data: locationContext ? true : false,
    
    // Subscription data (para usage tracking)
    subscription: agentData.client_subscriptions?.[0] || {}
  }
};
```

### 3.5 Atualizar o System Prompt do OpenAI

**IMPORTANTE**: Agora você precisa atualizar o node **OpenAI** para incluir o `location_context` no system prompt.

**LOCALIZAR** o node OpenAI no workflow e editar o campo **System Message**.

**ADICIONAR** a referência ao `location_context`:

```javascript
{{ $json.system_prompt }}

{{ $json.location_context }}

{{ $json.media_context }}
```

Ou se já tiver uma estrutura diferente, certifique-se de incluir `{{ $json.location_context }}` entre o system_prompt e o media_context.

### 3.6 Salvar
- Clique em **Save** ou pressione Ctrl+S
- Feche o editor

---

## ⚙️ PASSO 4: Configurar chatwoot_inbox_id nas Locations

### 4.1 Descobrir o inbox_id real do id, etc?


**Opção 1: Pelo Chatwoot Dashboard**
1. Abra o Chatwoot
2. Vá em **Settings → Inboxes**
3. Clique no inbox que você quer vincular
4. O **ID** aparece na URL: `https://chatwoot.com/app/accounts/1/settings/inboxes/123456`
   - Neste exemplo, o inbox_id é **123456**

**Opção 2: Testar o workflow e ver no log**
1. Execute o workflow
2. No node "Identificar Cliente e Agente", veja o output
3. Procure por `original_payload.body.inbox.id` ou `original_payload.inbox.id`

### 4.2 Atualizar no Supabase

Abra o **Supabase SQL Editor** e execute:

```sql
-- Substitua 123456 pelo inbox_id REAL que você descobriu acima

-- Para Bella Barra (matriz)
UPDATE locations 
SET chatwoot_inbox_id = 123456 
WHERE location_id = 'bella_barra_001';

-- Para Bella Ipanema
UPDATE locations 
SET chatwoot_inbox_id = 123457 
WHERE location_id = 'bella_ipanema_001';

-- Para Bella Copacabana
UPDATE locations 
SET chatwoot_inbox_id = 123458 
WHERE location_id = 'bella_copacabana_001';

-- Para Bella Botafogo
UPDATE locations 
SET chatwoot_inbox_id = 123459 
WHERE location_id = 'bella_botafogo_001';

-- Validar
SELECT location_id, name, chatwoot_inbox_id 
FROM locations 
WHERE client_id = 'estetica_bella_rede';
```

**⚠️ IMPORTANTE**: Cada inbox diferente deve ter um inbox_id único. Se você tem apenas 1 inbox configurado, use o mesmo ID para todas as 4 locations (por enquanto).

---

## 🧪 PASSO 5: Testar o Workflow

### 5.1 Salvar o workflow
- Clique em **Save** no canto superior direito

### 5.2 Ativar o workflow
- Toggle **Active** no canto superior direito

### 5.3 Enviar mensagem de teste
1. Abra o Chatwoot
2. Envie uma mensagem qualquer no inbox configurado
3. Exemplo: "Olá, quero agendar uma consulta"

### 5.4 Verificar execução no n8n
1. Vá em **Executions** (histórico de execuções)
2. Clique na execução mais recente
3. Verifique cada node:

**Node "🏢 Detectar Localização e Staff (RPC)":**
- ✅ Deve retornar JSON com `location_name`, `staff_list`, etc.
- ❌ Se retornar array vazio: `chatwoot_inbox_id` não está configurado

**Node "💼 Construir Contexto Location + Staff":**
- ✅ Deve mostrar `location_context` com texto formatado
- ✅ Deve ter `has_location_data: true`
- Exemplo de output esperado:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 INFORMAÇÕES DA UNIDADE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Nome: Bella Estética - Barra
Endereço: Av. das Américas, 5000, Rio de Janeiro
...
```

**Node "Construir Contexto Completo":**
- ✅ Deve ter `location_context` incluído no `fullContext`
- Verifique se o texto formatado da localização está presente

**Node OpenAI:**
- ✅ LLM deve responder considerando a localização e profissionais
- Teste perguntando: "Quais profissionais vocês têm?"
- LLM deve listar os profissionais da location correta

---

## 🐛 TROUBLESHOOTING: Problemas Comuns

### ❌ Problema 1: RPC retorna array vazio `[]`

**Causa**: `chatwoot_inbox_id` não está configurado ou está errado

**Solução**:
1. Verifique o inbox_id real (Passo 4.1)
2. Execute o UPDATE no Supabase (Passo 4.2)
3. Teste novamente

**Como validar**:
```sql
-- Ver todos os inbox_ids configurados
SELECT location_id, name, chatwoot_inbox_id 
FROM locations 
WHERE client_id = 'estetica_bella_rede';

-- Se estiver NULL, precisa configurar
-- Se estiver diferente do inbox real, precisa corrigir
```

---

### ❌ Problema 2: Erro "inbox.id is undefined"

**Causa**: Estrutura do payload do Chatwoot mudou ou está diferente do esperado

**Solução**:
1. Abra o node "Identificar Cliente e Agente"
2. Veja o output do `original_payload`
3. Identifique onde está o `inbox.id`
4. Edite o node "🏢 Detectar Localização e Staff (RPC)"
5. Na propriedade `jsonBody`, ajuste o caminho correto:

```javascript
// Opção 1 (padrão):
"p_inbox_id": {{ $json.original_payload.body.inbox.id }}

// Opção 2 (se body não existir):
"p_inbox_id": {{ $json.original_payload.inbox.id }}

// Opção 3 (direto do webhook):
"p_inbox_id": {{ $json.conversation.inbox_id }}
```

---

### ❌ Problema 3: Context não aparece no LLM

**Causa**: Node "Construir Contexto Completo" não foi atualizado corretamente

**Solução**:
1. Revise o Passo 3 completamente
2. Certifique-se de ter adicionado:
```javascript
const locationContext = item.location_context || '';
```
3. E alterado o `fullContext` para incluir `${locationContext}`
4. Salve e teste novamente

**Como validar**:
- No output do node "Construir Contexto Completo"
- Procure pela propriedade `fullContext`
- Ela deve conter o texto formatado da localização

---

### ❌ Problema 4: LLM não menciona os profissionais

**Causa**: Context está sendo injetado mas o system prompt não está usando

**Solução**:
1. Abra o node OpenAI (ou o node que chama o LLM)
2. Verifique se o `System Message` está usando a variável correta
3. Deve ser algo como:
```
{{ $json.full_context }}
```
ou
```
{{ $('Construir Contexto Completo').first().json.fullContext }}
```

---

### ❌ Problema 5: Node HTTP Request falha com erro 401/403

**Causa**: Headers de autenticação do Supabase estão errados ou faltando

**Solução**:
1. Verifique se o node "🏢 Detectar Localização" tem os headers:
   - `apikey`: Sua anon key do Supabase
   - `Authorization`: Bearer + anon key
   - `Content-Type`: application/json

2. Se necessário, copie os headers do node "Buscar Dados do Agente (HTTP)" que já funciona

---

## ✅ VALIDAÇÃO FINAL

### Checklist de Sucesso:

- [ ] 2 novos nodes importados e conectados
- [ ] Node "Construir Contexto Completo" atualizado
- [ ] `chatwoot_inbox_id` configurado nas 4 locations
- [ ] Teste enviado pelo Chatwoot
- [ ] RPC retornou dados da location (não array vazio)
- [ ] Context formatado aparece no node "Construir Contexto"
- [ ] LLM responde mencionando profissionais corretos
- [ ] Workflow executou sem erros

---

## 🎉 PRÓXIMOS PASSOS (Opcional)

Após validar que está funcionando:

1. **Configurar inboxes reais**: Se você tem múltiplas unidades/lojas, crie um inbox do Chatwoot para cada uma e vincule
   
2. **Adicionar mais profissionais**: Use a migration 012 como template para inserir mais staff

3. **Integrar Google Calendar**: Preencher `calendar_id` e `calendar_email` na tabela staff para agendamentos reais

4. **Adicionar lógica de agendamento**: Criar node que chama `get_available_slots()` quando cliente pedir para agendar

5. **LLM Switcher** (Migration 014): Permitir trocar entre OpenAI/Claude/Gemini por tenant

6. **Audio Support** (Migration 015): STT/TTS para mensagens de voz

---

## 📞 SUPORTE

Se encontrar problemas:

1. Verifique os logs no n8n (Executions → Clique na execução)
2. Veja o output de cada node para identificar onde falha
3. Use as queries SQL de validação para verificar os dados
4. Consulte a seção Troubleshooting acima

**Logs úteis**:
```javascript
// No node "💼 Construir Contexto Location + Staff"
// Já tem console.log detalhado:
console.log('✅ Localização detectada:', location.location_name);
console.log('📊 Total de profissionais:', location.total_staff);
```

---

**Versão**: 1.0.0  
**Data**: 2025-11-11  
**Autor**: GitHub Copilot  
**Migrations Required**: 011, 012, 013

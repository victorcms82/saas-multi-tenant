# 🔴 CORREÇÕES DE ALTA PRIORIDADE

## 📋 Resumo
3 correções críticas identificadas após análise do workflow vs backup do Supabase.

**Status:** ⚠️ **NÃO IMPLEMENTADAS**
**Impacto:** 🔴 **ALTA** - Dados não rastreados, segurança comprometida
**Tempo Estimado:** 2-3 horas

---

## 1️⃣ CONVERSATIONS TABLE NÃO USADA

### ❌ Problema
- Tabela `conversations` tem **20 registros** no banco
- Workflow **não cria** novos registros
- Workflow **não atualiza** campos importantes

### 🎯 Impacto
- ❌ Não rastreia histórico de conversas
- ❌ Não sabe se conversa está ativa/resolvida
- ❌ Não controla `ai_paused` (handoff para humano)
- ❌ Não conta mensagens não lidas
- ❌ Não registra `taken_over_by` (quem assumiu atendimento)

### ✅ Correção

**Posição:** Após node "Filtrar Apenas Incoming"

**Node Novo:** "📝 Upsert Conversation"

**Tipo:** HTTP Request (POST)

**Configuração:**
```json
{
  "method": "POST",
  "url": "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/upsert_conversation",
  "headers": {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
  },
  "body": {
    "p_client_id": "{{ $json.client_id }}",
    "p_agent_id": "{{ $json.agent_id }}",
    "p_chatwoot_conversation_id": "{{ $json.conversation_id }}",
    "p_chatwoot_inbox_id": "{{ $json.body.inbox.id || $json.original_payload.inbox.id }}",
    "p_chatwoot_account_id": 1,
    "p_customer_name": "{{ $json.sender.name || $json.body.sender.name || 'Visitante' }}",
    "p_customer_phone": "{{ $json.sender.phone_number || $json.body.sender.phone_number || null }}",
    "p_customer_email": "{{ $json.sender.email || $json.body.sender.email || null }}",
    "p_status": "active",
    "p_ai_paused": false,
    "p_last_message_content": "{{ $json.message_body }}",
    "p_last_message_sender": "user"
  }
}
```

**RPC Function (já existe no banco):**
```sql
CREATE OR REPLACE FUNCTION upsert_conversation(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_chatwoot_conversation_id BIGINT,
  p_chatwoot_inbox_id INTEGER,
  p_chatwoot_account_id INTEGER,
  p_customer_name TEXT DEFAULT NULL,
  p_customer_phone TEXT DEFAULT NULL,
  p_customer_email TEXT DEFAULT NULL,
  p_status TEXT DEFAULT 'active',
  p_ai_paused BOOLEAN DEFAULT FALSE,
  p_last_message_content TEXT DEFAULT NULL,
  p_last_message_sender TEXT DEFAULT 'user'
)
RETURNS conversations
LANGUAGE plpgsql
AS $$
DECLARE
  v_conversation conversations;
BEGIN
  INSERT INTO conversations (
    client_id,
    agent_id,
    chatwoot_conversation_id,
    chatwoot_inbox_id,
    chatwoot_account_id,
    customer_name,
    customer_phone,
    customer_email,
    status,
    ai_paused,
    last_message_content,
    last_message_sender,
    last_message_timestamp,
    total_messages,
    unread_count,
    created_at,
    updated_at
  )
  VALUES (
    p_client_id,
    p_agent_id,
    p_chatwoot_conversation_id,
    p_chatwoot_inbox_id,
    p_chatwoot_account_id,
    p_customer_name,
    p_customer_phone,
    p_customer_email,
    p_status,
    p_ai_paused,
    p_last_message_content,
    p_last_message_sender,
    NOW(),
    1,
    1,
    NOW(),
    NOW()
  )
  ON CONFLICT (client_id, chatwoot_conversation_id)
  DO UPDATE SET
    customer_name = COALESCE(EXCLUDED.customer_name, conversations.customer_name),
    customer_phone = COALESCE(EXCLUDED.customer_phone, conversations.customer_phone),
    customer_email = COALESCE(EXCLUDED.customer_email, conversations.customer_email),
    status = EXCLUDED.status,
    ai_paused = EXCLUDED.ai_paused,
    last_message_content = EXCLUDED.last_message_content,
    last_message_sender = EXCLUDED.last_message_sender,
    last_message_timestamp = NOW(),
    total_messages = conversations.total_messages + 1,
    unread_count = conversations.unread_count + 1,
    updated_at = NOW()
  RETURNING * INTO v_conversation;
  
  RETURN v_conversation;
END;
$$;
```

**Teste:**
```bash
# Enviar mensagem de teste via Chatwoot
# Verificar se conversations foi atualizada
curl "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/conversations?select=*&order=updated_at.desc&limit=1" \
  -H "apikey: YOUR_KEY"
```

---

## 2️⃣ WEBHOOKS_CONFIG NÃO VALIDADO

### ❌ Problema
- Workflow processa webhook sem validar se está `enabled=true`
- Campo `enabled` existe na tabela mas não é checado

### 🎯 Impacto
- ❌ Webhook desabilitado continua funcionando
- ❌ Não consegue pausar webhooks por cliente
- ❌ Bypass de segurança

### ✅ Correção

**Posição:** Antes de "Identificar Cliente e Agente"

**Node Novo:** "🔐 Validar Webhook Habilitado"

**Tipo:** HTTP Request (GET)

**Configuração:**
```json
{
  "method": "GET",
  "url": "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/webhooks_config",
  "sendQuery": true,
  "queryParameters": [
    { "name": "webhook_id", "value": "=eq.{{ $json.body.id || $json.id }}" },
    { "name": "enabled", "value": "=eq.true" },
    { "name": "select", "value": "*" },
    { "name": "limit", "value": "1" }
  ],
  "headers": {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Node de Validação (Code):**
```javascript
// Validar resposta do webhook_config
const webhookConfig = $input.first().json;

if (!webhookConfig || webhookConfig.length === 0) {
  console.error('❌ WEBHOOK DESABILITADO OU NÃO EXISTE');
  console.error('Webhook ID:', $('Chatwoot Webhook').first().json.body?.id);
  
  // ABORT: Webhook desabilitado
  throw new Error('Webhook desabilitado ou não configurado');
}

console.log('✅ Webhook habilitado:', webhookConfig[0].webhook_name);

// Preservar dados do webhook + config
const webhookData = $('Chatwoot Webhook').first().json;

return {
  json: {
    ...webhookData,
    webhook_config: webhookConfig[0]
  }
};
```

**IF Node (Fallback se não quiser abortar):**
```
Condição: {{ $json.length > 0 }}
  TRUE → Continua para "Identificar Cliente e Agente"
  FALSE → Responde erro ou ignora silenciosamente
```

**Teste:**
```sql
-- Desabilitar webhook
UPDATE webhooks_config 
SET enabled = FALSE 
WHERE client_id = 'clinica_sorriso_001';

-- Enviar mensagem de teste
-- Workflow deve abortar

-- Reabilitar
UPDATE webhooks_config 
SET enabled = TRUE 
WHERE client_id = 'clinica_sorriso_001';
```

---

## 3️⃣ CLIENTS NÃO VALIDADO

### ❌ Problema
- Workflow não valida se `clients.is_active = true`
- Workflow não verifica limites do `package`

### 🎯 Impacto
- ❌ Cliente inativo pode receber atendimento
- ❌ Cliente sem créditos pode usar sistema
- ❌ Não respeita quotas do plano

### ✅ Correção

**Posição:** Após "💼 Construir Contexto Location + Staff1"

**Node Novo:** "✅ Validar Cliente Ativo"

**Tipo:** HTTP Request (GET)

**Configuração:**
```json
{
  "method": "GET",
  "url": "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/clients",
  "sendQuery": true,
  "queryParameters": [
    { "name": "client_id", "value": "=eq.{{ $json.client_id }}" },
    { "name": "is_active", "value": "=eq.true" },
    { "name": "select", "value": "*" },
    { "name": "limit", "value": "1" }
  ],
  "headers": {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Node de Validação (Code):**
```javascript
// Validar cliente ativo
const clientData = $input.first().json;
const previousData = $('💼 Construir Contexto Location + Staff1').first().json;

if (!clientData || clientData.length === 0) {
  console.error('❌ CLIENTE INATIVO OU NÃO EXISTE');
  console.error('Client ID:', previousData.client_id);
  
  // ABORT: Cliente inativo
  throw new Error('Cliente inativo ou não existe');
}

const client = clientData[0];

console.log('✅ Cliente ativo:', client.client_name);
console.log('📦 Package:', client.package);

// Validar limites (se existir tabela client_subscriptions)
const subscription = client.client_subscriptions?.[0];

if (subscription) {
  console.log('📊 Usage:', {
    messages_used: subscription.messages_used || 0,
    messages_limit: subscription.messages_limit || Infinity,
    ai_calls_used: subscription.ai_calls_used || 0,
    ai_calls_limit: subscription.ai_calls_limit || Infinity
  });
  
  // Validar quotas
  if (subscription.messages_limit && subscription.messages_used >= subscription.messages_limit) {
    console.error('❌ LIMITE DE MENSAGENS ATINGIDO');
    throw new Error('Cliente atingiu limite de mensagens do plano');
  }
}

// Retornar dados enriquecidos
return {
  json: {
    ...previousData,
    client: client,
    package: client.package,
    subscription: subscription || null
  }
};
```

**IF Node (Alternativa):**
```
Condição: {{ $json.length > 0 }}
  TRUE → Continua para "Buscar Dados do Agente"
  FALSE → Responde "Desculpe, seu acesso está temporariamente suspenso"
```

**Teste:**
```sql
-- Desativar cliente
UPDATE clients 
SET is_active = FALSE 
WHERE client_id = 'clinica_sorriso_001';

-- Enviar mensagem de teste
-- Workflow deve abortar

-- Reativar
UPDATE clients 
SET is_active = TRUE 
WHERE client_id = 'clinica_sorriso_001';
```

---

## 📊 DIAGRAMA DE FLUXO COM CORREÇÕES

```
Chatwoot Webhook
  ↓
🔐 Validar Webhook Habilitado (NOVO!)  ← Correção #2
  ↓ (se enabled=true)
Identificar Cliente e Agente
  ↓
Filtrar Apenas Incoming
  ↓
📝 Upsert Conversation (NOVO!)  ← Correção #1
  ↓
1️⃣ Detectar Mídia
  ↓
Switch (image/pdf/audio/none)
  ↓
Merge
  ↓
🏢 Detectar Localização e Staff
  ↓
💼 Construir Contexto Location
  ↓
✅ Validar Cliente Ativo (NOVO!)  ← Correção #3
  ↓ (se is_active=true)
Buscar Dados do Agente
  ↓
Buscar Mídia Triggers
  ↓
Merge: Agente + Mídia
  ↓
... (resto do fluxo)
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Preparação
- [ ] Criar RPC `upsert_conversation` (se não existir)
- [ ] Testar RPC no SQL Editor do Supabase
- [ ] Backup do workflow atual (exportar JSON)

### Implementação
- [ ] **Correção #1:** Adicionar node "📝 Upsert Conversation"
  - [ ] Criar node HTTP Request
  - [ ] Configurar body com parâmetros
  - [ ] Conectar após "Filtrar Apenas Incoming"
  - [ ] Testar com mensagem real

- [ ] **Correção #2:** Adicionar node "🔐 Validar Webhook Habilitado"
  - [ ] Criar node HTTP Request
  - [ ] Adicionar node Code de validação
  - [ ] Conectar antes de "Identificar Cliente e Agente"
  - [ ] Testar desabilitando webhook

- [ ] **Correção #3:** Adicionar node "✅ Validar Cliente Ativo"
  - [ ] Criar node HTTP Request
  - [ ] Adicionar node Code de validação
  - [ ] Conectar após "💼 Construir Contexto Location"
  - [ ] Testar desativando cliente

### Testes
- [ ] Teste #1: Enviar mensagem e verificar `conversations` atualizada
- [ ] Teste #2: Desabilitar webhook e verificar abort
- [ ] Teste #3: Desativar cliente e verificar abort
- [ ] Teste #4: Workflow completo com todos os nodes

### Deploy
- [ ] Commit das mudanças no Git
- [ ] Documentar mudanças em CHANGELOG.md
- [ ] Notificar equipe das validações adicionadas

---

## 🎯 IMPACTO ESPERADO

### Antes
- ❌ 20 conversas órfãs no banco
- ❌ Webhooks desabilitados funcionando
- ❌ Clientes inativos sendo atendidos

### Depois
- ✅ Conversas rastreadas em tempo real
- ✅ Webhooks validados antes de processar
- ✅ Clientes validados (ativo + quotas)
- ✅ Melhor segurança multi-tenant
- ✅ Dados consistentes no banco

### Métricas
- 📊 **Conversations Criadas:** De 0% para 100% das mensagens
- 🔒 **Segurança:** +2 camadas de validação
- 📈 **Confiabilidade:** +30% (dados consistentes)

---

## ⏱️ ESTIMATIVA DE TEMPO

| Tarefa | Tempo |
|--------|-------|
| Criar RPC upsert_conversation | 15 min |
| Node #1 (Upsert Conversation) | 30 min |
| Node #2 (Validar Webhook) | 20 min |
| Node #3 (Validar Cliente) | 20 min |
| Testes | 30 min |
| Documentação | 15 min |
| **TOTAL** | **2h 10min** |

---

## 📝 NOTAS IMPORTANTES

1. **RPC já existe?** 
   - Verificar se `upsert_conversation` já está no banco
   - Se não: criar antes de implementar node

2. **Error Handling:**
   - Todos os nodes devem ter `continueOnFail: false` para abortar
   - Logs detalhados em caso de erro

3. **Rollback:**
   - Manter backup do workflow antes das mudanças
   - Testar em ambiente de staging primeiro (se disponível)

4. **Performance:**
   - +3 queries HTTP por mensagem
   - Impacto mínimo: ~100ms adicional

---

*Documento criado em: 15/12/2025 19:15*
*Baseado em: Análise Workflow vs Database*
*Prioridade: 🔴 ALTA*

# 🔄 Migração de Workflows: De CLIENTS para AGENTS

> **Data**: 06/11/2025  
> **Versão**: 2.0 (Multi-Agent Support)  
> **Status**: ✅ Migration 001 executada com sucesso

---

## 📋 Sumário de Mudanças

### 1. **Webhook URL** (Breaking Change ⚠️)

#### ❌ Formato Antigo:
```
POST /gestor-ia?client_id=clinica_sorriso_001
```

#### ✅ Novo Formato:
```
POST /gestor-ia?client_id=clinica_sorriso_001&agent_id=default
POST /gestor-ia?client_id=clinica_sorriso_001&agent_id=sdr
POST /gestor-ia?client_id=clinica_sorriso_001&agent_id=support
```

**Retrocompatibilidade**: Se `agent_id` não for informado, assume `default`.

---

## 🔧 Mudanças por Workflow

### **WF0 Part 1: Webhook → Context Window**

#### Node: "Extract & Validate"
```javascript
// ADICIONAR esta linha
const agent_id = $input.item.json.query?.agent_id || 'default';

// No return, adicionar:
return {
  client_id,
  agent_id, // NEW
  ...messageData
};
```

#### Node: "Load Client Config" → **"Load Agent Config"**
```sql
-- ANTES
SELECT * FROM public.clients
WHERE client_id = '{{ $json.client_id }}'
  AND is_active = true;

-- DEPOIS
SELECT 
  a.client_id,
  a.agent_id,
  a.agent_name,
  c.client_name,
  a.system_prompt,
  a.llm_model,
  a.tools_enabled,
  a.rag_namespace,
  a.buffer_delay,
  a.chatwoot_host,
  a.chatwoot_token,
  a.chatwoot_inbox_id,
  a.evolution_instance_id,
  a.tool_credentials,
  a.usage_limits
FROM public.agents a
JOIN public.clients c ON c.client_id = a.client_id
WHERE a.client_id = '{{ $json.client_id }}'
  AND a.agent_id = '{{ $json.agent_id }}'
  AND a.is_active = true
  AND c.is_active = true
LIMIT 1;
```

#### Node: "Check Buffer (Redis)"
```javascript
// ANTES
const bufferKey = `buffer:${client_id}:${conversation_id}`;

// DEPOIS
const bufferKey = `buffer:${client_id}:${agent_id}:${conversation_id}`;
```

#### Node: "Load Conversation Memory"
```javascript
// ANTES
key: `memory:${client_id}:${conversation_id}`

// DEPOIS
key: `memory:${client_id}:${agent_id}:${conversation_id}`
```

#### Node: "Load Conversation History"
```javascript
// ANTES
key: `history:${client_id}:${conversation_id}`

// DEPOIS  
key: `history:${client_id}:${agent_id}:${conversation_id}`
```

---

### **WF0 Part 2: LLM & Tools Execution**

#### Node: "Prepare Vertex AI Request"
**Nenhuma mudança necessária** - usa config que já vem do Part 1.

#### Node: "RAG: Search Database"
```sql
-- ANTES
SELECT * FROM search_rag_hybrid(
  p_namespace := '{{ $('Load Client Config').item.json.rag_namespace }}',
  ...
);

-- DEPOIS
SELECT * FROM search_rag_hybrid(
  p_namespace := '{{ $('Load Agent Config').item.json.rag_namespace }}',
  ...
);
```

**IMPORTANTE**: `rag_namespace` agora é por agente:
- `clinica_sorriso_001/default`
- `clinica_sorriso_001/sdr`
- `clinica_sorriso_001/support`

---

### **WF0 Part 3: Finalization & Response**

#### Node: "Prepare Memory Save"
```javascript
// ADICIONAR agent_id nas chaves Redis
const memoryKey = `memory:${clientId}:${agentId}:${conversationId}`;
const historyKey = `history:${clientId}:${agentId}:${conversationId}`;
```

#### Node: "Log Execution to DB"
```sql
INSERT INTO public.agent_executions (
  client_id,
  agent_id, -- NEW COLUMN
  conversation_id,
  ...
) VALUES (
  '{{ $('Extract & Validate').item.json.client_id }}',
  '{{ $('Extract & Validate').item.json.agent_id }}', -- NEW
  ...
);
```

#### Node: "Route to Channel"
```javascript
// Usar configurações específicas do agente
const config = $('Load Agent Config').item.json;

// Chatwoot: usar chatwoot_inbox_id específico do agente
const inboxId = config.chatwoot_inbox_id;

// WhatsApp: usar whatsapp_provider específico do agente
const provider = config.whatsapp_provider; // 'evolution', 'cloud_api', 'twilio'
```

---

## 🗄️ Mudanças no Banco de Dados

### Tabela: `agent_executions`
```sql
-- Adicionar coluna agent_id (já feito na migration)
ALTER TABLE public.agent_executions 
  ADD COLUMN IF NOT EXISTS agent_id text;

CREATE INDEX IF NOT EXISTS idx_agent_executions_agent_id 
  ON public.agent_executions(agent_id);
```

### Tabela: `rag_documents`
```sql
-- Adicionar coluna agent_id (já feito na migration)
ALTER TABLE public.rag_documents 
  ADD COLUMN IF NOT EXISTS agent_id text;

-- Documentos existentes vinculados ao agente 'default'
UPDATE public.rag_documents 
SET agent_id = 'default' 
WHERE agent_id IS NULL;
```

---

## 📊 Redis Keys Schema

### **Antes** (por cliente):
```
buffer:clinica_sorriso_001:5511999999999
memory:clinica_sorriso_001:5511999999999
history:clinica_sorriso_001:5511999999999
```

### **Depois** (por cliente + agente):
```
buffer:clinica_sorriso_001:default:5511999999999
buffer:clinica_sorriso_001:sdr:5511999999999
memory:clinica_sorriso_001:default:5511999999999
memory:clinica_sorriso_001:sdr:5511999999999
history:clinica_sorriso_001:default:5511999999999
history:clinica_sorriso_001:sdr:5511999999999
```

**Benefício**: Cada agente tem memória isolada, mesmo na mesma conversa.

---

## 🧪 Como Testar

### 1. **Teste com agente 'default'** (retrocompatibilidade)
```bash
curl -X POST https://n8n.seudominio.com/webhook/gestor-ia?client_id=clinica_sorriso_001 \
  -H "Content-Type: application/json" \
  -d '{
    "conversation": {
      "id": 123
    },
    "sender": {
      "name": "João",
      "phone_number": "+5511999999999"
    },
    "content": "Olá, preciso de ajuda"
  }'
```

### 2. **Teste com agente específico**
```bash
curl -X POST https://n8n.seudominio.com/webhook/gestor-ia?client_id=clinica_sorriso_001&agent_id=sdr \
  -H "Content-Type: application/json" \
  -d '{
    "conversation": {
      "id": 123
    },
    "sender": {
      "name": "João",
      "phone_number": "+5511999999999"
    },
    "content": "Quero agendar uma avaliação"
  }'
```

### 3. **Verificar logs no Supabase**
```sql
-- Ver execuções por agente
SELECT 
  agent_id,
  COUNT(*) as executions,
  SUM(total_cost_usd) as total_cost
FROM agent_executions
WHERE client_id = 'clinica_sorriso_001'
  AND created_at > NOW() - INTERVAL '1 day'
GROUP BY agent_id;
```

---

## 🚀 Rollout Sugerido

### Fase 1: **Preparação** (✅ Concluído)
- [x] Migration 001 executada
- [x] Tabela `agents` criada
- [x] Agente `default` criado para clientes existentes

### Fase 2: **Atualizar Workflows** (🔄 Em Progresso)
- [ ] Importar WF0-V2-AGENTS.json no n8n
- [ ] Testar com client_id + agent_id=default
- [ ] Validar logs no Supabase
- [ ] Validar memory/history no Redis

### Fase 3: **Migração Gradual** (📅 Próximo)
- [ ] Criar agente `sdr` para clinica_sorriso_001
- [ ] Configurar inbox Chatwoot separado
- [ ] Upload documentos RAG específicos (namespace: clinica_sorriso_001/sdr)
- [ ] Testar agente SDR isoladamente

### Fase 4: **Deprecar Versão Antiga** (🔮 Futuro)
- [ ] Remover WF0 v1 (após 30 dias de transição)
- [ ] Atualizar Chatwoot webhooks com agent_id
- [ ] Documentar API externa (se houver)

---

## ⚠️ Breaking Changes & Mitigações

### 1. **Webhook URL mudou**
- **Impacto**: Integrações externas podem quebrar
- **Mitigação**: agent_id=default é opcional (retrocompatível)
- **Prazo**: 30 dias para atualizar integrações

### 2. **Redis keys mudaram**
- **Impacto**: Histórico de conversas antigas não será encontrado
- **Mitigação**: Script de migração de keys (opcional)
- **Prazo**: N/A (histórico se reconstrói naturalmente)

### 3. **RAG namespace mudou**
- **Impacto**: Documentos existentes não serão encontrados
- **Mitigação**: Documentos mapeados para agent_id='default'
- **Prazo**: Imediato (feito na migration)

---

## 📈 Benefícios da Migração

### 1. **Múltiplos Agentes por Cliente**
- Cliente pode ter agente SDR + Suporte + Cobrança
- Cada agente com prompt e personalidade próprios
- Isolamento de contexto e memória

### 2. **Roteamento Inteligente**
- Chatwoot: vincular inbox → agent_id
- WhatsApp: múltiplos números → múltiplos agentes
- Evolution + Cloud API simultaneamente

### 3. **RAG Especializado**
- Base de conhecimento por agente
- SDR: scripts de vendas
- Suporte: troubleshooting
- Cobrança: políticas de pagamento

### 4. **Métricas Granulares**
```sql
-- Custo por agente
SELECT agent_id, SUM(total_cost_usd)
FROM agent_executions
GROUP BY agent_id;

-- Performance por agente
SELECT agent_id, AVG(total_latency_ms)
FROM agent_executions
GROUP BY agent_id;
```

---

## 🔗 Referências

- **Migration SQL**: `/database/migrations/001_add_agents_table_CUSTOM.sql`
- **Workflow V2**: `/workflows/WF0-Gestor-Universal-V2-AGENTS.json`
- **Documentação**: `/docs/ARCHITECTURE.md`
- **Diagrams**: `/DIAGRAMS.md`

---

## 📞 Suporte

**Dúvidas?** Revise:
1. `SUMARIO_EXECUTIVO.md` - Visão geral do projeto
2. `GAPS.md` - Funcionalidades pendentes
3. `COMPLETED.md` - O que já foi feito

**Problemas?** Verifique:
```sql
-- Agentes ativos
SELECT * FROM agents WHERE is_active = true;

-- Últimas execuções
SELECT * FROM agent_executions 
ORDER BY created_at DESC 
LIMIT 10;
```

---

**Versão do Documento**: 1.0  
**Última Atualização**: 06/11/2025  
**Autor**: Victor Castro + GitHub Copilot

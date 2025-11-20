# 📊 Tabelas Existentes no Supabase

## ✅ Estrutura Atual do Banco de Dados

Baseado nas migrations executadas (001-021), você já possui estas tabelas:

---

## 🏢 Core (Clientes e Agentes)

### 1. `clients`
**Multi-tenancy principal - conta do cliente**

```sql
- id (UUID, PK)
- client_id (TEXT, UNIQUE) -- Ex: 'clinica_sorriso_001'
- client_name (TEXT) -- "Clínica Sorriso"
- is_active (BOOLEAN)
- package (TEXT) -- 'starter', 'professional', 'enterprise'
- created_at, updated_at
- admin_email, admin_phone
- stripe_customer_id, stripe_subscription_id
- max_agents (INTEGER) -- Limite de agentes por plano
- chatwoot_inbox_id (INTEGER) -- Migration 007
- chatwoot_agent_id (INTEGER)
- chatwoot_agent_email (TEXT)
- chatwoot_access_granted (BOOLEAN)
- chatwoot_setup_at (TIMESTAMPTZ)
- rate_limits (JSONB)
- notes, tags, custom_fields
```

---

### 2. `agents`
**Múltiplos agentes por cliente - Migration 001**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients.client_id)
- agent_id (TEXT) -- 'default', 'sdr', 'support', etc
- agent_name (TEXT) -- "Agente Principal"
- is_active (BOOLEAN)
- package (TEXT)
- system_prompt (TEXT) -- Prompt específico do agente
- llm_provider (TEXT) -- 'google', 'openai'
- llm_model (TEXT) -- 'gemini-2.0-flash-exp', 'gpt-4o'
- llm_config (JSONB)
- tools_enabled (JSONB) -- ['rag', 'calendar', 'sheets']
- rag_namespace (TEXT, UNIQUE) -- 'client_id/agent_id'
- rag_config (JSONB)
- image_gen_provider (TEXT)
- image_gen_model (TEXT)
- image_gen_config (JSONB)
- buffer_delay (INTEGER)
- rate_limits (JSONB)
- google_calendar_id (TEXT)
- google_sheet_id (TEXT)
- crm_type (TEXT)
- crm_config (JSONB)
- whatsapp_provider (TEXT) -- 'evolution', 'cloud_api', 'twilio'
- whatsapp_config (JSONB)
- chatwoot_inbox_id (INTEGER)
- created_at, updated_at

UNIQUE(client_id, agent_id)
```

---

## 💬 Conversas e Mensagens

### 3. `conversation_memory`
**Histórico de mensagens - Migration 019**

```sql
- id (UUID, PK)
- client_id (VARCHAR, FK → clients)
- conversation_id (INTEGER) -- ID da conversa no Chatwoot
- message_role (VARCHAR) -- 'user', 'assistant', 'system'
- message_content (TEXT)
- message_timestamp (TIMESTAMPTZ)
- contact_id (INTEGER)
- agent_id (VARCHAR) -- 'default'
- channel (VARCHAR) -- 'whatsapp'
- has_attachments (BOOLEAN)
- attachments (JSONB)
- metadata (JSONB)
- created_at (TIMESTAMPTZ)

INDEX: (client_id, conversation_id, message_timestamp DESC)

RLS HABILITADO
```

**Funções RPC:**
- `get_conversation_history(client_id, conversation_id, limit)` → Busca últimas N mensagens
- `save_conversation_message(...)` → Salva nova mensagem
- `cleanup_old_conversation_memory(days_to_keep)` → Remove mensagens antigas (TTL)

---

### 4. `memory_config`
**Configuração de memória por agente - Migration 021**

```sql
- id (UUID, PK)
- client_id (VARCHAR, FK → clients)
- agent_id (VARCHAR) -- 'default'
- memory_limit (INTEGER) -- Max mensagens (padrão: 50)
- memory_hours_back (INTEGER) -- Janela temporal (padrão: 24h)
- memory_enabled (BOOLEAN)
- created_at, updated_at

UNIQUE(client_id, agent_id)
```

---

## 📚 RAG (Knowledge Base)

### 5. `rag_documents`
**Documentos com embeddings vetoriais - Migration 020**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → agents)
- agent_id (TEXT, FK → agents)
- content (TEXT) -- Chunk do documento
- content_hash (TEXT) -- MD5 para deduplicação
- embedding (VECTOR(1536)) -- OpenAI ada-002 embedding
- metadata (JSONB)
- source_type (TEXT) -- 'pdf', 'txt', 'url', 'manual'
- source_id (TEXT)
- source_url (TEXT)
- file_name (TEXT)
- chunk_index (INTEGER)
- total_chunks (INTEGER)
- created_at, updated_at
- created_by (TEXT)

INDEX: ivfflat (embedding vector_cosine_ops) -- Busca vetorial
INDEX: (client_id, agent_id)
INDEX: (content_hash)

RLS HABILITADO
```

**Extensão necessária:**
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

---

## 📸 Mídia do Cliente

### 6. `client_media`
**Acervo de mídia (fotos, vídeos, PDFs) - Migration 005**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients)
- agent_id (TEXT, FK → agents) -- Opcional
- file_name (TEXT)
- file_type (TEXT) -- 'image', 'video', 'document', 'audio'
- file_url (TEXT) -- URL do Supabase Storage
- file_size_bytes (BIGINT)
- mime_type (TEXT)
- title (TEXT)
- description (TEXT)
- tags (TEXT[]) -- ['consultorio', 'recepcao', 'unidade_centro']
- category (TEXT) -- 'branding', 'facilities', 'team', 'services'
- is_active (BOOLEAN)
- upload_date, created_at, updated_at

INDEX: GIN(tags) -- Busca por tags
INDEX: (client_id, agent_id)
```

---

### 7. `media_send_rules`
**Regras para envio automático de mídia - Migration 005**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients)
- agent_id (TEXT)
- rule_type (TEXT) -- 'keyword_trigger', 'conversation_phase', 'llm_decision'
- rule_name (TEXT)
- keywords (TEXT[])
- match_type (TEXT) -- 'contains', 'exact', 'regex'
- message_number (INTEGER)
- media_id (UUID, FK → client_media)
- is_active (BOOLEAN)
- priority (INTEGER)
- created_at, updated_at
```

---

### 8. `media_send_log`
**Histórico de envios de mídia - Migration 005**

```sql
- id (UUID, PK)
- client_id (TEXT)
- agent_id (TEXT)
- conversation_id (INTEGER)
- media_id (UUID, FK → client_media)
- rule_id (UUID, FK → media_send_rules)
- sent_at (TIMESTAMPTZ)
- trigger_reason (TEXT)
- success (BOOLEAN)
- error_message (TEXT)
```

**Função RPC:**
- `search_client_media(client_id, agent_id, tags, file_type, category)` → Busca mídia

---

## 🏢 Multi-Localização

### 9. `locations`
**Múltiplas unidades/filiais - Migration 011**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients)
- location_name (TEXT) -- "Unidade Centro"
- location_type (TEXT) -- 'clinic', 'office', 'store'
- address_full (TEXT)
- address_city, address_state, address_zip
- phone_main, phone_whatsapp
- email (TEXT)
- chatwoot_inbox_id (INTEGER) -- 1 inbox por localização
- display_order (INTEGER)
- working_hours (JSONB) -- Horário de funcionamento
- services_offered (JSONB)
- media_folder (TEXT) -- Pasta no Storage
- is_active (BOOLEAN)
- created_at, updated_at

INDEX: (client_id, is_active)
```

---

### 10. `staff`
**Equipe/profissionais por localização - Migration 012**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients)
- location_id (UUID, FK → locations)
- staff_name (TEXT) -- "Dr. João Silva"
- role (TEXT) -- 'doctor', 'receptionist', 'manager'
- specialties (TEXT[])
- phone, email
- photo_url (TEXT)
- bio (TEXT)
- working_schedule (JSONB)
- is_active (BOOLEAN)
- created_at, updated_at

INDEX: (client_id, location_id, is_active)
```

---

## 💰 Billing e Usage

### 11. `client_usage`
**Tracking de uso para billing - Migration 002**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients)
- billing_period (DATE) -- '2025-11-01'
- timestamp (TIMESTAMPTZ)
- total_requests (INTEGER)
- successful_requests (INTEGER)
- failed_requests (INTEGER)
- total_tokens_in (INTEGER)
- total_tokens_out (INTEGER)
- total_tokens (INTEGER)
- images_generated (INTEGER)
- rag_searches (INTEGER)
- calendar_operations (INTEGER)
- crm_operations (INTEGER)
- email_sent (INTEGER)
- sms_sent (INTEGER)
- llm_cost_usd (NUMERIC)
- tools_cost_usd (NUMERIC)
- storage_cost_usd (NUMERIC)
- total_cost_usd (NUMERIC)
- details (JSONB)

UNIQUE(client_id, billing_period)
INDEX: (client_id, billing_period DESC)
```

---

### 12. `packages` (Marketplace)
**Planos/pacotes disponíveis - Migration 002**

```sql
- id (UUID, PK)
- package_name (TEXT, UNIQUE) -- 'starter', 'pro', 'enterprise'
- display_name (TEXT) -- "Plano Starter"
- description (TEXT)
- price_monthly_usd (NUMERIC)
- price_yearly_usd (NUMERIC)
- features (JSONB)
- limits (JSONB)
- is_active (BOOLEAN)
- is_featured (BOOLEAN)
- created_at, updated_at
```

---

### 13. `client_subscriptions`
**Assinaturas ativas - Migration 002**

```sql
- id (UUID, PK)
- client_id (TEXT, FK → clients)
- package_name (TEXT, FK → packages)
- status (TEXT) -- 'active', 'trialing', 'canceled', 'expired'
- started_at (TIMESTAMPTZ)
- trial_ends_at (TIMESTAMPTZ)
- current_period_start (TIMESTAMPTZ)
- current_period_end (TIMESTAMPTZ)
- canceled_at (TIMESTAMPTZ)
- stripe_subscription_id (TEXT)
- created_at, updated_at
```

---

## 🔧 Outras Tabelas

### 14. `agent_executions`
**Log de execuções do agente**

```sql
- id (UUID, PK)
- client_id (TEXT)
- agent_id (TEXT)
- execution_timestamp (TIMESTAMPTZ)
- status (TEXT) -- 'success', 'error'
- details (JSONB)
```

---

### 15. `channels`
**Canais de comunicação (WhatsApp, Email, etc)**

```sql
- id (UUID, PK)
- client_id (TEXT)
- assigned_agent_id (TEXT)
- channel_type (TEXT) -- 'whatsapp', 'email', 'chat'
- channel_config (JSONB)
- is_active (BOOLEAN)
```

---

### 16. `rate_limit_buckets`
**Controle de rate limiting**

```sql
- id (UUID, PK)
- client_id (TEXT)
- agent_id (TEXT)
- bucket_type (TEXT)
- current_count (INTEGER)
- reset_at (TIMESTAMPTZ)
```

---

## 🔒 Row Level Security (RLS)

**Tabelas com RLS habilitado:**
- ✅ `agents`
- ✅ `conversation_memory`
- ✅ `rag_documents`

**Políticas aplicadas:**
- Clientes só veem dados do próprio `client_id`
- Filtros automáticos por `client_id` em todas as queries

---

## 📊 Resumo Quantitativo

| Categoria | Tabelas |
|-----------|---------|
| **Core** | clients, agents |
| **Conversas** | conversation_memory, memory_config |
| **RAG** | rag_documents |
| **Mídia** | client_media, media_send_rules, media_send_log |
| **Multi-Localização** | locations, staff |
| **Billing** | client_usage, packages, client_subscriptions |
| **Outras** | agent_executions, channels, rate_limit_buckets |
| **TOTAL** | **16 tabelas** |

---

## 🎯 Para o Dashboard (app.digitai.app)

### Tabelas que você VAI USAR:

✅ **JÁ EXISTEM:**
- `clients` → Dados do cliente logado
- `conversation_memory` → Histórico de mensagens
- `agents` → Informações do agente

❌ **FALTAM CRIAR:**
- Nenhuma! Você já tem tudo necessário.

### Ajustes Necessários:

1. **Adicionar colunas para autenticação:**

```sql
-- Na tabela clients (ou criar nova tabela users)
ALTER TABLE clients 
ADD COLUMN auth_user_id UUID REFERENCES auth.users(id);

-- Ou criar tabela separada:
CREATE TABLE dashboard_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  client_id TEXT REFERENCES clients(client_id),
  full_name TEXT,
  role TEXT DEFAULT 'owner', -- 'owner', 'admin', 'viewer'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

2. **RLS para conversation_memory:**

```sql
-- Já existe! Apenas ajustar policy se necessário
CREATE POLICY "Users can view their client conversations"
ON conversation_memory FOR SELECT
USING (
  client_id IN (
    SELECT client_id FROM dashboard_users WHERE id = auth.uid()
  )
);
```

3. **Função para métricas do dashboard:**

```sql
-- Já existe: get_daily_stats(client_id, date)
-- Retorna: total_conversations, ai_resolved, human_handled, active_now
```

---

## ✅ Conclusão

**Você já tem 95% do necessário!**

Para o dashboard funcionar, você só precisa:
1. ✅ Configurar Supabase Auth (email/senha)
2. ✅ Vincular `auth.users` com `clients`
3. ✅ Ajustar RLS para permitir acesso do cliente
4. ✅ Usar as tabelas existentes nas queries

**Nenhuma migration nova necessária!** 🎉

---

**Última atualização:** 17/11/2025

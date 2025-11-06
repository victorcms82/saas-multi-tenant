# Setup Guide - WF 0: Gestor Universal

## 📋 Checklist de Configuração

### 1. ✅ Preparação do Ambiente

#### 1.1. Supabase
- [ ] Projeto criado no Supabase
- [ ] Conectado ao banco de dados
- [ ] Vault habilitado
- [ ] Extensions instaladas (`vector`, `pg_cron`)

#### 1.2. Google Cloud
- [ ] Projeto criado (`n8n-evolute`)
- [ ] APIs habilitadas:
  - [ ] Vertex AI API
  - [ ] Cloud Storage API
  - [ ] Cloud Functions API
- [ ] Service Account criada (`n8n-vertex-ai-sa`)
- [ ] Chave JSON gerada
- [ ] Roles configurados:
  - [ ] Vertex AI User
  - [ ] Storage Object Viewer

#### 1.3. Redis
- [ ] Instância configurada (local ou Upstash)
- [ ] DB-0 para buffer
- [ ] DB-1 para memória e cache

#### 1.4. n8n
- [ ] n8n rodando (versão 1.118.1+)
- [ ] Acesso ao painel
- [ ] HTTPS configurado (para webhooks)

---

### 2. 🗄️ Database Setup (Supabase)

Execute os scripts SQL na ordem:

#### 2.1. Extensions e Functions Base

```sql
-- Habilitar extensões
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Function para atualizar updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at() 
RETURNS TRIGGER AS $$ 
BEGIN 
  NEW.updated_at = now(); 
  RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;
```

#### 2.2. Criar Tabelas Core

```sql
-- Tabela clients
CREATE TABLE public.clients (
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  
  client_id text NOT NULL UNIQUE,
  client_name text NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  is_trial boolean DEFAULT false NOT NULL,
  trial_expires_at timestamptz,
  
  package text NOT NULL,
  system_prompt text NOT NULL,
  
  llm_provider text DEFAULT 'google'::text NOT NULL,
  llm_model text DEFAULT 'gemini-2.0-flash-exp'::text NOT NULL,
  llm_config jsonb DEFAULT '{"temperature": 0.7, "top_p": 0.95, "max_tokens": 2048}'::jsonb,
  
  tools_enabled jsonb DEFAULT '["rag"]'::jsonb NOT NULL,
  
  rag_namespace text NOT NULL UNIQUE,
  rag_config jsonb DEFAULT '{"chunk_size": 1000, "chunk_overlap": 200, "top_k": 5, "min_similarity": 0.7}'::jsonb,
  
  image_gen_provider text DEFAULT 'google'::text,
  image_gen_model text DEFAULT 'imagen-3.0-generate-001'::text,
  image_gen_config jsonb DEFAULT '{"size": "1024x1024", "quality": "standard"}'::jsonb,
  
  buffer_delay integer DEFAULT 1 NOT NULL,
  timezone text DEFAULT 'America/Sao_Paulo'::text,
  
  rate_limits jsonb DEFAULT '{"requests_per_minute": 60, "requests_per_day": 10000, "tokens_per_month": 1000000, "images_per_month": 100}'::jsonb,
  
  webhook_secret text DEFAULT gen_random_uuid()::text NOT NULL,
  google_credentials_vault_id uuid,
  chatwoot_token_vault_id uuid,
  evolution_token_vault_id uuid,
  
  chatwoot_host text,
  chatwoot_account_id integer,
  chatwoot_inbox_id integer,
  
  evolution_instance_name text,
  evolution_webhook_url text,
  
  google_calendar_id text,
  google_sheet_id text,
  
  crm_type text,
  crm_config jsonb,
  
  admin_name text NOT NULL,
  admin_email text NOT NULL,
  admin_phone text,
  admin_user_id uuid,
  
  stripe_customer_id text,
  stripe_subscription_id text,
  billing_email text,
  monthly_budget_usd numeric(10,2),
  
  notes text,
  tags text[],
  custom_fields jsonb
);

-- Índices
CREATE INDEX idx_clients_client_id ON public.clients(client_id);
CREATE INDEX idx_clients_is_active ON public.clients(is_active) WHERE is_active = true;

-- Trigger
CREATE TRIGGER on_clients_updated 
  BEFORE UPDATE ON public.clients 
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_updated_at();
```

#### 2.3. Criar Tabela RAG Documents

```sql
-- Tabela rag_documents
CREATE TABLE public.rag_documents (
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  created_at timestamptz DEFAULT now() NOT NULL,
  
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  rag_namespace text NOT NULL,
  
  document_id uuid NOT NULL,
  source_type text NOT NULL,
  source_url text,
  source_name text NOT NULL,
  uploaded_at timestamptz DEFAULT now() NOT NULL,
  uploaded_by text,
  
  chunk_index integer NOT NULL,
  chunk_text text NOT NULL,
  chunk_tokens integer,
  
  embedding vector(768),
  
  metadata jsonb,
  
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('portuguese', chunk_text)
  ) STORED,
  
  is_active boolean DEFAULT true NOT NULL,
  quality_score numeric(3,2),
  
  version integer DEFAULT 1,
  previous_version_id uuid REFERENCES public.rag_documents(id),
  
  CONSTRAINT unique_namespace_document_chunk 
    UNIQUE(rag_namespace, document_id, chunk_index)
);

-- Índices
CREATE INDEX idx_rag_namespace ON public.rag_documents(rag_namespace);
CREATE INDEX idx_rag_client_id ON public.rag_documents(client_id);
CREATE INDEX idx_rag_document_id ON public.rag_documents(document_id);

-- Índice vetorial (ajustar lists baseado no volume)
CREATE INDEX idx_rag_embedding ON public.rag_documents 
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- Índice de texto completo
CREATE INDEX idx_rag_search_vector ON public.rag_documents 
  USING GIN(search_vector);
```

#### 2.4. Criar Tabela Agent Executions

```sql
-- Tabela agent_executions
CREATE TABLE public.agent_executions (
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  timestamp timestamptz DEFAULT now() NOT NULL,
  
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  conversation_id text NOT NULL,
  contact_id text,
  
  channel_type text NOT NULL,
  channel_config jsonb,
  
  user_message text,
  user_message_type text,
  user_attachments jsonb,
  
  system_prompt_used text,
  llm_provider text NOT NULL,
  llm_model text NOT NULL,
  llm_config jsonb,
  
  conversation_history jsonb,
  rag_context jsonb,
  tools_context jsonb,
  
  tools_called jsonb,
  
  agent_response text,
  agent_response_type text,
  agent_attachments jsonb,
  
  total_latency_ms integer,
  llm_latency_ms integer,
  rag_latency_ms integer,
  tools_latency_ms integer,
  
  prompt_tokens integer,
  completion_tokens integer,
  total_tokens integer,
  cached_tokens integer,
  
  llm_cost_usd numeric(10,6),
  tools_cost_usd numeric(10,6),
  total_cost_usd numeric(10,6),
  
  status text NOT NULL DEFAULT 'success',
  error_message text,
  error_stack text,
  
  quality_metrics jsonb,
  
  n8n_workflow_id text,
  n8n_execution_id text,
  trace_id text,
  span_id text,
  
  was_cached boolean DEFAULT false,
  required_human_handoff boolean DEFAULT false,
  user_feedback integer,
  
  tags text[],
  notes text
);

-- Índices
CREATE INDEX idx_executions_client_timestamp ON public.agent_executions(client_id, timestamp DESC);
CREATE INDEX idx_executions_conversation ON public.agent_executions(conversation_id, timestamp);
CREATE INDEX idx_executions_status ON public.agent_executions(status) WHERE status != 'success';
```

#### 2.5. Criar Tabela Client Usage

```sql
-- Tabela client_usage
CREATE TABLE public.client_usage (
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  timestamp timestamptz DEFAULT now() NOT NULL,
  
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  billing_period date NOT NULL,
  
  total_requests integer DEFAULT 0,
  successful_requests integer DEFAULT 0,
  failed_requests integer DEFAULT 0,
  
  total_tokens_in integer DEFAULT 0,
  total_tokens_out integer DEFAULT 0,
  total_tokens integer DEFAULT 0,
  
  images_generated integer DEFAULT 0,
  
  rag_searches integer DEFAULT 0,
  calendar_operations integer DEFAULT 0,
  crm_operations integer DEFAULT 0,
  email_sent integer DEFAULT 0,
  sms_sent integer DEFAULT 0,
  
  llm_cost_usd numeric(10,2) DEFAULT 0.00,
  tools_cost_usd numeric(10,2) DEFAULT 0.00,
  storage_cost_usd numeric(10,2) DEFAULT 0.00,
  total_cost_usd numeric(10,2) DEFAULT 0.00,
  
  details jsonb,
  
  CONSTRAINT unique_client_period UNIQUE(client_id, billing_period)
);

-- Índices
CREATE INDEX idx_usage_client_period ON public.client_usage(client_id, billing_period DESC);
```

#### 2.6. Criar Tabela Rate Limit Buckets

```sql
-- Tabela rate_limit_buckets
CREATE TABLE public.rate_limit_buckets (
  client_id text PRIMARY KEY REFERENCES public.clients(client_id) ON DELETE CASCADE,
  
  minute_count integer DEFAULT 0 NOT NULL,
  minute_reset timestamptz NOT NULL DEFAULT (now() + interval '1 minute'),
  
  hour_count integer DEFAULT 0 NOT NULL,
  hour_reset timestamptz NOT NULL DEFAULT (now() + interval '1 hour'),
  
  day_count integer DEFAULT 0 NOT NULL,
  day_reset timestamptz NOT NULL DEFAULT (now() + interval '1 day'),
  
  month_tokens integer DEFAULT 0 NOT NULL,
  month_reset timestamptz NOT NULL DEFAULT date_trunc('month', now() + interval '1 month'),
  
  month_images integer DEFAULT 0 NOT NULL,
  
  last_updated timestamptz DEFAULT now() NOT NULL
);
```

#### 2.7. Criar Functions (Rate Limit e Usage)

```sql
-- Function: check_and_increment_rate_limit
CREATE OR REPLACE FUNCTION check_and_increment_rate_limit(
  p_client_id text,
  p_tokens_to_consume integer DEFAULT 0
) RETURNS jsonb AS $$
DECLARE
  v_limits jsonb;
  v_bucket record;
  v_now timestamptz := now();
  v_allowed boolean := true;
  v_reason text := NULL;
BEGIN
  SELECT rate_limits INTO v_limits
  FROM public.clients
  WHERE client_id = p_client_id;
  
  IF v_limits IS NULL THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'Cliente não encontrado');
  END IF;
  
  INSERT INTO public.rate_limit_buckets (client_id)
  VALUES (p_client_id)
  ON CONFLICT (client_id) DO NOTHING;
  
  SELECT * INTO v_bucket
  FROM public.rate_limit_buckets
  WHERE client_id = p_client_id
  FOR UPDATE;
  
  IF v_now >= v_bucket.minute_reset THEN
    UPDATE public.rate_limit_buckets
    SET minute_count = 0, minute_reset = v_now + interval '1 minute'
    WHERE client_id = p_client_id;
    v_bucket.minute_count := 0;
  END IF;
  
  IF v_now >= v_bucket.day_reset THEN
    UPDATE public.rate_limit_buckets
    SET day_count = 0, day_reset = v_now + interval '1 day'
    WHERE client_id = p_client_id;
    v_bucket.day_count := 0;
  END IF;
  
  IF v_now >= v_bucket.month_reset THEN
    UPDATE public.rate_limit_buckets
    SET month_tokens = 0, month_images = 0,
        month_reset = date_trunc('month', v_now + interval '1 month')
    WHERE client_id = p_client_id;
    v_bucket.month_tokens := 0;
  END IF;
  
  IF v_bucket.minute_count >= (v_limits->>'requests_per_minute')::integer THEN
    v_allowed := false;
    v_reason := 'Rate limit: requisições por minuto excedido';
  ELSIF v_bucket.day_count >= (v_limits->>'requests_per_day')::integer THEN
    v_allowed := false;
    v_reason := 'Rate limit: requisições por dia excedido';
  ELSIF v_bucket.month_tokens + p_tokens_to_consume > (v_limits->>'tokens_per_month')::integer THEN
    v_allowed := false;
    v_reason := 'Quota: tokens mensais excedidos';
  END IF;
  
  IF v_allowed THEN
    UPDATE public.rate_limit_buckets
    SET minute_count = minute_count + 1,
        hour_count = hour_count + 1,
        day_count = day_count + 1,
        month_tokens = month_tokens + p_tokens_to_consume,
        last_updated = v_now
    WHERE client_id = p_client_id;
  END IF;
  
  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'reason', v_reason,
    'current', jsonb_build_object(
      'minute', v_bucket.minute_count,
      'day', v_bucket.day_count,
      'month_tokens', v_bucket.month_tokens
    ),
    'limits', v_limits
  );
END;
$$ LANGUAGE plpgsql;

-- Function: increment_client_usage
CREATE OR REPLACE FUNCTION increment_client_usage(
  p_client_id text,
  p_tokens_in integer DEFAULT 0,
  p_tokens_out integer DEFAULT 0,
  p_images integer DEFAULT 0,
  p_rag_searches integer DEFAULT 0,
  p_cost_usd numeric DEFAULT 0.00
) RETURNS void AS $$
DECLARE
  v_period date := date_trunc('month', now());
BEGIN
  INSERT INTO public.client_usage (
    client_id, billing_period,
    total_requests,
    total_tokens_in, total_tokens_out, total_tokens,
    images_generated, rag_searches,
    total_cost_usd
  ) VALUES (
    p_client_id, v_period,
    1,
    p_tokens_in, p_tokens_out, p_tokens_in + p_tokens_out,
    p_images, p_rag_searches,
    p_cost_usd
  )
  ON CONFLICT (client_id, billing_period) 
  DO UPDATE SET
    total_requests = client_usage.total_requests + 1,
    total_tokens_in = client_usage.total_tokens_in + p_tokens_in,
    total_tokens_out = client_usage.total_tokens_out + p_tokens_out,
    total_tokens = client_usage.total_tokens + p_tokens_in + p_tokens_out,
    images_generated = client_usage.images_generated + p_images,
    rag_searches = client_usage.rag_searches + p_rag_searches,
    total_cost_usd = client_usage.total_cost_usd + p_cost_usd,
    timestamp = now();
END;
$$ LANGUAGE plpgsql;

-- Function: search_rag_hybrid
CREATE OR REPLACE FUNCTION search_rag_hybrid(
  p_namespace text,
  p_query_embedding vector(768),
  p_query_text text,
  p_limit integer DEFAULT 5,
  p_semantic_weight numeric DEFAULT 0.7,
  p_min_similarity numeric DEFAULT 0.7
)
RETURNS TABLE (
  id uuid,
  chunk_text text,
  source_name text,
  similarity numeric,
  rank numeric,
  combined_score numeric
) AS $$
BEGIN
  RETURN QUERY
  WITH semantic_search AS (
    SELECT 
      d.id,
      d.chunk_text,
      d.source_name,
      1 - (d.embedding <=> p_query_embedding) AS similarity,
      ROW_NUMBER() OVER (ORDER BY d.embedding <=> p_query_embedding) AS rank
    FROM public.rag_documents d
    WHERE 
      d.rag_namespace = p_namespace 
      AND d.is_active = true
      AND (1 - (d.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY d.embedding <=> p_query_embedding
    LIMIT p_limit * 2
  ),
  keyword_search AS (
    SELECT 
      d.id,
      ts_rank_cd(d.search_vector, websearch_to_tsquery('portuguese', p_query_text)) AS rank
    FROM public.rag_documents d
    WHERE 
      d.rag_namespace = p_namespace 
      AND d.is_active = true
      AND d.search_vector @@ websearch_to_tsquery('portuguese', p_query_text)
  )
  SELECT 
    s.id,
    s.chunk_text,
    s.source_name,
    s.similarity,
    COALESCE(k.rank, 0) AS keyword_rank,
    (s.similarity * p_semantic_weight + COALESCE(k.rank, 0) * (1 - p_semantic_weight)) AS combined_score
  FROM semantic_search s
  LEFT JOIN keyword_search k ON s.id = k.id
  ORDER BY combined_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
```

#### 2.8. Inserir Cliente de Teste

```sql
-- Cliente de teste
INSERT INTO public.clients (
  client_id,
  client_name,
  package,
  system_prompt,
  rag_namespace,
  admin_name,
  admin_email,
  llm_provider,
  llm_model,
  tools_enabled
) VALUES (
  'test-client',
  'Cliente de Teste',
  'sdr',
  'Você é um assistente virtual amigável e prestativo. Seu objetivo é ajudar os usuários com suas dúvidas de forma clara e objetiva. Sempre seja educado e profissional.',
  'test-client-rag',
  'Admin Teste',
  'admin@teste.com',
  'google',
  'gemini-2.0-flash-exp',
  '["rag"]'::jsonb
);
```

---

### 3. 🔧 Configuração do n8n

#### 3.1. Importar Workflows

1. Acesse n8n
2. Vá em **Workflows** → **Import from File**
3. Importe os 3 arquivos JSON

#### 3.2. Configurar Credentials

Siga as instruções em `workflows/README.md` seção "Configurações Necessárias"

#### 3.3. Ativar Workflow

1. Abra o workflow importado
2. Verifique todas as conexões
3. Clique em **Active** no canto superior direito

---

### 4. 🧪 Testar o Workflow

#### 4.1. Com Postman/Insomnia

```http
POST https://seu-n8n.com/webhook/gestor-ia?client_id=test-client
Content-Type: application/json

{
  "conversation": {
    "id": 999
  },
  "sender": {
    "name": "Teste User",
    "phone_number": "+5521999999999"
  },
  "content": "Olá, esta é uma mensagem de teste!",
  "message_type": "text",
  "inbox": {
    "id": 1
  },
  "account": {
    "id": 1
  }
}
```

#### 4.2. Verificar Logs

```sql
-- Ver execução
SELECT * FROM agent_executions 
WHERE client_id = 'test-client'
ORDER BY timestamp DESC 
LIMIT 1;

-- Ver usage
SELECT * FROM client_usage
WHERE client_id = 'test-client';
```

---

### 5. ✅ Próximos Passos

- [ ] Configurar Chatwoot/Evolution API
- [ ] Adicionar documentos ao RAG
- [ ] Configurar Google Calendar (opcional)
- [ ] Configurar integrações de CRM (opcional)
- [ ] Setup de monitoramento (Grafana, etc)
- [ ] Configurar alertas

---

## 🆘 Problemas Comuns

### Workflow não ativa
- Verifique se todas as credentials estão configuradas
- Confirme que o webhook path não tem conflitos

### Erro ao chamar Vertex AI
- Verifique se Service Account tem permissões corretas
- Confirme que APIs estão habilitadas no Google Cloud

### RAG não funciona
- Certifique-se de ter inserido documentos primeiro
- Verifique se embedding index foi criado

---

**Tempo estimado de setup**: 30-60 minutos

**Autor**: Victor Castro - Evolute Digital  
**Data**: 06/11/2025

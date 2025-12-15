-- ============================================================================
-- MIGRATION 001: Adicionar Tabela AGENTS (Múltiplos Agentes por Cliente)
-- Data: 06/11/2025
-- Autor: Victor Castro + GitHub Copilot
-- Descrição: Reestrutura sistema para suportar N agentes por cliente
-- ============================================================================

-- ============================================================================
-- PARTE 1: CRIAR TABELA AGENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.agents (
  -- Identificação Única
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,

  -- Relacionamento com Cliente (FK)
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  
  -- Identificador do Agente (único dentro do cliente)
  agent_id text NOT NULL, -- Ex: "sdr", "support", "billing"
  agent_name text NOT NULL, -- Nome amigável: "Agente SDR", "Suporte Técnico"
  
  is_active boolean DEFAULT true NOT NULL,
  
  -- Configuração do Agente (Personalidade)
  package text NOT NULL, -- FK lógica para packages.package_name
  system_prompt text NOT NULL, -- Prompt COMPLETO específico deste agente
  
  -- Configuração de LLM (pode sobrescrever padrão do cliente)
  llm_provider text DEFAULT 'google'::text NOT NULL,
  llm_model text DEFAULT 'gemini-2.0-flash-exp'::text NOT NULL,
  llm_config jsonb DEFAULT '{
    "temperature": 0.7,
    "top_p": 0.95,
    "max_tokens": 2048,
    "grounding": true
  }'::jsonb,

  -- Tools Disponíveis (específicas por agente)
  tools_enabled jsonb DEFAULT '["rag"]'::jsonb NOT NULL,
  
  -- Configuração RAG (namespace isolado por agente)
  rag_namespace text NOT NULL UNIQUE, -- Ex: "acme-corp/sdr"
  rag_config jsonb DEFAULT '{
    "chunk_size": 1000,
    "chunk_overlap": 200,
    "top_k": 5,
    "min_similarity": 0.7
  }'::jsonb,

  -- Geração de Imagens (se habilitado)
  image_gen_provider text DEFAULT 'google'::text,
  image_gen_model text DEFAULT 'imagen-3.0-generate-001'::text,
  image_gen_config jsonb DEFAULT '{
    "size": "1024x1024",
    "quality": "standard",
    "style": "vivid"
  }'::jsonb,

  -- Configuração Operacional
  buffer_delay integer DEFAULT 1 NOT NULL,
  
  -- Rate Limits & Quotas (por agente)
  rate_limits jsonb DEFAULT '{
    "requests_per_minute": 60,
    "requests_per_day": 10000,
    "tokens_per_month": 1000000,
    "images_per_month": 100
  }'::jsonb,

  -- Configurações Específicas de Ferramentas
  google_calendar_id text,
  google_sheet_id text,
  
  crm_type text,
  crm_config jsonb,

  -- WhatsApp Provider Configuration (Evolution, Cloud API, Twilio)
  whatsapp_provider text DEFAULT 'evolution'::text,
  -- Valores possíveis: 'evolution', 'cloud_api', 'twilio'
  
  whatsapp_config jsonb DEFAULT '{}'::jsonb,
  -- Evolution: {"instance_name": "acme-sdr", "api_key_vault_id": "..."}
  -- Cloud API: {"phone_number_id": "123456", "access_token_vault_id": "..."}
  -- Twilio: {"account_sid": "AC...", "auth_token_vault_id": "...", "from_number": "+1..."}

  -- Chatwoot Integration
  chatwoot_inbox_id integer,
  -- ID do inbox no Chatwoot vinculado a este agente

  -- Metadata Adicional
  notes text,
  tags text[],
  custom_fields jsonb,

  -- Constraint: client_id + agent_id deve ser único
  CONSTRAINT unique_client_agent UNIQUE (client_id, agent_id)
);

-- ============================================================================
-- PARTE 2: CRIAR ÍNDICES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_agents_client_id 
  ON public.agents(client_id);

CREATE INDEX IF NOT EXISTS idx_agents_agent_id 
  ON public.agents(agent_id);

CREATE INDEX IF NOT EXISTS idx_agents_composite 
  ON public.agents(client_id, agent_id);

CREATE INDEX IF NOT EXISTS idx_agents_package 
  ON public.agents(package);

CREATE INDEX IF NOT EXISTS idx_agents_is_active 
  ON public.agents(is_active) 
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_agents_rag_namespace 
  ON public.agents(rag_namespace);

CREATE INDEX IF NOT EXISTS idx_agents_chatwoot_inbox 
  ON public.agents(chatwoot_inbox_id) 
  WHERE chatwoot_inbox_id IS NOT NULL;

-- ============================================================================
-- PARTE 3: COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.agents IS 
  'Agentes especializados de cada cliente. Permite múltiplos agentes por cliente (SDR, Suporte, Cobrança, etc).';

COMMENT ON COLUMN public.agents.client_id IS 
  'FK para clients.client_id. Identifica a qual cliente este agente pertence.';

COMMENT ON COLUMN public.agents.agent_id IS 
  'Identificador do agente dentro do cliente. Ex: "sdr", "support", "billing".';

COMMENT ON COLUMN public.agents.system_prompt IS 
  'Prompt de sistema COMPLETO que define persona específica deste agente.';

COMMENT ON COLUMN public.agents.tools_enabled IS 
  'Array JSON com ferramentas específicas deste agente. Diferentes agentes = ferramentas diferentes.';

COMMENT ON COLUMN public.agents.rag_namespace IS 
  'Namespace único no vector store. Formato: "{client_id}/{agent_id}". Ex: "acme-corp/sdr".';

COMMENT ON COLUMN public.agents.whatsapp_provider IS 
  'Provider de WhatsApp: "evolution" (não-oficial), "cloud_api" (Meta oficial), "twilio" (oficial BSP).';

COMMENT ON COLUMN public.agents.chatwoot_inbox_id IS 
  'ID do inbox no Chatwoot vinculado a este agente. Usado para roteamento de mensagens.';

-- ============================================================================
-- PARTE 4: TRIGGER PARA UPDATED_AT
-- ============================================================================

CREATE TRIGGER on_agents_updated 
  BEFORE UPDATE ON public.agents 
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- PARTE 5: ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;

-- Policy exemplo (ajustar conforme seu sistema de auth)
-- CREATE POLICY "Usuários veem apenas agentes do seu cliente"
--   ON public.agents FOR SELECT
--   USING (client_id = (auth.jwt() ->> 'client_id'));

-- ============================================================================
-- PARTE 6: MIGRAÇÃO DE DADOS EXISTENTES
-- ============================================================================

-- Criar agente padrão para cada cliente existente
INSERT INTO public.agents (
  client_id,
  agent_id,
  agent_name,
  package,
  system_prompt,
  llm_provider,
  llm_model,
  llm_config,
  tools_enabled,
  rag_namespace,
  rag_config,
  image_gen_provider,
  image_gen_model,
  image_gen_config,
  buffer_delay,
  rate_limits,
  google_calendar_id,
  google_sheet_id,
  crm_type,
  crm_config,
  notes,
  tags,
  custom_fields
)
SELECT 
  client_id,
  'default' as agent_id,
  'Agente Principal' as agent_name,
  package,
  system_prompt,
  llm_provider,
  llm_model,
  llm_config,
  tools_enabled,
  CASE 
    -- Se rag_namespace já existe, converter para novo formato
    WHEN rag_namespace IS NOT NULL THEN client_id || '/default'
    ELSE client_id || '/default'
  END as rag_namespace,
  rag_config,
  image_gen_provider,
  image_gen_model,
  image_gen_config,
  buffer_delay,
  rate_limits,
  google_calendar_id,
  google_sheet_id,
  crm_type,
  crm_config,
  notes,
  tags,
  custom_fields
FROM public.clients
WHERE NOT EXISTS (
  -- Evitar duplicação se migration já foi executada
  SELECT 1 FROM public.agents 
  WHERE agents.client_id = clients.client_id 
    AND agents.agent_id = 'default'
);

-- ============================================================================
-- PARTE 7: ATUALIZAR TABELAS RELACIONADAS (rag_documents)
-- ============================================================================

-- Adicionar coluna agent_id à tabela rag_documents
ALTER TABLE public.rag_documents 
  ADD COLUMN IF NOT EXISTS agent_id text DEFAULT 'default';

-- Atualizar agent_id nos documentos existentes
UPDATE public.rag_documents 
SET agent_id = 'default'
WHERE agent_id IS NULL;

-- Criar constraint de FK composta
ALTER TABLE public.rag_documents 
  DROP CONSTRAINT IF EXISTS fk_rag_documents_client;

ALTER TABLE public.rag_documents
  ADD CONSTRAINT fk_rag_documents_agent 
  FOREIGN KEY (client_id, agent_id) 
  REFERENCES public.agents(client_id, agent_id) 
  ON DELETE CASCADE;

-- Criar índice composto
CREATE INDEX IF NOT EXISTS idx_rag_documents_client_agent 
  ON public.rag_documents(client_id, agent_id);

-- ============================================================================
-- PARTE 8: ATUALIZAR TABELAS RELACIONADAS (agent_executions)
-- ============================================================================

-- Adicionar coluna agent_id à tabela agent_executions
ALTER TABLE public.agent_executions 
  ADD COLUMN IF NOT EXISTS agent_id text DEFAULT 'default';

-- Atualizar agent_id nas execuções existentes
UPDATE public.agent_executions 
SET agent_id = 'default'
WHERE agent_id IS NULL;

-- Criar índice composto
CREATE INDEX IF NOT EXISTS idx_agent_executions_client_agent 
  ON public.agent_executions(client_id, agent_id);

-- ============================================================================
-- PARTE 9: ATUALIZAR TABELAS RELACIONADAS (channels)
-- ============================================================================

-- Adicionar coluna assigned_agent_id à tabela channels
ALTER TABLE public.channels 
  ADD COLUMN IF NOT EXISTS assigned_agent_id text;

-- Para canais existentes, atribuir ao agente default
UPDATE public.channels 
SET assigned_agent_id = 'default'
WHERE assigned_agent_id IS NULL;

-- Criar índice
CREATE INDEX IF NOT EXISTS idx_channels_assigned_agent 
  ON public.channels(client_id, assigned_agent_id);

-- ============================================================================
-- PARTE 10: ATUALIZAR TABELAS RELACIONADAS (rate_limit_buckets)
-- ============================================================================

-- Adicionar coluna agent_id à tabela rate_limit_buckets
ALTER TABLE public.rate_limit_buckets 
  ADD COLUMN IF NOT EXISTS agent_id text DEFAULT 'default';

-- Atualizar agent_id nos buckets existentes
UPDATE public.rate_limit_buckets 
SET agent_id = 'default'
WHERE agent_id IS NULL;

-- Criar índice composto
CREATE INDEX IF NOT EXISTS idx_rate_limit_buckets_client_agent 
  ON public.rate_limit_buckets(client_id, agent_id);

-- ============================================================================
-- PARTE 11: ATUALIZAR TABELA CLIENTS (REMOVER CAMPOS DUPLICADOS)
-- ============================================================================

-- ⚠️ ATENÇÃO: Apenas executar após confirmar que dados foram migrados!
-- ⚠️ Comentado por segurança. Descomentar após validação.

-- ALTER TABLE public.clients 
--   DROP COLUMN IF EXISTS system_prompt,
--   DROP COLUMN IF EXISTS llm_provider,
--   DROP COLUMN IF EXISTS llm_model,
--   DROP COLUMN IF EXISTS llm_config,
--   DROP COLUMN IF EXISTS tools_enabled,
--   DROP COLUMN IF EXISTS rag_namespace,
--   DROP COLUMN IF EXISTS rag_config,
--   DROP COLUMN IF EXISTS image_gen_provider,
--   DROP COLUMN IF EXISTS image_gen_model,
--   DROP COLUMN IF EXISTS image_gen_config,
--   DROP COLUMN IF EXISTS buffer_delay,
--   DROP COLUMN IF EXISTS google_calendar_id,
--   DROP COLUMN IF EXISTS google_sheet_id,
--   DROP COLUMN IF EXISTS crm_type,
--   DROP COLUMN IF EXISTS crm_config;

-- ⚠️ NOTA: Manter esses campos na tabela clients por enquanto
-- ⚠️ Eles podem ser usados como "defaults" para novos agentes
-- ⚠️ Ou podem ser removidos após período de transição (30 dias)

-- ============================================================================
-- PARTE 12: ADICIONAR CAMPO max_agents À TABELA CLIENTS
-- ============================================================================

ALTER TABLE public.clients 
  ADD COLUMN IF NOT EXISTS max_agents integer DEFAULT 3;

COMMENT ON COLUMN public.clients.max_agents IS 
  'Número máximo de agentes permitidos para este cliente (baseado no plano).';

-- Atualizar clientes existentes baseado no package
UPDATE public.clients 
SET max_agents = CASE 
  WHEN package = 'starter' THEN 1
  WHEN package = 'professional' THEN 3
  WHEN package = 'enterprise' THEN 10
  ELSE 3
END
WHERE max_agents IS NULL;

-- ============================================================================
-- PARTE 13: VERIFICAÇÃO DE INTEGRIDADE
-- ============================================================================

-- Query para validar migration
DO $$
DECLARE
  total_clients integer;
  total_agents integer;
  agents_sem_client integer;
  clients_sem_agent integer;
BEGIN
  SELECT COUNT(*) INTO total_clients FROM public.clients;
  SELECT COUNT(*) INTO total_agents FROM public.agents;
  
  SELECT COUNT(*) INTO agents_sem_client 
  FROM public.agents 
  WHERE client_id NOT IN (SELECT client_id FROM public.clients);
  
  SELECT COUNT(*) INTO clients_sem_agent 
  FROM public.clients 
  WHERE client_id NOT IN (SELECT client_id FROM public.agents);
  
  RAISE NOTICE '============================================';
  RAISE NOTICE 'MIGRATION 001: Verificação de Integridade';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Total de clientes: %', total_clients;
  RAISE NOTICE 'Total de agentes: %', total_agents;
  RAISE NOTICE 'Agentes sem cliente (ERRO): %', agents_sem_client;
  RAISE NOTICE 'Clientes sem agente (AVISO): %', clients_sem_agent;
  RAISE NOTICE '============================================';
  
  IF agents_sem_client > 0 THEN
    RAISE WARNING 'Existem agentes órfãos! Investigar.';
  END IF;
  
  IF total_agents >= total_clients THEN
    RAISE NOTICE '✅ Migration executada com sucesso!';
  ELSE
    RAISE WARNING '⚠️ Alguns clientes podem não ter agentes criados.';
  END IF;
END $$;

-- ============================================================================
-- PARTE 14: QUERIES DE EXEMPLO (PÓS-MIGRATION)
-- ============================================================================

-- Listar todos os agentes de um cliente
-- SELECT * FROM public.agents WHERE client_id = 'acme-corp';

-- Buscar config de um agente específico
-- SELECT system_prompt, tools_enabled, rag_namespace
-- FROM public.agents 
-- WHERE client_id = 'acme-corp' AND agent_id = 'sdr';

-- Contar agentes por cliente
-- SELECT client_id, COUNT(*) as num_agents
-- FROM public.agents 
-- GROUP BY client_id 
-- ORDER BY num_agents DESC;

-- Verificar clientes que excederam max_agents
-- SELECT c.client_id, c.max_agents, COUNT(a.id) as current_agents
-- FROM public.clients c
-- LEFT JOIN public.agents a ON c.client_id = a.client_id
-- GROUP BY c.client_id, c.max_agents
-- HAVING COUNT(a.id) > c.max_agents;

-- ============================================================================
-- FIM DA MIGRATION 001
-- ============================================================================

-- Rollback (se necessário):
-- DROP TABLE IF EXISTS public.agents CASCADE;
-- ALTER TABLE public.rag_documents DROP COLUMN IF EXISTS agent_id;
-- ALTER TABLE public.agent_executions DROP COLUMN IF EXISTS agent_id;
-- ALTER TABLE public.channels DROP COLUMN IF EXISTS assigned_agent_id;
-- ALTER TABLE public.rate_limit_buckets DROP COLUMN IF EXISTS agent_id;
-- ALTER TABLE public.clients DROP COLUMN IF EXISTS max_agents;

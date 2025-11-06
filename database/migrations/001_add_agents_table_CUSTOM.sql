-- ============================================================================
-- MIGRATION 001: Adicionar Tabela AGENTS (Múltiplos Agentes por Cliente)
-- Data: 06/11/2025
-- Autor: Victor Castro + GitHub Copilot
-- Descrição: Reestrutura sistema para suportar N agentes por cliente
-- VERSÃO: Customizada para estrutura real do projeto
-- ============================================================================

-- ============================================================================
-- PARTE 1: CRIAR TABELA AGENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.agents (
  -- Identificação Única
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Relacionamento com Cliente (FK)
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  
  -- Identificador do Agente (único dentro do cliente)
  agent_id text NOT NULL, -- Ex: "sdr", "support", "billing"
  agent_name text NOT NULL, -- Nome amigável: "Agente SDR", "Suporte Técnico"
  
  is_active boolean NOT NULL DEFAULT true,
  
  -- Configuração do Agente (Personalidade)
  template_id text, -- FK para agent_templates.template_id (será populado na Migration 002)
  system_prompt text NOT NULL, -- Prompt COMPLETO específico deste agente
  
  -- Configuração de LLM (compatível com sua estrutura)
  llm_model text NOT NULL DEFAULT 'gpt-4o-mini',
  
  -- Tools Disponíveis (específicas por agente)
  tools_enabled jsonb NOT NULL DEFAULT '["rag"]'::jsonb,
  
  -- Configuração RAG (namespace isolado por agente)
  rag_namespace text NOT NULL UNIQUE, -- Ex: "acme-corp/sdr"
  
  -- Configurações de Canal (compatível com sua estrutura)
  chatwoot_host text,
  chatwoot_token text,
  chatwoot_inbox_id integer, -- NOVO: Para vincular inbox específico
  
  google_calendar_id text,
  google_sheet_id text,
  
  evolution_instance_id text, -- Compatível com seu campo
  
  -- WhatsApp Provider (NOVO: Suporte multi-provider)
  whatsapp_provider text DEFAULT 'evolution', -- 'evolution', 'cloud_api', 'twilio'
  whatsapp_config jsonb DEFAULT '{}'::jsonb,
  
  -- Tool Credentials (compatível com sua estrutura)
  tool_credentials jsonb,
  
  -- Usage Limits (compatível com sua estrutura)
  usage_limits jsonb,
  
  -- Configuração Operacional
  buffer_delay integer NOT NULL DEFAULT 1,
  
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

CREATE INDEX IF NOT EXISTS idx_agents_template_id 
  ON public.agents(template_id);

CREATE INDEX IF NOT EXISTS idx_agents_is_active 
  ON public.agents(is_active) 
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_agents_rag_namespace 
  ON public.agents(rag_namespace);

CREATE INDEX IF NOT EXISTS idx_agents_chatwoot_inbox 
  ON public.agents(chatwoot_inbox_id);

-- ============================================================================
-- PARTE 3: COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.agents IS 
  'Agentes especializados de cada cliente. Permite múltiplos agentes por cliente.';

COMMENT ON COLUMN public.agents.client_id IS 
  'FK para clients.client_id. Identifica a qual cliente este agente pertence.';

COMMENT ON COLUMN public.agents.agent_id IS 
  'Identificador do agente dentro do cliente. Ex: "sdr", "support", "billing".';

COMMENT ON COLUMN public.agents.template_id IS 
  'FK para agent_templates.template_id. Define o tipo/categoria do agente no marketplace.';

COMMENT ON COLUMN public.agents.system_prompt IS 
  'Prompt de sistema COMPLETO que define persona específica deste agente.';

COMMENT ON COLUMN public.agents.tools_enabled IS 
  'Array JSON com ferramentas específicas deste agente.';

COMMENT ON COLUMN public.agents.rag_namespace IS 
  'Namespace único no vector store. Formato: "{client_id}/{agent_id}".';

COMMENT ON COLUMN public.agents.chatwoot_inbox_id IS 
  'ID do inbox no Chatwoot vinculado a este agente. Permite roteamento automático.';

COMMENT ON COLUMN public.agents.whatsapp_provider IS 
  'Provider do WhatsApp: evolution (não-oficial), cloud_api (Meta oficial), twilio (BSP oficial).';

-- ============================================================================
-- PARTE 4: TRIGGER PARA UPDATED_AT
-- ============================================================================

-- Reutilizar função handle_updated_at que já existe
CREATE TRIGGER on_agents_updated 
  BEFORE UPDATE ON public.agents 
  FOR EACH ROW 
  EXECUTE FUNCTION handle_updated_at();

-- ============================================================================
-- PARTE 5: ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;

-- Policy exemplo (ajustar conforme seu auth)
-- CREATE POLICY "Usuários veem apenas agentes do seu cliente"
--   ON public.agents FOR SELECT
--   USING (client_id = (auth.jwt() ->> 'client_id'));

-- ============================================================================
-- PARTE 6: MIGRAÇÃO DE DADOS EXISTENTES
-- ============================================================================

DO $$
DECLARE
  v_client_count integer;
  v_agents_created integer := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'MIGRATION 001: Migrando dados de clients → agents';
  RAISE NOTICE '========================================';
  
  -- Contar clientes existentes
  SELECT COUNT(*) INTO v_client_count FROM public.clients;
  RAISE NOTICE 'Clientes encontrados: %', v_client_count;
  
  IF v_client_count = 0 THEN
    RAISE NOTICE 'Nenhum cliente para migrar. Tabela agents criada vazia.';
    RETURN;
  END IF;
  
  -- Criar agente 'default' para cada cliente existente
  INSERT INTO public.agents (
    client_id,
    agent_id,
    agent_name,
    template_id,
    system_prompt,
    llm_model,
    tools_enabled,
    rag_namespace,
    chatwoot_host,
    chatwoot_token,
    google_calendar_id,
    google_sheet_id,
    evolution_instance_id,
    tool_credentials,
    usage_limits,
    buffer_delay,
    is_active
  )
  SELECT 
    client_id,
    'default' as agent_id, -- Agente padrão
    'Agente Principal' as agent_name,
    NULL as template_id, -- Será populado na Migration 002 baseado no package
    COALESCE(system_prompt, 'Você é um assistente virtual.') as system_prompt,
    COALESCE(llm_model, 'gpt-4o-mini') as llm_model,
    COALESCE(tools_enabled, '["rag"]'::jsonb) as tools_enabled,
    client_id || '/default' as rag_namespace, -- Novo formato
    chatwoot_host,
    chatwoot_token,
    google_calendar_id,
    google_sheet_id,
    evolution_instance_id,
    tool_credentials,
    usage_limits,
    COALESCE(buffer_delay, 1) as buffer_delay,
    is_active
  FROM public.clients
  WHERE is_active = true;
  
  GET DIAGNOSTICS v_agents_created = ROW_COUNT;
  
  RAISE NOTICE 'Agentes criados: %', v_agents_created;
  RAISE NOTICE 'Formato rag_namespace: client_id/default';
  
END $$;

-- ============================================================================
-- PARTE 7: ATUALIZAR TABELAS RELACIONADAS (Se existirem)
-- ============================================================================

-- Nota: Essas tabelas podem não existir ainda no seu projeto.
-- Os comandos usam IF EXISTS para não dar erro.

-- 7.1: Tabela rag_documents (se existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'rag_documents'
  ) THEN
    -- Adicionar coluna agent_id
    ALTER TABLE public.rag_documents 
      ADD COLUMN IF NOT EXISTS agent_id text;
    
    -- Criar índice
    CREATE INDEX IF NOT EXISTS idx_rag_documents_agent_id 
      ON public.rag_documents(agent_id);
    
    -- Atualizar documentos existentes (mapear para agente 'default')
    UPDATE public.rag_documents 
    SET agent_id = 'default' 
    WHERE agent_id IS NULL;
    
    RAISE NOTICE 'Tabela rag_documents atualizada com agent_id';
  ELSE
    RAISE NOTICE 'Tabela rag_documents não existe (ok, será criada depois)';
  END IF;
END $$;

-- 7.2: Tabela agent_executions (se existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'agent_executions'
  ) THEN
    ALTER TABLE public.agent_executions 
      ADD COLUMN IF NOT EXISTS agent_id text;
    
    CREATE INDEX IF NOT EXISTS idx_agent_executions_agent_id 
      ON public.agent_executions(agent_id);
    
    UPDATE public.agent_executions 
    SET agent_id = 'default' 
    WHERE agent_id IS NULL;
    
    RAISE NOTICE 'Tabela agent_executions atualizada com agent_id';
  ELSE
    RAISE NOTICE 'Tabela agent_executions não existe (ok, será criada depois)';
  END IF;
END $$;

-- 7.3: Tabela channels (se existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'channels'
  ) THEN
    ALTER TABLE public.channels 
      ADD COLUMN IF NOT EXISTS assigned_agent_id text;
    
    CREATE INDEX IF NOT EXISTS idx_channels_assigned_agent 
      ON public.channels(assigned_agent_id);
    
    RAISE NOTICE 'Tabela channels atualizada com assigned_agent_id';
  ELSE
    RAISE NOTICE 'Tabela channels não existe (ok)';
  END IF;
END $$;

-- ============================================================================
-- PARTE 8: ADICIONAR CAMPO MAX_AGENTS EM CLIENTS
-- ============================================================================

ALTER TABLE public.clients 
  ADD COLUMN IF NOT EXISTS max_agents integer DEFAULT 1;

COMMENT ON COLUMN public.clients.max_agents IS 
  'Número máximo de agentes permitidos para este cliente (baseado na assinatura).';

-- Manter padrão 1 para todos os clientes (será atualizado via subscriptions na Migration 002)
UPDATE public.clients
SET max_agents = 1
WHERE max_agents IS NULL;

-- ============================================================================
-- PARTE 9: VERIFICAÇÃO DE INTEGRIDADE
-- ============================================================================

DO $$
DECLARE
  v_total_clients integer;
  v_total_agents integer;
  v_orphaned_agents integer;
  v_clients_without_agents integer;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICAÇÃO DE INTEGRIDADE';
  RAISE NOTICE '========================================';
  
  -- Contar clientes
  SELECT COUNT(*) INTO v_total_clients FROM public.clients;
  RAISE NOTICE 'Total de clientes: %', v_total_clients;
  
  -- Contar agentes
  SELECT COUNT(*) INTO v_total_agents FROM public.agents;
  RAISE NOTICE 'Total de agentes: %', v_total_agents;
  
  -- Verificar agentes órfãos
  SELECT COUNT(*) INTO v_orphaned_agents
  FROM public.agents a
  WHERE NOT EXISTS (
    SELECT 1 FROM public.clients c WHERE c.client_id = a.client_id
  );
  
  IF v_orphaned_agents > 0 THEN
    RAISE WARNING 'ATENÇÃO: % agentes órfãos encontrados!', v_orphaned_agents;
  ELSE
    RAISE NOTICE 'Nenhum agente órfão (OK)';
  END IF;
  
  -- Verificar clientes sem agentes
  SELECT COUNT(*) INTO v_clients_without_agents
  FROM public.clients c
  WHERE NOT EXISTS (
    SELECT 1 FROM public.agents a WHERE a.client_id = c.client_id
  );
  
  IF v_clients_without_agents > 0 THEN
    RAISE WARNING 'ATENÇÃO: % clientes sem agentes!', v_clients_without_agents;
  ELSE
    RAISE NOTICE 'Todos os clientes têm pelo menos 1 agente (OK)';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '✅ Migration 001 completa!';
  RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- PARTE 10: QUERIES DE EXEMPLO (Comentadas - para referência)
-- ============================================================================

-- Listar todos os agentes de um cliente
-- SELECT * FROM public.agents WHERE client_id = 'clinica_sorriso_001';

-- Criar novo agente para um cliente
-- INSERT INTO public.agents (
--   client_id, agent_id, agent_name, template_id, system_prompt, rag_namespace
-- ) VALUES (
--   'clinica_sorriso_001', 
--   'sdr', 
--   'Agente SDR', 
--   'sdr-starter',  -- template_id do marketplace
--   'Você é um SDR especializado...', 
--   'clinica_sorriso_001/sdr'
-- );

-- Buscar config de um agente específico
-- SELECT * FROM public.agents 
-- WHERE client_id = 'clinica_sorriso_001' AND agent_id = 'sdr';

-- Contar agentes por cliente
-- SELECT client_id, COUNT(*) as agent_count 
-- FROM public.agents 
-- GROUP BY client_id;

-- Verificar se cliente excedeu max_agents
-- SELECT 
--   c.client_id,
--   c.max_agents,
--   COUNT(a.id) as current_agents,
--   (COUNT(a.id) >= c.max_agents) as at_limit
-- FROM public.clients c
-- LEFT JOIN public.agents a ON a.client_id = c.client_id
-- GROUP BY c.client_id, c.max_agents;

-- ============================================================================
-- ROLLBACK INSTRUCTIONS (Usar apenas se precisar desfazer)
-- ============================================================================

-- ATENÇÃO: Isso apagará a tabela agents e todas as alterações!
-- Só execute se precisar desfazer a migration.

-- DROP TABLE IF EXISTS public.agents CASCADE;
-- ALTER TABLE public.clients DROP COLUMN IF EXISTS max_agents;
-- ALTER TABLE public.rag_documents DROP COLUMN IF EXISTS agent_id;
-- ALTER TABLE public.agent_executions DROP COLUMN IF EXISTS agent_id;
-- ALTER TABLE public.channels DROP COLUMN IF EXISTS assigned_agent_id;

-- ============================================================================
-- FIM DA MIGRATION 001
-- ============================================================================

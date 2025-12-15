-- Migration 001 - VERSÃO SIMPLIFICADA (apenas tabela + índices básicos)

-- Drop table if exists (para garantir que criamos do zero)
DROP TABLE IF EXISTS public.agents CASCADE;

CREATE TABLE public.agents (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  agent_id text NOT NULL,
  agent_name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  
  template_id text,
  system_prompt text NOT NULL,
  llm_model text NOT NULL DEFAULT 'gpt-4o-mini',
  tools_enabled jsonb NOT NULL DEFAULT '["rag"]'::jsonb,
  rag_namespace text NOT NULL UNIQUE,
  
  chatwoot_host text,
  chatwoot_token text,
  chatwoot_inbox_id integer,
  google_calendar_id text,
  google_sheet_id text,
  evolution_instance_id text,
  
  whatsapp_provider text DEFAULT 'evolution',
  whatsapp_config jsonb DEFAULT '{}'::jsonb,
  tool_credentials jsonb,
  usage_limits jsonb,
  buffer_delay integer NOT NULL DEFAULT 1,
  
  notes text,
  tags text[],
  custom_fields jsonb,
  
  CONSTRAINT unique_client_agent UNIQUE (client_id, agent_id)
);

-- Índices básicos
CREATE INDEX IF NOT EXISTS idx_agents_client_id ON public.agents(client_id);
CREATE INDEX IF NOT EXISTS idx_agents_agent_id ON public.agents(agent_id);
CREATE INDEX IF NOT EXISTS idx_agents_rag_namespace ON public.agents(rag_namespace);

-- Adicionar campo max_agents na tabela clients
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS max_agents integer DEFAULT 1;

-- Migrar dados existentes
INSERT INTO public.agents (
  client_id, agent_id, agent_name, template_id, system_prompt, llm_model, 
  tools_enabled, rag_namespace, is_active, chatwoot_host, chatwoot_token,
  google_calendar_id, google_sheet_id, evolution_instance_id, 
  tool_credentials, usage_limits, buffer_delay
)
SELECT 
  client_id,
  'default' as agent_id,
  'Agente Principal' as agent_name,
  package as template_id, -- Mapeia package → template_id
  COALESCE(system_prompt, 'Você é um assistente virtual.') as system_prompt,
  COALESCE(llm_model, 'gpt-4o-mini') as llm_model,
  COALESCE(tools_enabled, '["rag"]'::jsonb) as tools_enabled,
  client_id || '/default' as rag_namespace,
  is_active,
  chatwoot_host,
  chatwoot_token,
  google_calendar_id,
  google_sheet_id,
  evolution_instance_id,
  tool_credentials,
  usage_limits,
  COALESCE(buffer_delay, 1) as buffer_delay
FROM public.clients
WHERE is_active = true
ON CONFLICT (client_id, agent_id) DO NOTHING;

-- Verificação
SELECT 
  'Tabela agents criada!' as status,
  COUNT(*) as total_agentes
FROM public.agents;

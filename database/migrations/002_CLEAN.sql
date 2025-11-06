-- ============================================================================
-- MIGRATION 002: Marketplace (VERSÃO LIMPA)
-- ============================================================================

-- PARTE 1: Criar tabela de templates
CREATE TABLE IF NOT EXISTS public.agent_templates (
  template_id text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  template_name text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  
  monthly_price decimal(10,2) NOT NULL,
  infrastructure_cost_usd decimal(10,4) DEFAULT 1.38,
  support_hours_included integer DEFAULT 0,
  hourly_rate_usd decimal(10,2) DEFAULT 46.88,
  
  default_system_prompt text NOT NULL,
  default_llm_model text NOT NULL DEFAULT 'gpt-4o-mini',
  
  tools_enabled jsonb NOT NULL DEFAULT '["rag"]'::jsonb,
  usage_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  
  is_active boolean NOT NULL DEFAULT true
);

-- PARTE 2: Inserir 4 templates
INSERT INTO public.agent_templates (
  template_id, template_name, description, category, monthly_price,
  infrastructure_cost_usd, support_hours_included, default_system_prompt
) VALUES
('sdr-starter', 'SDR Starter', 'Agente SDR básico', 'sales', 697.00, 
  1.38, 0, 'Você é um SDR especializado...'),
('sdr-pro', 'SDR Pro', 'Agente SDR completo', 'sales', 1297.00, 
  1.38, 4, 'Você é um SDR experiente...'),
('support-basic', 'Suporte Básico', 'Atendimento automático', 'support', 497.00, 
  1.38, 0, 'Você é um assistente de suporte...'),
('support-premium', 'Suporte Premium', 'Atendimento multi-canal', 'support', 997.00, 
  1.38, 2, 'Você é um especialista em suporte...')
ON CONFLICT (template_id) DO NOTHING;

-- PARTE 3: Atualizar template_id dos agentes existentes
-- Mapear package antigo → novo template_id
UPDATE public.agents
SET template_id = CASE
  WHEN template_id IN ('SDR', 'sdr') THEN 'sdr-starter'
  WHEN template_id IN ('Support', 'support') THEN 'support-basic'
  WHEN template_id IN ('Pro', 'pro', 'Enterprise', 'enterprise') THEN 'sdr-pro'
  ELSE 'sdr-starter'  -- Fallback
END
WHERE template_id IS NOT NULL;

-- PARTE 4: Adicionar FK (agora os template_id são válidos!)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_agents_template'
  ) THEN
    ALTER TABLE public.agents
      ADD CONSTRAINT fk_agents_template
      FOREIGN KEY (template_id) 
      REFERENCES public.agent_templates(template_id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- PARTE 5: Criar tabela de assinaturas
CREATE TABLE IF NOT EXISTS public.client_subscriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  agent_id text NOT NULL,
  template_id text NOT NULL REFERENCES public.agent_templates(template_id),
  
  template_snapshot jsonb NOT NULL,
  status text NOT NULL DEFAULT 'active',
  
  monthly_price decimal(10,2) NOT NULL,
  billing_cycle text NOT NULL DEFAULT 'monthly',
  
  subscription_start_date timestamptz,
  next_billing_date timestamptz,
  
  current_usage jsonb DEFAULT '{}'::jsonb,
  
  FOREIGN KEY (client_id, agent_id) REFERENCES public.agents(client_id, agent_id) ON DELETE CASCADE,
  CONSTRAINT unique_client_agent_subscription UNIQUE (client_id, agent_id)
);

-- PARTE 6: Criar assinaturas para agentes existentes
INSERT INTO public.client_subscriptions (
  client_id, agent_id, template_id, template_snapshot, status,
  subscription_start_date, monthly_price
)
SELECT 
  a.client_id,
  a.agent_id,
  a.template_id,
  row_to_json(t)::jsonb,
  'active',
  a.created_at,
  t.monthly_price
FROM public.agents a
JOIN public.agent_templates t ON a.template_id = t.template_id
WHERE a.is_active = true
ON CONFLICT (client_id, agent_id) DO NOTHING;

-- PARTE 7: View de lucratividade
CREATE OR REPLACE VIEW v_template_profitability AS
SELECT 
  t.template_id,
  t.template_name,
  t.monthly_price / 5.33 as monthly_price_usd,
  t.infrastructure_cost_usd,
  t.support_hours_included,
  t.hourly_rate_usd,
  (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd)) as total_cost_usd,
  ((t.monthly_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd))) as profit_per_client_usd,
  ROUND(
    (((t.monthly_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd))) / 
    (t.monthly_price / 5.33)) * 100, 
    2
  ) as profit_margin_percentage,
  COUNT(s.id) FILTER (WHERE s.status = 'active') as active_subscriptions,
  SUM(s.monthly_price / 5.33) FILTER (WHERE s.status = 'active') as total_mrr_usd
FROM public.agent_templates t
LEFT JOIN public.client_subscriptions s ON t.template_id = s.template_id
GROUP BY 
  t.template_id, t.template_name, t.monthly_price,
  t.infrastructure_cost_usd, t.support_hours_included, t.hourly_rate_usd;

-- PARTE 8: Verificação final
SELECT 
  'Migration 002 completa!' as status,
  (SELECT COUNT(*) FROM public.agent_templates) as templates_criados,
  (SELECT COUNT(*) FROM public.client_subscriptions) as assinaturas_criadas,
  (SELECT COUNT(*) FROM public.agents WHERE template_id IS NOT NULL) as agentes_com_template;

-- FIM

-- ============================================================================
-- MIGRATION 002: Sistema de Marketplace Multi-Agente (FLEXÍVEL)
-- Data: 06/11/2025
-- Autor: Victor Castro + GitHub Copilot
-- Descrição: Tabelas para marketplace de agentes com MÁXIMA FLEXIBILIDADE
-- ============================================================================

-- ============================================================================
-- PARTE 1: AGENT TEMPLATES (Catálogo do Marketplace)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.agent_templates (
  -- Identificação
  template_id text PRIMARY KEY, -- Ex: "sdr-starter", "support-pro"
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Info Básica
  template_name text NOT NULL, -- Nome amigável: "SDR Starter"
  description text NOT NULL, -- Descrição de venda
  category text NOT NULL, -- "sales", "support", "recruitment", etc.
  
  -- FLEXIBILIDADE: Versionamento (permite mudanças sem quebrar assinaturas)
  version integer NOT NULL DEFAULT 1,
  is_active boolean NOT NULL DEFAULT true,
  is_featured boolean NOT NULL DEFAULT false,
  
  -- FLEXIBILIDADE: A/B Testing
  variant text, -- 'A', 'B', 'control', null
  variant_weight decimal(3,2), -- Peso para distribuição (0.50 = 50%)
  
  -- Pricing (EDITÁVEL a qualquer momento)
  monthly_price decimal(10,2) NOT NULL,
  setup_fee decimal(10,2) DEFAULT 0,
  
  -- FLEXIBILIDADE: Preços alternativos
  annual_price decimal(10,2), -- Preço anual (com desconto)
  quarterly_price decimal(10,2), -- Preço trimestral
  
  -- Custos Operacionais (para cálculo de margem)
  infrastructure_cost_usd decimal(10,4) DEFAULT 1.38, -- Custo infra/cliente/mês (Supabase + LLM + etc)
  support_hours_included integer DEFAULT 0, -- Horas de suporte humano incluídas/mês
  hourly_rate_usd decimal(10,2) DEFAULT 46.88, -- R$250/h ÷ 5.33 = $46.88 (para cálculo de margem)
  
  -- FLEXIBILIDADE: Histórico de preços (nunca perca track)
  price_history jsonb DEFAULT '[]'::jsonb,
  -- Ex: [{"date": "2025-11-06", "old_price": 497, "new_price": 697, "reason": "teste conversão"}]
  
  -- Configuração Técnica do Agente
  default_system_prompt text NOT NULL,
  default_llm_model text NOT NULL DEFAULT 'gpt-4o-mini',
  
  -- Tools e Features (EDITÁVEL - Array)
  tools_enabled jsonb NOT NULL DEFAULT '["rag"]'::jsonb,
  features text[] NOT NULL DEFAULT ARRAY['rag'], -- Lista legível
  
  -- FLEXIBILIDADE: Features premium (add-ons inclusos)
  included_addons text[] DEFAULT ARRAY[]::text[],
  -- Ex: ['transcription_500min', 'calendar_integration', 'whatsapp_bot']
  
  -- Usage Limits (EDITÁVEL - JSONB flexível)
  usage_limits jsonb NOT NULL DEFAULT '{
    "messages_per_month": 5000,
    "transcription_minutes": 120,
    "image_generations": 50,
    "rag_documents": 100,
    "rag_queries_per_month": 1000
  }'::jsonb,
  
  -- FLEXIBILIDADE: Limites soft vs hard
  soft_limits jsonb DEFAULT '{}'::jsonb, -- Avisos antes de bloquear
  overage_pricing jsonb DEFAULT '{}'::jsonb, -- Preço por uso excedente
  -- Ex: {"messages": 0.01, "transcription_per_minute": 0.02}
  
  -- Configurações de Canal (defaults)
  default_channels text[] DEFAULT ARRAY['whatsapp'],
  channel_config jsonb DEFAULT '{}'::jsonb,
  
  -- FLEXIBILIDADE: Metadata customizável (sem limites)
  metadata jsonb DEFAULT '{}'::jsonb,
  -- Use para QUALQUER info extra: tags, ícones, cores, demos, etc.
  
  -- Marketing e Vendas
  tagline text, -- Frase de impacto: "Seu SDR que nunca dorme"
  benefits text[], -- Lista de benefícios
  use_cases text[], -- Casos de uso: ["Prospecção B2B", "Follow-up automático"]
  
  -- FLEXIBILIDADE: Experiment tracking
  experiment_id text, -- ID do experimento (ex: "pricing_test_nov_2025")
  experiment_data jsonb DEFAULT '{}'::jsonb,
  
  -- SEO e Discovery
  slug text UNIQUE, -- URL amigável: "sdr-starter"
  search_keywords text[], -- Para busca interna
  
  -- Imagens e Assets
  icon_url text,
  cover_image_url text,
  demo_video_url text,
  
  -- Stats (atualizado por triggers)
  active_subscriptions integer DEFAULT 0,
  total_revenue decimal(12,2) DEFAULT 0,
  conversion_rate decimal(5,2), -- % de trials que viraram pagos
  
  -- Constraints
  CONSTRAINT valid_variant_weight CHECK (variant_weight IS NULL OR (variant_weight >= 0 AND variant_weight <= 1))
);

-- ============================================================================
-- PARTE 2: CLIENT SUBSCRIPTIONS (Assinaturas Ativas)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.client_subscriptions (
  -- Identificação
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Relacionamentos
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  agent_id text NOT NULL, -- FK composta com client_id
  template_id text NOT NULL REFERENCES public.agent_templates(template_id),
  
  -- FLEXIBILIDADE: Snapshot do template (para auditoria)
  template_snapshot jsonb NOT NULL,
  -- Armazena o estado completo do template no momento da contratação
  -- Assim, mudanças no template não afetam assinaturas antigas
  
  -- Status da Assinatura
  status text NOT NULL DEFAULT 'trial', 
  -- 'trial', 'active', 'paused', 'cancelled', 'expired'
  
  -- FLEXIBILIDADE: Datas flexíveis
  trial_start_date timestamptz,
  trial_end_date timestamptz,
  subscription_start_date timestamptz,
  subscription_end_date timestamptz, -- Para contratos com prazo
  next_billing_date timestamptz,
  cancelled_at timestamptz,
  
  -- Pricing (pode divergir do template)
  monthly_price decimal(10,2) NOT NULL, -- Pode ter desconto custom
  billing_cycle text NOT NULL DEFAULT 'monthly', -- 'monthly', 'quarterly', 'annual'
  
  -- FLEXIBILIDADE: Descontos e promoções
  discount_percentage decimal(5,2) DEFAULT 0,
  discount_reason text, -- "Black Friday", "Cliente VIP", etc.
  promotional_code text,
  
  -- FLEXIBILIDADE: Customizações do cliente
  custom_limits jsonb, -- Override dos limites do template
  custom_features text[], -- Features extras negociadas
  custom_config jsonb DEFAULT '{}'::jsonb,
  
  -- Uso atual (atualizado em tempo real)
  current_usage jsonb DEFAULT '{
    "messages_this_month": 0,
    "transcription_minutes_this_month": 0,
    "images_this_month": 0,
    "rag_queries_this_month": 0
  }'::jsonb,
  
  -- Billing
  total_paid decimal(12,2) DEFAULT 0,
  last_payment_date timestamptz,
  last_payment_amount decimal(10,2),
  payment_method text, -- 'credit_card', 'pix', 'boleto', 'wire_transfer'
  
  -- FLEXIBILIDADE: Metadata da assinatura
  subscription_metadata jsonb DEFAULT '{}'::jsonb,
  -- Ex: {"acquisition_channel": "webinar", "sales_rep": "João", "referral": "client_xyz"}
  
  -- Gestão de Relacionamento
  account_manager_id text, -- Quem cuida deste cliente
  support_tier text DEFAULT 'self-service', -- 'self-service', 'standard', 'premium'
  
  -- Notes internas
  internal_notes text,
  
  -- FK composta para agents
  FOREIGN KEY (client_id, agent_id) REFERENCES public.agents(client_id, agent_id) ON DELETE CASCADE,
  
  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('trial', 'active', 'paused', 'cancelled', 'expired', 'pending_payment', 'suspended')),
  CONSTRAINT valid_billing_cycle CHECK (billing_cycle IN ('monthly', 'quarterly', 'annual', 'custom')),
  CONSTRAINT unique_client_agent_subscription UNIQUE (client_id, agent_id)
);

-- ============================================================================
-- PARTE 3: FEATURE PRICING (Add-ons e Consumo)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feature_pricing (
  -- Identificação
  feature_id text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Info
  feature_name text NOT NULL,
  description text,
  category text NOT NULL, -- "api_usage", "storage", "integration", "support"
  
  is_active boolean NOT NULL DEFAULT true,
  
  -- Pricing (EDITÁVEL)
  pricing_model text NOT NULL, -- 'per_unit', 'tiered', 'flat', 'free'
  unit_price decimal(10,4), -- Preço unitário (ex: R$ 0.02/minuto)
  unit_name text, -- "minuto", "mensagem", "documento", "usuário"
  
  -- FLEXIBILIDADE: Pricing tiers (para volume)
  pricing_tiers jsonb,
  -- Ex: [
  --   {"from": 0, "to": 1000, "price": 0.02},
  --   {"from": 1001, "to": 5000, "price": 0.015},
  --   {"from": 5001, "to": null, "price": 0.01}
  -- ]
  
  -- Metadata
  metadata jsonb DEFAULT '{}'::jsonb,
  
  -- Marketing
  display_name text, -- Nome para exibir: "Transcrição de Áudio"
  icon_url text
);

-- ============================================================================
-- PARTE 4: CLIENT USAGE (Tracking Mensal para Billing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.client_usage (
  -- Identificação
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- Período
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  agent_id text NOT NULL,
  month date NOT NULL, -- Primeiro dia do mês: '2025-11-01'
  
  -- Usage tracking
  usage_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- Ex: {
  --   "messages": 3450,
  --   "transcription_minutes": 87,
  --   "images": 12,
  --   "rag_queries": 890,
  --   "api_calls": 5600
  -- }
  
  -- Calculated costs
  base_cost decimal(10,2) NOT NULL DEFAULT 0, -- Custo fixo (mensalidade)
  overage_cost decimal(10,2) NOT NULL DEFAULT 0, -- Custo de excedente
  addon_cost decimal(10,2) NOT NULL DEFAULT 0, -- Custo de add-ons
  total_cost decimal(10,2) NOT NULL DEFAULT 0,
  
  -- Billing
  invoice_id text, -- Referência para sistema de billing externo
  paid boolean NOT NULL DEFAULT false,
  paid_at timestamptz,
  
  -- Metadata
  notes jsonb DEFAULT '{}'::jsonb,
  
  -- FK composta
  FOREIGN KEY (client_id, agent_id) REFERENCES public.agents(client_id, agent_id) ON DELETE CASCADE,
  
  -- Constraint: uma linha por cliente/agente/mês
  CONSTRAINT unique_client_agent_month UNIQUE (client_id, agent_id, month)
);

-- ============================================================================
-- PARTE 5: PRICING EXPERIMENTS (A/B Testing de Preços)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pricing_experiments (
  experiment_id text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  ended_at timestamptz,
  
  name text NOT NULL,
  description text,
  hypothesis text, -- "Aumentar preço de R$ 497 para R$ 697 não reduz conversão"
  
  status text NOT NULL DEFAULT 'draft', -- 'draft', 'running', 'paused', 'completed'
  
  -- Variants
  variants jsonb NOT NULL,
  -- Ex: [
  --   {"variant": "control", "price": 497, "weight": 0.5},
  --   {"variant": "test", "price": 697, "weight": 0.5}
  -- ]
  
  -- Resultados (atualizado automaticamente)
  results jsonb DEFAULT '{}'::jsonb,
  -- Ex: {
  --   "control": {"views": 100, "trials": 30, "conversions": 12, "revenue": 5964},
  --   "test": {"views": 100, "trials": 25, "conversions": 10, "revenue": 6970}
  -- }
  
  winner text, -- 'control', 'test', ou null
  confidence_level decimal(5,2), -- 95%, 99%, etc.
  
  metadata jsonb DEFAULT '{}'::jsonb
);

-- ============================================================================
-- PARTE 6: SUBSCRIPTION EVENTS (Audit Log)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subscription_events (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  
  subscription_id uuid NOT NULL REFERENCES public.client_subscriptions(id) ON DELETE CASCADE,
  
  event_type text NOT NULL,
  -- 'created', 'activated', 'paused', 'resumed', 'cancelled', 
  -- 'renewed', 'upgraded', 'downgraded', 'price_changed', 'limit_changed'
  
  event_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- Armazena o estado antes/depois da mudança
  
  triggered_by text, -- 'system', 'user', 'admin', user_id
  notes text
);

-- ============================================================================
-- PARTE 7: ÍNDICES (Performance)
-- ============================================================================

-- agent_templates
CREATE INDEX idx_agent_templates_category ON public.agent_templates(category);
CREATE INDEX idx_agent_templates_is_active ON public.agent_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_agent_templates_variant ON public.agent_templates(variant) WHERE variant IS NOT NULL;
CREATE INDEX idx_agent_templates_experiment ON public.agent_templates(experiment_id) WHERE experiment_id IS NOT NULL;
CREATE INDEX idx_agent_templates_slug ON public.agent_templates(slug);

-- client_subscriptions
CREATE INDEX idx_subscriptions_client_id ON public.client_subscriptions(client_id);
CREATE INDEX idx_subscriptions_agent_id ON public.client_subscriptions(agent_id);
CREATE INDEX idx_subscriptions_template_id ON public.client_subscriptions(template_id);
CREATE INDEX idx_subscriptions_status ON public.client_subscriptions(status);
CREATE INDEX idx_subscriptions_client_agent ON public.client_subscriptions(client_id, agent_id);
CREATE INDEX idx_subscriptions_next_billing ON public.client_subscriptions(next_billing_date) 
  WHERE status = 'active';
CREATE INDEX idx_subscriptions_trial_end ON public.client_subscriptions(trial_end_date)
  WHERE status = 'trial';

-- client_usage
CREATE INDEX idx_usage_client_agent ON public.client_usage(client_id, agent_id);
CREATE INDEX idx_usage_month ON public.client_usage(month);
CREATE INDEX idx_usage_unpaid ON public.client_usage(paid) WHERE paid = false;

-- subscription_events
CREATE INDEX idx_events_subscription_id ON public.subscription_events(subscription_id);
CREATE INDEX idx_events_type ON public.subscription_events(event_type);
CREATE INDEX idx_events_created_at ON public.subscription_events(created_at);

-- ============================================================================
-- PARTE 8: TRIGGERS
-- ============================================================================

-- Trigger para updated_at
CREATE TRIGGER on_agent_templates_updated 
  BEFORE UPDATE ON public.agent_templates 
  FOR EACH ROW 
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_client_subscriptions_updated 
  BEFORE UPDATE ON public.client_subscriptions 
  FOR EACH ROW 
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_feature_pricing_updated 
  BEFORE UPDATE ON public.feature_pricing 
  FOR EACH ROW 
  EXECUTE FUNCTION handle_updated_at();

-- Trigger para histórico de preços
CREATE OR REPLACE FUNCTION track_price_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.monthly_price IS DISTINCT FROM NEW.monthly_price THEN
    NEW.price_history = COALESCE(NEW.price_history, '[]'::jsonb) || 
      jsonb_build_object(
        'date', now(),
        'old_price', OLD.monthly_price,
        'new_price', NEW.monthly_price,
        'changed_by', current_user
      );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_template_price_change
  BEFORE UPDATE ON public.agent_templates
  FOR EACH ROW
  WHEN (OLD.monthly_price IS DISTINCT FROM NEW.monthly_price)
  EXECUTE FUNCTION track_price_change();

-- Trigger para criar evento de mudança de status
CREATE OR REPLACE FUNCTION log_subscription_event()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.subscription_events (subscription_id, event_type, event_data)
    VALUES (NEW.id, 'created', jsonb_build_object('initial_state', row_to_json(NEW)));
    
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.subscription_events (subscription_id, event_type, event_data)
    VALUES (
      NEW.id, 
      'status_changed', 
      jsonb_build_object(
        'old_status', OLD.status,
        'new_status', NEW.status,
        'timestamp', now()
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_subscription_change
  AFTER INSERT OR UPDATE ON public.client_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION log_subscription_event();

-- Trigger para atualizar stats do template
CREATE OR REPLACE FUNCTION update_template_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Atualizar contador de assinaturas ativas
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
    UPDATE public.agent_templates
    SET 
      active_subscriptions = (
        SELECT COUNT(*) 
        FROM public.client_subscriptions 
        WHERE template_id = NEW.template_id AND status = 'active'
      ),
      total_revenue = (
        SELECT COALESCE(SUM(total_paid), 0)
        FROM public.client_subscriptions
        WHERE template_id = NEW.template_id
      )
    WHERE template_id = NEW.template_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_subscription_stats
  AFTER INSERT OR UPDATE ON public.client_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_template_stats();

-- ============================================================================
-- PARTE 9: ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.agent_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pricing_experiments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- Policies exemplo (ajustar conforme seu auth)
-- CREATE POLICY "Templates públicos para todos"
--   ON public.agent_templates FOR SELECT
--   USING (is_active = true);

-- CREATE POLICY "Clientes veem apenas suas assinaturas"
--   ON public.client_subscriptions FOR SELECT
--   USING (client_id = (auth.jwt() ->> 'client_id'));

-- ============================================================================
-- PARTE 10: VIEWS ÚTEIS
-- ============================================================================

-- View: Revenue por template
CREATE OR REPLACE VIEW v_template_revenue AS
SELECT 
  t.template_id,
  t.template_name,
  t.category,
  t.monthly_price,
  COUNT(s.id) as active_subscriptions,
  SUM(s.monthly_price) as monthly_recurring_revenue,
  AVG(s.monthly_price) as avg_price_paid
FROM public.agent_templates t
LEFT JOIN public.client_subscriptions s 
  ON t.template_id = s.template_id 
  AND s.status = 'active'
GROUP BY t.template_id, t.template_name, t.category, t.monthly_price;

-- View: Clientes com uso próximo do limite
CREATE OR REPLACE VIEW v_usage_alerts AS
SELECT 
  s.client_id,
  s.agent_id,
  s.template_id,
  t.template_name,
  COALESCE((s.current_usage->>'messages_this_month')::integer, 0) as messages_used,
  COALESCE((t.usage_limits->>'messages_per_month')::integer, 0) as messages_limit,
  CASE 
    WHEN COALESCE((t.usage_limits->>'messages_per_month')::integer, 0) = 0 THEN 0
    ELSE ROUND(
      (s.current_usage->>'messages_this_month')::numeric / 
      (t.usage_limits->>'messages_per_month')::numeric * 100, 
      2
    )
  END as usage_percentage
FROM public.client_subscriptions s
JOIN public.agent_templates t ON s.template_id = t.template_id
WHERE s.status = 'active'
  AND t.usage_limits ? 'messages_per_month'
  AND (t.usage_limits->>'messages_per_month')::integer > 0
  AND (
    (s.current_usage->>'messages_this_month')::numeric / 
    (t.usage_limits->>'messages_per_month')::numeric
  ) > 0.8;

-- View: Trials expirando esta semana
CREATE OR REPLACE VIEW v_trials_expiring_soon AS
SELECT 
  s.id,
  s.client_id,
  s.agent_id,
  c.client_name,
  t.template_name,
  s.trial_end_date,
  (s.trial_end_date - now()::date) as days_remaining
FROM public.client_subscriptions s
JOIN public.clients c ON s.client_id = c.client_id
JOIN public.agent_templates t ON s.template_id = t.template_id
WHERE s.status = 'trial'
  AND s.trial_end_date BETWEEN now() AND now() + interval '7 days'
ORDER BY s.trial_end_date;

-- View 4: Lucratividade por Template (Real-Time Profitability)
CREATE OR REPLACE VIEW v_template_profitability AS
SELECT 
  t.template_id,
  t.template_name,
  t.category,
  t.monthly_price / 5.33 as monthly_price_usd, -- BRL → USD (taxa exemplo)
  t.infrastructure_cost_usd,
  t.support_hours_included,
  t.hourly_rate_usd,
  -- Custo Total por Cliente
  (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd)) as total_cost_usd,
  -- Margem Unitária
  ((t.monthly_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd))) as profit_per_client_usd,
  -- Margem Percentual
  ROUND(
    (((t.monthly_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd))) / 
    (t.monthly_price / 5.33)) * 100, 
    2
  ) as profit_margin_percentage,
  -- MRR Total (todas as assinaturas ativas)
  COUNT(s.id) FILTER (WHERE s.status = 'active') as active_subscriptions,
  SUM(s.monthly_price / 5.33) FILTER (WHERE s.status = 'active') as total_mrr_usd,
  -- Lucro Total Mensal
  SUM(
    (s.monthly_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd))
  ) FILTER (WHERE s.status = 'active') as total_monthly_profit_usd,
  -- Metadata
  t.is_active,
  t.updated_at
FROM public.agent_templates t
LEFT JOIN public.client_subscriptions s ON t.template_id = s.template_id
GROUP BY 
  t.template_id, 
  t.template_name, 
  t.category, 
  t.monthly_price,
  t.infrastructure_cost_usd,
  t.support_hours_included,
  t.hourly_rate_usd,
  t.is_active,
  t.updated_at
ORDER BY total_monthly_profit_usd DESC NULLS LAST;

COMMENT ON VIEW v_template_profitability IS 
  'Calcula margem de lucro real por template considerando custos de infraestrutura e suporte humano. Atualiza em tempo real.';

-- ============================================================================
-- PARTE 11: FUNÇÕES DE NEGÓCIO
-- ============================================================================

-- Função: Calcular custo total de uma assinatura
CREATE OR REPLACE FUNCTION calculate_subscription_cost(
  p_subscription_id uuid,
  p_month date
) RETURNS decimal(10,2) AS $$
DECLARE
  v_base_cost decimal(10,2);
  v_overage_cost decimal(10,2) := 0;
  v_total decimal(10,2);
BEGIN
  -- Buscar custo base
  SELECT monthly_price INTO v_base_cost
  FROM public.client_subscriptions
  WHERE id = p_subscription_id;
  
  -- Calcular overages (implementar lógica aqui)
  -- v_overage_cost = ...
  
  v_total := v_base_cost + v_overage_cost;
  
  RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Função: Verificar se cliente pode criar mais agentes
CREATE OR REPLACE FUNCTION can_create_agent(p_client_id text)
RETURNS boolean AS $$
DECLARE
  v_max_agents integer;
  v_current_subscriptions integer;
BEGIN
  -- Buscar limite máximo de agentes
  SELECT max_agents INTO v_max_agents
  FROM public.clients
  WHERE client_id = p_client_id;
  
  -- Contar assinaturas ativas (não canceladas ou expiradas)
  SELECT COUNT(*) INTO v_current_subscriptions
  FROM public.client_subscriptions
  WHERE client_id = p_client_id 
    AND status IN ('trial', 'active', 'paused');
  
  RETURN v_current_subscriptions < v_max_agents;
END;
$$ LANGUAGE plpgsql;

-- Função: Reset de uso mensal (rodar no início de cada mês)
CREATE OR REPLACE FUNCTION reset_monthly_usage()
RETURNS void AS $$
BEGIN
  UPDATE public.client_subscriptions
  SET current_usage = '{
    "messages_this_month": 0,
    "transcription_minutes_this_month": 0,
    "images_this_month": 0,
    "rag_queries_this_month": 0
  }'::jsonb
  WHERE status = 'active';
  
  RAISE NOTICE 'Usage reset para % assinaturas ativas', 
    (SELECT COUNT(*) FROM public.client_subscriptions WHERE status = 'active');
END;
$$ LANGUAGE plpgsql;

-- Função: Criar assinatura a partir de um template
CREATE OR REPLACE FUNCTION create_subscription_from_template(
  p_client_id text,
  p_agent_id text,
  p_template_id text,
  p_trial_days integer DEFAULT 7
) RETURNS uuid AS $$
DECLARE
  v_subscription_id uuid;
  v_template_snapshot jsonb;
  v_template_price decimal(10,2);
BEGIN
  -- Verificar se cliente pode criar mais agentes
  IF NOT can_create_agent(p_client_id) THEN
    RAISE EXCEPTION 'Cliente atingiu limite máximo de agentes';
  END IF;
  
  -- Criar snapshot do template
  SELECT row_to_json(t)::jsonb, t.monthly_price
  INTO v_template_snapshot, v_template_price
  FROM public.agent_templates t
  WHERE template_id = p_template_id AND is_active = true;
  
  IF v_template_snapshot IS NULL THEN
    RAISE EXCEPTION 'Template % não encontrado ou inativo', p_template_id;
  END IF;
  
  -- Criar assinatura
  INSERT INTO public.client_subscriptions (
    client_id,
    agent_id,
    template_id,
    template_snapshot,
    status,
    trial_start_date,
    trial_end_date,
    monthly_price
  ) VALUES (
    p_client_id,
    p_agent_id,
    p_template_id,
    v_template_snapshot,
    'trial',
    now(),
    now() + (p_trial_days || ' days')::interval,
    v_template_price
  ) RETURNING id INTO v_subscription_id;
  
  RAISE NOTICE 'Assinatura % criada para cliente % (trial até %)', 
    v_subscription_id, p_client_id, now() + (p_trial_days || ' days')::interval;
  
  RETURN v_subscription_id;
END;
$$ LANGUAGE plpgsql;

-- Função: Incrementar uso de uma assinatura
CREATE OR REPLACE FUNCTION increment_usage(
  p_client_id text,
  p_agent_id text,
  p_usage_type text,
  p_amount integer DEFAULT 1
) RETURNS void AS $$
DECLARE
  v_current_value integer;
  v_limit integer;
  v_key text;
BEGIN
  -- Mapear tipo de uso para chave JSON
  v_key := p_usage_type || '_this_month';
  
  -- Buscar valor atual e limite
  SELECT 
    COALESCE((current_usage->>v_key)::integer, 0),
    COALESCE((template_snapshot->'usage_limits'->>p_usage_type)::integer, 999999)
  INTO v_current_value, v_limit
  FROM public.client_subscriptions s
  JOIN public.agent_templates t ON s.template_id = t.template_id
  WHERE s.client_id = p_client_id 
    AND s.agent_id = p_agent_id
    AND s.status IN ('trial', 'active');
  
  -- Verificar limite (soft warning, não bloqueia)
  IF v_current_value + p_amount > v_limit THEN
    RAISE WARNING 'Cliente % agente % atingiu limite de %: %/%', 
      p_client_id, p_agent_id, p_usage_type, v_current_value + p_amount, v_limit;
  END IF;
  
  -- Incrementar uso
  UPDATE public.client_subscriptions
  SET current_usage = jsonb_set(
    current_usage,
    ARRAY[v_key],
    to_jsonb(v_current_value + p_amount)
  )
  WHERE client_id = p_client_id 
    AND agent_id = p_agent_id
    AND status IN ('trial', 'active');
END;
$$ LANGUAGE plpgsql;

-- Função: Ativar assinatura após trial
CREATE OR REPLACE FUNCTION activate_subscription(p_subscription_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.client_subscriptions
  SET 
    status = 'active',
    subscription_start_date = now(),
    next_billing_date = now() + interval '1 month'
  WHERE id = p_subscription_id
    AND status = 'trial';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assinatura % não encontrada ou não está em trial', p_subscription_id;
  END IF;
  
  RAISE NOTICE 'Assinatura % ativada', p_subscription_id;
END;
$$ LANGUAGE plpgsql;

-- Função: Cancelar assinatura
CREATE OR REPLACE FUNCTION cancel_subscription(
  p_subscription_id uuid,
  p_reason text DEFAULT NULL
) RETURNS void AS $$
BEGIN
  UPDATE public.client_subscriptions
  SET 
    status = 'cancelled',
    cancelled_at = now(),
    internal_notes = COALESCE(internal_notes, '') || E'\nCancelado em ' || now()::text || 
      CASE WHEN p_reason IS NOT NULL THEN ': ' || p_reason ELSE '' END
  WHERE id = p_subscription_id
    AND status IN ('trial', 'active', 'paused');
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assinatura % não encontrada ou já cancelada', p_subscription_id;
  END IF;
  
  RAISE NOTICE 'Assinatura % cancelada', p_subscription_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PARTE 12: DADOS INICIAIS (Templates de Exemplo)
-- ============================================================================

-- Criar tabela temporária para mapear packages antigos → template_id
CREATE TEMP TABLE _package_migration_map (
  old_package text PRIMARY KEY,
  new_template_id text,
  priority integer
);

INSERT INTO _package_migration_map VALUES
  ('SDR', 'sdr-starter', 1),
  ('sdr', 'sdr-starter', 1),
  ('Support', 'support-basic', 2),
  ('support', 'support-basic', 2),
  ('Pro', 'sdr-pro', 3),
  ('pro', 'sdr-pro', 3),
  ('Enterprise', 'sdr-pro', 4),  -- Mapear para pro por enquanto
  ('enterprise', 'sdr-pro', 4);

INSERT INTO public.agent_templates (
  template_id,
  template_name,
  description,
  category,
  monthly_price,
  setup_fee,
  annual_price,
  infrastructure_cost_usd,
  support_hours_included,
  hourly_rate_usd,
  default_system_prompt,
  features,
  usage_limits,
  tagline,
  benefits,
  slug
) VALUES
-- SDR Starter (Self-Service - 0h suporte)
(
  'sdr-starter',
  'SDR Starter',
  'Agente de vendas para prospecção básica e qualificação de leads',
  'sales',
  697.00,
  0,
  6970.00, -- 2 meses grátis no anual
  1.38, -- Custo infra: $1.38/mês
  0, -- Sem suporte humano (self-service)
  46.88, -- Hora de trabalho: $46.88
  'Você é um SDR (Sales Development Representative) especializado em prospecção B2B...',
  ARRAY['rag', 'calendar', 'whatsapp'],
  '{
    "messages_per_month": 5000,
    "transcription_minutes": 120,
    "image_generations": 50,
    "rag_documents": 100,
    "rag_queries_per_month": 1000
  }'::jsonb,
  'Seu SDR que nunca dorme',
  ARRAY[
    'Prospecção automatizada 24/7',
    'Qualificação inteligente de leads',
    'Follow-up consistente',
    'Integração com calendário'
  ],
  'sdr-starter'
),

-- SDR Pro (Managed - 4h suporte)
(
  'sdr-pro',
  'SDR Pro',
  'Agente de vendas avançado com múltiplos canais e automações',
  'sales',
  1297.00,
  0,
  12970.00,
  1.38, -- Custo infra: $1.38/mês
  4, -- 4 horas de suporte humano incluídas
  46.88, -- Hora de trabalho: $46.88
  'Você é um SDR (Sales Development Representative) experiente...',
  ARRAY['rag', 'calendar', 'whatsapp', 'email', 'linkedin', 'crm'],
  '{
    "messages_per_month": 15000,
    "transcription_minutes": 300,
    "image_generations": 150,
    "rag_documents": 500,
    "rag_queries_per_month": 5000
  }'::jsonb,
  'SDR completo para escalar vendas',
  ARRAY[
    'Todos os recursos do Starter',
    'Múltiplos canais (WhatsApp, Email, LinkedIn)',
    'Integração com CRM',
    'Análise de sentimento',
    '3x mais capacidade',
    '4h de suporte dedicado/mês'
  ],
  'sdr-pro'
),

-- Suporte Básico (Self-Service - 0h suporte)
(
  'support-basic',
  'Suporte Básico',
  'Atendimento automático para dúvidas frequentes',
  'support',
  497.00,
  0,
  4970.00,
  1.38, -- Custo infra: $1.38/mês
  0, -- Sem suporte humano (self-service)
  46.88, -- Hora de trabalho: $46.88
  'Você é um assistente de suporte técnico prestativo...',
  ARRAY['rag', 'whatsapp', 'chatwoot'],
  '{
    "messages_per_month": 3000,
    "transcription_minutes": 60,
    "image_generations": 20,
    "rag_documents": 50,
    "rag_queries_per_month": 500
  }'::jsonb,
  'Suporte 24/7 sem custo de operador',
  ARRAY[
    'Atendimento instantâneo',
    'Base de conhecimento inteligente',
    'Reduz 70% dos tickets',
    'Integração com Chatwoot'
  ],
  'support-basic'
),

-- Suporte Premium (Managed - 2h suporte)
(
  'support-premium',
  'Suporte Premium',
  'Atendimento multi-canal com escalação inteligente',
  'support',
  997.00,
  0,
  9970.00,
  1.38, -- Custo infra: $1.38/mês
  2, -- 2 horas de suporte humano incluídas
  46.88, -- Hora de trabalho: $46.88
  'Você é um especialista em suporte ao cliente...',
  ARRAY['rag', 'whatsapp', 'chatwoot', 'email', 'voice', 'ticket_management'],
  '{
    "messages_per_month": 10000,
    "transcription_minutes": 200,
    "image_generations": 100,
    "rag_documents": 300,
    "rag_queries_per_month": 3000
  }'::jsonb,
  'Suporte enterprise sem time de CS',
  ARRAY[
    'Todos os recursos do Básico',
    'Atendimento por voz (transcrição)',
    'Gestão de tickets',
    'Escalação inteligente para humanos',
    'Analytics de satisfação',
    '2h de suporte dedicado/mês'
  ],
  'support-premium'
);

-- ============================================================================
-- PARTE 13: Feature Pricing (Add-ons)
-- ============================================================================

INSERT INTO public.feature_pricing (
  feature_id,
  feature_name,
  description,
  category,
  pricing_model,
  unit_price,
  unit_name,
  display_name
) VALUES
(
  'transcription',
  'Transcrição de Áudio',
  'Transcrição automática de mensagens de voz',
  'api_usage',
  'per_unit',
  0.02,
  'minuto',
  'Transcrição de Áudio'
),
(
  'image_generation',
  'Geração de Imagens',
  'Criação de imagens com IA (Imagen/DALL-E)',
  'api_usage',
  'per_unit',
  0.50,
  'imagem',
  'Geração de Imagens'
),
(
  'additional_documents',
  'Documentos RAG Extras',
  'Armazenamento adicional de documentos no RAG',
  'storage',
  'per_unit',
  0.10,
  'documento',
  'Documentos RAG'
),
(
  'premium_support',
  'Suporte Premium',
  'Suporte prioritário com SLA de 2h',
  'support',
  'flat',
  500.00,
  'mês',
  'Suporte Premium'
),
(
  'custom_training',
  'Treinamento Customizado',
  'Sessão de treinamento de 2h para personalizar agente',
  'support',
  'flat',
  1500.00,
  'sessão',
  'Treinamento Customizado'
);

-- ============================================================================
-- PARTE 14: MIGRAR CLIENTES EXISTENTES PARA MARKETPLACE
-- ============================================================================

DO $$
DECLARE
  v_agents_updated integer := 0;
  v_subscriptions_created integer := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'MIGRANDO CLIENTES EXISTENTES';
  RAISE NOTICE '========================================';
  
  -- 1. Atualizar template_id dos agentes baseado no package antigo do cliente
  UPDATE public.agents a
  SET template_id = COALESCE(
    (SELECT new_template_id 
     FROM _package_migration_map m
     JOIN public.clients c ON c.client_id = a.client_id
     WHERE LOWER(c.package) = LOWER(m.old_package)
     ORDER BY m.priority
     LIMIT 1),
    'sdr-starter'  -- Fallback: se não encontrar mapeamento, usar starter
  )
  WHERE template_id IS NULL;
  
  GET DIAGNOSTICS v_agents_updated = ROW_COUNT;
  RAISE NOTICE 'Agentes atualizados com template_id: %', v_agents_updated;
  
  -- 2. Criar assinaturas ativas para todos os agentes migrados
  INSERT INTO public.client_subscriptions (
    client_id,
    agent_id,
    template_id,
    template_snapshot,
    status,
    subscription_start_date,
    next_billing_date,
    monthly_price,
    billing_cycle
  )
  SELECT 
    a.client_id,
    a.agent_id,
    a.template_id,
    row_to_json(t)::jsonb as template_snapshot,
    'active' as status,
    a.created_at as subscription_start_date,
    date_trunc('month', now()) + interval '1 month' as next_billing_date,
    t.monthly_price,
    'monthly' as billing_cycle
  FROM public.agents a
  JOIN public.agent_templates t ON a.template_id = t.template_id
  WHERE a.is_active = true
    AND NOT EXISTS (
      SELECT 1 FROM public.client_subscriptions s
      WHERE s.client_id = a.client_id AND s.agent_id = a.agent_id
    );
  
  GET DIAGNOSTICS v_subscriptions_created = ROW_COUNT;
  RAISE NOTICE 'Assinaturas criadas para clientes existentes: %', v_subscriptions_created;
  
  -- 3. Adicionar FK de agents → agent_templates (agora que todos têm template_id)
  ALTER TABLE public.agents
    ADD CONSTRAINT fk_agents_template
    FOREIGN KEY (template_id) 
    REFERENCES public.agent_templates(template_id)
    ON DELETE SET NULL;
  
  RAISE NOTICE 'FK agents → agent_templates criada';
  
  RAISE NOTICE '';
  RAISE NOTICE '✅ Migração de clientes existentes completa!';
  RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- PARTE 15: COMENTÁRIOS
-- ============================================================================

COMMENT ON TABLE public.agent_templates IS 
  'Catálogo de agentes do marketplace. Campos JSONB permitem mudanças sem migrations.';

COMMENT ON COLUMN public.agent_templates.price_history IS 
  'Array JSON com histórico de mudanças de preço. Nunca perca track de experimentos.';

COMMENT ON COLUMN public.agent_templates.variant IS 
  'Para A/B testing de preços. Null = sem teste ativo.';

COMMENT ON COLUMN public.agent_templates.metadata IS 
  'Campo livre para QUALQUER dado extra. Use sem limites: cores, ícones, demos, etc.';

COMMENT ON COLUMN public.agent_templates.infrastructure_cost_usd IS 
  'Custo mensal de infraestrutura por cliente (Supabase + LLM + APIs). Usado para calcular margem real.';

COMMENT ON COLUMN public.agent_templates.support_hours_included IS 
  'Horas de suporte humano incluídas por mês. 0 = self-service, >0 = managed.';

COMMENT ON COLUMN public.agent_templates.hourly_rate_usd IS 
  'Taxa horária para cálculo de custo de suporte. Padrão: $46.88 (R$250/h ÷ 5.33).';

COMMENT ON TABLE public.client_subscriptions IS 
  'Assinaturas ativas. template_snapshot preserva estado no momento da compra.';

COMMENT ON COLUMN public.client_subscriptions.custom_limits IS 
  'Override de limites negociados com cliente específico.';

COMMENT ON TABLE public.subscription_events IS 
  'Audit log completo de mudanças em assinaturas. Rastreabilidade total.';

-- ============================================================================
-- PARTE 16: VERIFICAÇÃO
-- ============================================================================

DO $$
DECLARE
  v_templates_created integer;
  v_features_created integer;
  v_agents_with_template integer;
  v_subscriptions_active integer;
BEGIN
  SELECT COUNT(*) INTO v_templates_created FROM public.agent_templates;
  SELECT COUNT(*) INTO v_features_created FROM public.feature_pricing;
  SELECT COUNT(*) INTO v_agents_with_template FROM public.agents WHERE template_id IS NOT NULL;
  SELECT COUNT(*) INTO v_subscriptions_active FROM public.client_subscriptions WHERE status = 'active';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'MIGRATION 002 COMPLETA';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Templates criados: %', v_templates_created;
  RAISE NOTICE 'Features de pricing criadas: %', v_features_created;
  RAISE NOTICE 'Agentes com template_id: %', v_agents_with_template;
  RAISE NOTICE 'Assinaturas ativas: %', v_subscriptions_active;
  RAISE NOTICE '';
  RAISE NOTICE '✅ Sistema de marketplace FLEXÍVEL criado!';
  RAISE NOTICE '✅ Clientes existentes migrados com sucesso!';
  RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- FIM DA MIGRATION 002
-- ============================================================================

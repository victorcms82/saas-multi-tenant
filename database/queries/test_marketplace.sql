-- ============================================================================
-- QUERIES DE TESTE - Sistema de Marketplace
-- ============================================================================

-- 1. Ver todos os templates com cálculo de margem
SELECT * FROM v_template_profitability ORDER BY profit_margin_percentage DESC;

-- 2. Ver agente criado e seu template
SELECT 
  a.client_id,
  a.agent_id,
  a.agent_name,
  a.template_id,
  t.template_name,
  t.monthly_price,
  t.support_hours_included
FROM public.agents a
JOIN public.agent_templates t ON a.template_id = t.template_id;

-- 3. Ver assinatura ativa
SELECT 
  s.client_id,
  s.agent_id,
  s.status,
  s.monthly_price,
  s.template_id,
  t.template_name,
  s.subscription_start_date
FROM public.client_subscriptions s
JOIN public.agent_templates t ON s.template_id = t.template_id;

-- 4. Calcular MRR total
SELECT 
  SUM(monthly_price) as mrr_brl,
  SUM(monthly_price / 5.33) as mrr_usd,
  COUNT(*) as assinaturas_ativas
FROM public.client_subscriptions
WHERE status = 'active';

-- 5. Ver margem de lucro do template do cliente
SELECT 
  template_id,
  template_name,
  monthly_price_usd,
  infrastructure_cost_usd,
  support_hours_included * hourly_rate_usd as support_cost_usd,
  total_cost_usd,
  profit_per_client_usd,
  profit_margin_percentage || '%' as margem
FROM v_template_profitability
WHERE active_subscriptions > 0;

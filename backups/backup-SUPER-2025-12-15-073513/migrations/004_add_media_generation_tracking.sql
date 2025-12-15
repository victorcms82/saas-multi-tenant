-- ============================================================================
-- MIGRATION 004: Adicionar Tracking de Geração de Mídia
-- ============================================================================
-- Adiciona campos para rastrear mídia gerada pelo agente (imagens, áudios, docs)

-- 1. Adicionar campos de tracking de mídia gerada
ALTER TABLE client_subscriptions
ADD COLUMN IF NOT EXISTS images_generated INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS audios_generated INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS documents_generated INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS media_generation_cost_usd DECIMAL(10,4) DEFAULT 0;

COMMENT ON COLUMN client_subscriptions.images_generated IS 'Total de imagens geradas (DALL-E, Stable Diffusion)';
COMMENT ON COLUMN client_subscriptions.audios_generated IS 'Total de áudios gerados (TTS)';
COMMENT ON COLUMN client_subscriptions.documents_generated IS 'Total de documentos gerados (PDF, DOCX)';
COMMENT ON COLUMN client_subscriptions.media_generation_cost_usd IS 'Custo total acumulado de geração de mídia em USD';

-- 2. Atualizar view de profitability para incluir custos de mídia gerada
CREATE OR REPLACE VIEW v_template_profitability_complete AS
SELECT 
  t.template_id,
  t.name,
  t.base_price,
  t.infrastructure_cost_usd,
  t.support_hours_included,
  t.hourly_rate_usd,
  
  -- Custos operacionais completos
  (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd)) as total_monthly_cost_usd,
  
  -- Receita em USD (conversão R$ → USD)
  (t.base_price / 5.33) as monthly_revenue_usd,
  
  -- Margem bruta (sem custos de mídia)
  (t.base_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd)) as gross_profit_usd,
  
  -- Margem percentual bruta
  ROUND(
    ((t.base_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd))) 
    / (t.base_price / 5.33) * 100,
    2
  ) as gross_margin_percent,
  
  -- Custos médios de mídia (baseado em uso real dos clientes)
  COALESCE(AVG(s.media_generation_cost_usd), 0) as avg_media_cost_usd,
  
  -- Margem líquida (considerando custos de mídia)
  (t.base_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd) + COALESCE(AVG(s.media_generation_cost_usd), 0)) as net_profit_usd,
  
  -- Margem percentual líquida
  ROUND(
    ((t.base_price / 5.33) - (t.infrastructure_cost_usd + (t.support_hours_included * t.hourly_rate_usd) + COALESCE(AVG(s.media_generation_cost_usd), 0))) 
    / (t.base_price / 5.33) * 100,
    2
  ) as net_margin_percent,
  
  -- Métricas de uso
  COUNT(s.client_id) as active_clients,
  SUM(s.images_generated) as total_images_generated,
  SUM(s.audios_generated) as total_audios_generated,
  SUM(s.documents_generated) as total_documents_generated,
  
  t.created_at,
  t.updated_at
FROM agent_templates t
LEFT JOIN client_subscriptions s ON t.template_id = s.template_id AND s.status = 'active'
WHERE t.is_active = true
GROUP BY 
  t.template_id,
  t.name,
  t.base_price,
  t.infrastructure_cost_usd,
  t.support_hours_included,
  t.hourly_rate_usd,
  t.created_at,
  t.updated_at
ORDER BY net_margin_percent DESC;

COMMENT ON VIEW v_template_profitability_complete IS 'Profitability completa incluindo custos de geração de mídia';

-- 3. Criar query de exemplo
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'MIGRATION 004: Mídia Gerada - EXECUTADA';
  RAISE NOTICE '===========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Campos adicionados:';
  RAISE NOTICE '  ✅ images_generated (INTEGER)';
  RAISE NOTICE '  ✅ audios_generated (INTEGER)';
  RAISE NOTICE '  ✅ documents_generated (INTEGER)';
  RAISE NOTICE '  ✅ media_generation_cost_usd (DECIMAL)';
  RAISE NOTICE '';
  RAISE NOTICE 'View atualizada:';
  RAISE NOTICE '  ✅ v_template_profitability_complete';
  RAISE NOTICE '     (inclui custos de mídia gerada)';
  RAISE NOTICE '';
  RAISE NOTICE 'Exemplo de uso no workflow:';
  RAISE NOTICE '  UPDATE client_subscriptions';
  RAISE NOTICE '  SET images_generated = images_generated + 1,';
  RAISE NOTICE '      media_generation_cost_usd = media_generation_cost_usd + 0.04';
  RAISE NOTICE '  WHERE client_id = ? AND agent_id = ?';
  RAISE NOTICE '';
  RAISE NOTICE '===========================================';
END $$;

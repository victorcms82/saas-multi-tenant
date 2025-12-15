-- ============================================================================
-- INSERT: client_subscriptions para estetica_bella_rede
-- ============================================================================
-- PROBLEMA: Registro não existe, causando travamento no workflow
-- SOLUÇÃO: Inserir manualmente
-- ============================================================================

-- Verificar se já existe
SELECT * FROM client_subscriptions 
WHERE client_id = 'estetica_bella_rede' 
  AND agent_id = 'default';

-- Inserir (se não existir)
INSERT INTO client_subscriptions (
  client_id,
  agent_id,
  template_id,
  template_snapshot,
  status,
  monthly_price,
  billing_cycle,
  subscription_start_date,
  current_usage
)
VALUES (
  'estetica_bella_rede',
  'default',
  'bella-default',
  '{}'::jsonb,
  'active',
  199.00,
  'monthly',
  NOW(),
  '{"messages_count": 0, "last_message_at": null}'::jsonb
)
ON CONFLICT (client_id, agent_id) DO UPDATE
SET 
  updated_at = NOW(),
  status = 'active';

-- Validar
SELECT client_id, agent_id, status, monthly_price, created_at
FROM client_subscriptions 
WHERE client_id = 'estetica_bella_rede';

-- Resultado esperado:
-- client_id            | agent_id | status | monthly_price | created_at
-- ---------------------+----------+--------+---------------+-----------
-- estetica_bella_rede  | default  | active | 199.00        | (now)

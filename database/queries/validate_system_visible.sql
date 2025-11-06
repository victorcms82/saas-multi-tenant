-- ============================================================================
-- VALIDAÇÃO DO SISTEMA - VERSÃO COM RESULTADOS VISÍVEIS
-- ============================================================================

-- 1. Verificar tabelas existentes
SELECT 
  'Tabelas Principais' as categoria,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') as clients,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agents') as agents,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agent_templates') as templates,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'client_subscriptions') as subscriptions;

-- 2. Verificar FKs
SELECT 
  'Foreign Keys' as categoria,
  COUNT(*) as total_fks
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
  AND table_name IN ('agents', 'client_subscriptions');

-- 3. Integridade de dados
SELECT 
  'Integridade' as categoria,
  (SELECT COUNT(*) FROM agents WHERE client_id NOT IN (SELECT client_id FROM clients)) as agentes_orfaos,
  (SELECT COUNT(*) FROM agents WHERE template_id IS NULL) as agentes_sem_template,
  (SELECT COUNT(*) FROM agents a LEFT JOIN agent_templates t ON a.template_id = t.template_id WHERE a.template_id IS NOT NULL AND t.template_id IS NULL) as template_ids_invalidos,
  (SELECT COUNT(*) FROM client_subscriptions s LEFT JOIN agents a ON s.client_id = a.client_id AND s.agent_id = a.agent_id WHERE a.id IS NULL) as assinaturas_orfas;

-- 4. Estatísticas do sistema
SELECT 
  'Estatísticas' as categoria,
  (SELECT COUNT(*) FROM clients) as total_clientes,
  (SELECT COUNT(*) FROM agents WHERE is_active = true) as agentes_ativos,
  (SELECT COUNT(*) FROM agent_templates WHERE is_active = true) as templates_disponiveis,
  (SELECT COUNT(*) FROM client_subscriptions WHERE status = 'active') as assinaturas_ativas,
  (SELECT COALESCE(SUM(monthly_price), 0) FROM client_subscriptions WHERE status = 'active') as mrr_brl,
  (SELECT COALESCE(SUM(monthly_price / 5.33), 0) FROM client_subscriptions WHERE status = 'active') as mrr_usd;

-- 5. Status geral
SELECT 
  'Status Final' as categoria,
  CASE 
    WHEN (SELECT COUNT(*) FROM agents WHERE client_id NOT IN (SELECT client_id FROM clients)) = 0
     AND (SELECT COUNT(*) FROM agents a LEFT JOIN agent_templates t ON a.template_id = t.template_id WHERE a.template_id IS NOT NULL AND t.template_id IS NULL) = 0
     AND (SELECT COUNT(*) FROM client_subscriptions s LEFT JOIN agents a ON s.client_id = a.client_id AND s.agent_id = a.agent_id WHERE a.id IS NULL) = 0
    THEN '✅ SISTEMA 100% ÍNTEGRO'
    ELSE '⚠️ REVISAR ERROS ACIMA'
  END as status;

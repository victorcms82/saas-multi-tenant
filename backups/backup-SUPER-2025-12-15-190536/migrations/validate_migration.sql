-- ============================================================================
-- VALIDAÇÃO DA MIGRATION 001
-- Execute estas queries para validar a migração
-- ============================================================================

-- 1. Ver estrutura completa do agente criado
SELECT 
  agent_id,
  agent_name,
  package,
  llm_model,
  tools_enabled,
  rag_namespace,
  chatwoot_host,
  chatwoot_token,
  evolution_instance_id,
  tool_credentials,
  usage_limits,
  is_active,
  created_at
FROM public.agents 
WHERE client_id = 'clinica_sorriso_001';

-- 2. Comparar clients vs agents (mesmos dados?)
SELECT 
  'clients' as source,
  client_id,
  package,
  llm_model,
  tools_enabled,
  chatwoot_token,
  evolution_instance_id
FROM public.clients
WHERE client_id = 'clinica_sorriso_001'

UNION ALL

SELECT 
  'agents' as source,
  client_id,
  package,
  llm_model,
  tools_enabled,
  chatwoot_token,
  evolution_instance_id
FROM public.agents
WHERE client_id = 'clinica_sorriso_001';

-- 3. Verificar se campo max_agents foi adicionado
SELECT 
  client_id,
  package,
  max_agents
FROM public.clients;

-- 4. Testar constraint UNIQUE (client_id + agent_id)
-- Este deve dar ERRO (esperado):
-- INSERT INTO public.agents (client_id, agent_id, agent_name, package, system_prompt, rag_namespace)
-- VALUES ('clinica_sorriso_001', 'default', 'Teste', 'SDR', 'teste', 'clinica_sorriso_001/teste2');

-- 5. Ver índices criados
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'agents'
ORDER BY indexname;

-- 6. Verificar RLS habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'agents';

-- 7. Contar agentes por cliente (útil quando tiver mais)
SELECT 
  c.client_id,
  c.client_name,
  c.max_agents,
  COUNT(a.id) as current_agents,
  c.max_agents - COUNT(a.id) as available_slots
FROM public.clients c
LEFT JOIN public.agents a ON a.client_id = c.client_id
GROUP BY c.client_id, c.client_name, c.max_agents;

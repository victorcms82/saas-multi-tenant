-- ============================================================================
-- Migration 014: Criar Agent para Bella Estética (estetica_bella_rede)
-- ============================================================================

INSERT INTO agents (
  client_id, 
  agent_id, 
  agent_name, 
  system_prompt, 
  llm_model, 
  tools_enabled, 
  rag_namespace, 
  is_active
) VALUES (
  'estetica_bella_rede',
  'default',
  'Assistente Bella',
  'Você é um assistente de uma rede de clínicas de estética chamada Bella Estética. Ajude os clientes com agendamentos e informações sobre tratamentos estéticos.',
  'gpt-4o',
  '["rag", "MCP_Calendar", "crm_novolead", "crm_conexao", "crm_update", "crm_qualificado", "crm_agendado", "crm_desqualificado", "update_cadastro", "redirect_human", "Think"]'::JSONB,
  'estetica_bella_rede/default',
  true
)
RETURNING client_id, agent_id, agent_name, llm_model;

-- ============================================================================
-- TEST RPC: search_client_media_rules
-- ============================================================================

-- Teste 1: Parâmetros exatos do webhook test
SELECT * FROM search_client_media_rules(
  p_client_id := 'clinica_sorriso_001',
  p_agent_id := 'default',
  p_message_body := 'qual o preço?',
  p_conversation_id := '99999'
);

-- Teste 2: Ver todas as regras disponíveis
SELECT 
  id,
  client_id,
  agent_id,
  rule_type,
  keywords,
  media_id,
  is_active
FROM media_send_rules
WHERE client_id = 'clinica_sorriso_001'
  AND agent_id = 'default'
  AND is_active = true;

-- Teste 3: Ver mídias disponíveis
SELECT 
  id,
  file_name,
  tags
FROM client_media
WHERE client_id = 'clinica_sorriso_001'
  AND agent_id = 'default'
  AND is_active = true;

-- Teste 4: Testar keyword match manualmente
SELECT 
  msr.id as rule_id,
  msr.keywords,
  cm.file_name,
  cm.file_url
FROM media_send_rules msr
JOIN client_media cm ON msr.media_id = cm.id
WHERE msr.client_id = 'clinica_sorriso_001'
  AND msr.agent_id = 'default'
  AND msr.rule_type = 'keyword_trigger'
  AND msr.is_active = true
  AND EXISTS (
    SELECT 1
    FROM unnest(msr.keywords) AS keyword
    WHERE 'qual o preço?' ILIKE '%' || keyword || '%'
  );

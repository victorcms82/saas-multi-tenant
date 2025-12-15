-- Função RPC para buscar regras de mídia via Supabase REST API
-- Execute no SQL Editor do Supabase

CREATE OR REPLACE FUNCTION search_client_media_rules(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_message_body TEXT,
  p_conversation_id TEXT
)
RETURNS TABLE (
  rule_id UUID,
  media_id UUID,
  trigger_type TEXT,
  trigger_value TEXT,
  file_url TEXT,
  file_type TEXT,
  file_name TEXT,
  mime_type TEXT,
  title TEXT,
  description TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH keyword_matches AS (
    SELECT 
      msr.id as rule_id,
      msr.media_id,
      msr.priority,
      msr.send_once,
      msr.cooldown_hours,
      'keyword'::TEXT as trigger_type,
      array_to_string(msr.keywords, ', ') as trigger_value
    FROM media_send_rules msr
    WHERE msr.client_id = p_client_id
      AND (msr.agent_id = p_agent_id OR msr.agent_id IS NULL)
      AND msr.rule_type = 'keyword_trigger'
      AND msr.is_active = true
      AND EXISTS (
        SELECT 1 FROM unnest(msr.keywords) kw
        WHERE LOWER(p_message_body) LIKE '%' || LOWER(kw) || '%'
      )
  ),
  phase_matches AS (
    SELECT 
      msr.id as rule_id,
      msr.media_id,
      msr.priority,
      msr.send_once,
      msr.cooldown_hours,
      'phase'::TEXT as trigger_type,
      ('message_' || msr.message_number::TEXT)::TEXT as trigger_value
    FROM media_send_rules msr,
    (
      SELECT COUNT(*) as msg_count 
      FROM media_send_log 
      WHERE conversation_id = p_conversation_id
    ) conv
    WHERE msr.client_id = p_client_id
      AND (msr.agent_id = p_agent_id OR msr.agent_id IS NULL)
      AND msr.rule_type = 'conversation_phase'
      AND msr.is_active = true
      AND msr.message_number = conv.msg_count + 1
  ),
  all_matches AS (
    SELECT * FROM keyword_matches
    UNION ALL
    SELECT * FROM phase_matches
  )
  SELECT 
    am.rule_id,
    am.media_id,
    am.trigger_type,
    am.trigger_value,
    cm.file_url,
    cm.file_type,
    cm.file_name,
    cm.mime_type,
    cm.title,
    cm.description
  FROM all_matches am
  INNER JOIN client_media cm ON am.media_id = cm.id
  WHERE cm.is_active = true
    AND (
      am.send_once = false 
      OR NOT EXISTS (
        SELECT 1 FROM media_send_log msl
        WHERE msl.rule_id = am.rule_id
          AND msl.conversation_id = p_conversation_id
      )
    )
    AND (
      am.cooldown_hours IS NULL
      OR NOT EXISTS (
        SELECT 1 FROM media_send_log msl
        WHERE msl.rule_id = am.rule_id
          AND msl.conversation_id = p_conversation_id
          AND msl.sent_at > NOW() - (am.cooldown_hours || ' hours')::INTERVAL
      )
    )
  ORDER BY am.priority ASC
  LIMIT 3;
END;
$$;

-- Dar permissão de execução para anon e authenticated
GRANT EXECUTE ON FUNCTION search_client_media_rules(TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;

-- Testar função
SELECT * FROM search_client_media_rules(
  'clinica_sorriso_001',
  'default',
  'qual o preço?',
  'test-conv-123'
);

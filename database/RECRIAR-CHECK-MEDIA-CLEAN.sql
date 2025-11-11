-- Recriar check_media_triggers sem sobrecarga
CREATE OR REPLACE FUNCTION check_media_triggers(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_message TEXT
)
RETURNS TABLE (
  rule_id UUID,
  media_id UUID,
  trigger_type VARCHAR,
  trigger_value TEXT,
  file_url TEXT,
  file_type VARCHAR,
  file_name VARCHAR,
  mime_type VARCHAR,
  title VARCHAR,
  description TEXT
)
SECURITY DEFINER
AS $$
BEGIN
  IF p_client_id IS NULL OR p_client_id = '' THEN
    RAISE EXCEPTION 'client_id obrigatorio';
  END IF;

  PERFORM set_config('app.current_client_id', p_client_id, true);

  RETURN QUERY
  SELECT 
    cmr.rule_id,
    cmr.media_id,
    cmr.trigger_type::VARCHAR,
    cmr.trigger_value,
    cm.file_url,
    cm.file_type::VARCHAR,
    cm.file_name::VARCHAR,
    cm.mime_type::VARCHAR,
    cm.title::VARCHAR,
    cm.description
  FROM client_media_rules cmr
  INNER JOIN client_media cm ON cmr.media_id = cm.id
  WHERE 
    cmr.client_id = p_client_id
    AND cm.client_id = p_client_id
    AND cmr.agent_id = p_agent_id
    AND cmr.is_active = true
    AND cm.is_active = true
    AND cmr.trigger_type = 'keyword'
    AND p_message ~* cmr.trigger_value
  ORDER BY cmr.priority DESC, cmr.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

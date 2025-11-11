-- ============================================================================
-- FIX: Remover sobrecarga duplicada de check_media_triggers
-- ============================================================================

-- 1. Dropar TODAS as versões da função
DROP FUNCTION IF EXISTS check_media_triggers(VARCHAR, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS check_media_triggers(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS check_media_triggers(character varying, character varying, text);

-- 2. Recriar UMA versão unificada (usando TEXT que é mais genérico)
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
  -- 🔒 VALIDAÇÃO
  IF p_client_id IS NULL OR p_client_id = '' THEN
    RAISE EXCEPTION '🔒 client_id obrigatório';
  END IF;

  -- Setar contexto
  PERFORM set_config('app.current_client_id', p_client_id, true);

  -- 🔒 QUERY BLINDADA: APENAS mídia do client_id específico
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
  INNER JOIN client_media cm 
    ON cmr.media_id = cm.media_id
  WHERE 
    -- 🔒 CRÍTICO: Filtro duplo de client_id (regra + mídia)
    cmr.client_id = p_client_id
    AND cm.client_id = p_client_id
    AND cmr.agent_id = p_agent_id
    AND cmr.is_active = true
    AND cm.is_active = true
    AND cmr.trigger_type = 'keyword'
    AND p_message ~* cmr.trigger_value
  ORDER BY 
    cmr.priority DESC,
    cmr.created_at DESC
  LIMIT 1;  -- 🔒 Apenas 1 mídia por mensagem
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_media_triggers IS 
'🔒 SEGURANÇA BLINDADA: Retorna mídia APENAS do client_id fornecido. 
Versão unificada (TEXT) - sem sobrecarga.';

-- 3. Verificar que só existe uma versão agora
SELECT 
  proname as function_name,
  pg_get_function_identity_arguments(oid) as arguments
FROM pg_proc 
WHERE proname = 'check_media_triggers';

-- Deve retornar APENAS 1 linha

-- CRIAR FUNCTION RPC: check_media_triggers
-- Busca regras de mídia ativas que fazem match com a mensagem do usuário

CREATE OR REPLACE FUNCTION public.check_media_triggers(
    p_client_id TEXT,
    p_agent_id TEXT,
    p_message TEXT
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
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cmr.id AS rule_id,
        cmr.media_id,
        cmr.trigger_type,
        cmr.trigger_value,
        cm.file_url,
        cm.file_type,
        cm.file_name,
        cm.mime_type,
        cm.title,
        cm.description
    FROM public.client_media_rules cmr
    JOIN public.client_media cm ON cmr.media_id = cm.id
    WHERE cmr.client_id = p_client_id
      AND cmr.agent_id = p_agent_id
      AND cmr.is_active = true
      AND cmr.trigger_type = 'keyword'
      AND p_message ~* cmr.trigger_value  -- Regex match case-insensitive
    ORDER BY cmr.priority DESC, cmr.created_at DESC
    LIMIT 1;  -- Retornar apenas 1 arquivo por vez (pode ser ajustado)
END;
$$;

-- Comentário da function
COMMENT ON FUNCTION public.check_media_triggers IS 
'Busca regras de mídia ativas que fazem match com a mensagem do usuário usando regex case-insensitive';

-- Testar a function
SELECT * FROM public.check_media_triggers(
    'clinica_sorriso_001',
    'default',
    'quero ver a clínica'
);

-- Testes adicionais
SELECT * FROM public.check_media_triggers(
    'clinica_sorriso_001',
    'default',
    'quanto custa uma limpeza?'
);

SELECT * FROM public.check_media_triggers(
    'clinica_sorriso_001',
    'default',
    'mostra a equipe'
);

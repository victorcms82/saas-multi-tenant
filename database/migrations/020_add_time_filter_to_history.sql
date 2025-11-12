-- ============================================================================
-- Migration 020: Adicionar filtro de tempo ao histórico de conversa
-- ============================================================================
-- Permite controlar memória por tempo (1h, 1 dia, 1 semana, etc)
-- ============================================================================

-- Drop da função antiga (sem filtro de tempo)
DROP FUNCTION IF EXISTS get_conversation_history(VARCHAR, INTEGER, INTEGER);

-- Criar nova versão COM filtro de tempo
CREATE OR REPLACE FUNCTION get_conversation_history(
    p_client_id VARCHAR,
    p_conversation_id INTEGER,
    p_limit INTEGER DEFAULT 10,
    p_hours_back INTEGER DEFAULT NULL  -- NOVO: NULL = sem limite de tempo
)
RETURNS TABLE(
    message_role VARCHAR,
    message_content TEXT,
    message_timestamp TIMESTAMP WITH TIME ZONE,
    has_attachments BOOLEAN,
    contact_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    time_cutoff TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Calcular timestamp de corte se p_hours_back foi fornecido
    IF p_hours_back IS NOT NULL THEN
        time_cutoff := NOW() - (p_hours_back || ' hours')::INTERVAL;
    ELSE
        -- Sem limite de tempo (busca tudo)
        time_cutoff := '1900-01-01'::TIMESTAMP WITH TIME ZONE;
    END IF;

    -- Configurar client_id para RLS
    PERFORM set_config('app.current_client_id', p_client_id, true);
    
    RETURN QUERY
    SELECT 
        cm.message_role,
        cm.message_content,
        cm.message_timestamp,
        cm.has_attachments,
        cm.contact_id
    FROM conversation_memory cm
    WHERE cm.client_id = p_client_id
      AND cm.conversation_id = p_conversation_id
      AND cm.message_timestamp >= time_cutoff  -- ⬅️ NOVO: Filtro de tempo
    ORDER BY cm.message_timestamp DESC
    LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_conversation_history(VARCHAR, INTEGER, INTEGER, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_conversation_history(VARCHAR, INTEGER, INTEGER, INTEGER) TO authenticated;

-- ============================================================================
-- EXEMPLOS DE USO:
-- ============================================================================

-- Buscar últimas 10 mensagens da última 1 hora
-- SELECT * FROM get_conversation_history('estetica_bella_rede', 6, 10, 1);

-- Buscar últimas 20 mensagens das últimas 24 horas (1 dia)
-- SELECT * FROM get_conversation_history('estetica_bella_rede', 6, 20, 24);

-- Buscar últimas 50 mensagens da última semana (168 horas)
-- SELECT * FROM get_conversation_history('estetica_bella_rede', 6, 50, 168);

-- Buscar últimas 10 mensagens sem limite de tempo (comportamento antigo)
-- SELECT * FROM get_conversation_history('estetica_bella_rede', 6, 10, NULL);

-- ============================================================================
-- CONFIGURAÇÕES SUGERIDAS:
-- ============================================================================
-- 1h  = 1 hora    → p_hours_back: 1
-- 3h  = 3 horas   → p_hours_back: 3
-- 12h = 12 horas  → p_hours_back: 12
-- 1d  = 1 dia     → p_hours_back: 24
-- 3d  = 3 dias    → p_hours_back: 72
-- 1s  = 1 semana  → p_hours_back: 168
-- 1m  = 1 mês     → p_hours_back: 720
-- ============================================================================

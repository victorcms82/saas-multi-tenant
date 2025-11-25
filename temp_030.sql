-- ============================================================================
-- Migration 030: Corrigir tipos de retorno das funções RPC do Admin
-- ============================================================================
-- Descrição: Ajusta tipos de retorno das funções get_all_clients, 
--            get_all_agents e get_global_conversations para bater com 
--            os tipos reais das colunas
-- Data: 2025-11-24
-- ============================================================================

-- ============================================================================
-- 1. Recriar get_all_clients com tipos corretos
-- ============================================================================

DROP FUNCTION IF EXISTS get_all_clients();

CREATE OR REPLACE FUNCTION get_all_clients()
RETURNS TABLE (
    client_id VARCHAR(100),
    client_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    rag_namespace VARCHAR(255),
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    total_agents BIGINT,
    total_conversations BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode acessar esta função';
    END IF;
    
    -- Retornar dados de todos os clientes
    RETURN QUERY
    SELECT 
        c.client_id,
        c.client_name,
        c.contact_email,
        c.contact_phone,
        c.rag_namespace,
        c.is_active,
        c.created_at,
        COUNT(DISTINCT a.id) as total_agents,
        COUNT(DISTINCT conv.id) as total_conversations
    FROM clients c
    LEFT JOIN agents a ON a.client_id = c.client_id
    LEFT JOIN conversations conv ON conv.client_id = c.client_id
    GROUP BY c.client_id, c.client_name, c.contact_email, c.contact_phone, c.rag_namespace, c.is_active, c.created_at
    ORDER BY c.created_at DESC;
END;
$$;

COMMENT ON FUNCTION get_all_clients IS 
'[ADMIN ONLY] Retorna lista de todos os clientes com contagem de agentes e conversas';

-- ============================================================================
-- 2. Recriar get_all_agents com tipos corretos
-- ============================================================================

DROP FUNCTION IF EXISTS get_all_agents();

CREATE OR REPLACE FUNCTION get_all_agents()
RETURNS TABLE (
    id UUID,
    agent_id VARCHAR(100),
    agent_name VARCHAR(255),
    client_id VARCHAR(100),
    client_name VARCHAR(255),
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    total_conversations BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode acessar esta função';
    END IF;
    
    -- Retornar dados de todos os agentes
    RETURN QUERY
    SELECT 
        a.id,
        a.agent_id,
        a.agent_name,
        a.client_id,
        c.client_name,
        a.is_active,
        a.created_at,
        COUNT(DISTINCT conv.id) as total_conversations
    FROM agents a
    LEFT JOIN clients c ON c.client_id = a.client_id
    LEFT JOIN conversations conv ON conv.client_id = a.client_id
    GROUP BY a.id, a.agent_id, a.agent_name, a.client_id, c.client_name, a.is_active, a.created_at
    ORDER BY a.created_at DESC;
END;
$$;

COMMENT ON FUNCTION get_all_agents IS 
'[ADMIN ONLY] Retorna lista de todos os agentes de todos os clientes';

-- ============================================================================
-- 3. Recriar get_global_conversations com tipos corretos
-- ============================================================================

DROP FUNCTION IF EXISTS get_global_conversations(INTEGER, INTEGER, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS get_global_conversations(INTEGER, INTEGER, VARCHAR, INTEGER);

CREATE OR REPLACE FUNCTION get_global_conversations(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_client_id VARCHAR(100) DEFAULT NULL,
    p_status_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    chatwoot_conversation_id INTEGER,
    client_id VARCHAR(100),
    client_name VARCHAR(255),
    contact_identifier VARCHAR(255),
    channel VARCHAR(50),
    status_id INTEGER,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode acessar esta função';
    END IF;
    
    -- Retornar conversas de todos os clientes
    RETURN QUERY
    SELECT 
        c.id as conversation_id,
        c.chatwoot_conversation_id,
        c.client_id,
        cl.client_name,
        c.contact_identifier,
        c.channel,
        c.status_id,
        c.last_message_content as last_message,
        c.last_message_at,
        c.created_at
    FROM conversations c
    LEFT JOIN clients cl ON cl.client_id = c.client_id
    WHERE 
        (p_client_id IS NULL OR c.client_id = p_client_id)
        AND (p_status_id IS NULL OR c.status_id = p_status_id)
    ORDER BY c.last_message_at DESC NULLS LAST
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_global_conversations IS 
'[ADMIN ONLY] Retorna conversas de todos os clientes com filtros';


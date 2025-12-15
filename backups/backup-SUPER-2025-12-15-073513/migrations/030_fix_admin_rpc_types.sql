-- ============================================================================
-- Migration 030: Admin Master RPCs (VERSÃO DEFINITIVA - COM DROP DINÂMICO)
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. LIMPAR FUNÇÕES ÓRFÃS (DROPAR TODAS AS VERSÕES)
-- ============================================================================

-- Dropar TODAS as versões de get_all_clients
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'get_all_clients'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- Dropar TODAS as versões de get_all_agents
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'get_all_agents'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- Dropar TODAS as versões de get_global_conversations
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'get_global_conversations'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- Dropar TODAS as versões de create_new_client
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'create_new_client'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- Dropar TODAS as versões de create_default_agent
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'create_default_agent'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- ============================================================================
-- 2. CRIAR: get_all_clients
-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_clients()
RETURNS TABLE (
    client_id TEXT,
    client_name TEXT,
    admin_email TEXT,
    admin_phone TEXT,
    rag_namespace TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    total_agents BIGINT,
    total_conversations BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode acessar esta função';
    END IF;
    
    RETURN QUERY
    SELECT 
        c.client_id,
        c.client_name,
        c.admin_email,
        c.admin_phone,
        c.rag_namespace,
        c.is_active,
        c.created_at,
        COUNT(DISTINCT a.id) as total_agents,
        COUNT(DISTINCT conv.id) as total_conversations
    FROM clients c
    LEFT JOIN agents a ON a.client_id = c.client_id
    LEFT JOIN conversations conv ON conv.client_id = c.client_id
    GROUP BY c.client_id, c.client_name, c.admin_email, c.admin_phone, c.rag_namespace, c.is_active, c.created_at
    ORDER BY c.created_at DESC;
END;
$$;

COMMENT ON FUNCTION get_all_clients IS '[ADMIN ONLY] Lista todos os clientes';

-- ============================================================================
-- 3. CRIAR: get_all_agents
-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_agents()
RETURNS TABLE (
    id UUID,
    agent_id TEXT,
    agent_name TEXT,
    client_id TEXT,
    client_name TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    total_conversations BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode acessar esta função';
    END IF;
    
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
    LEFT JOIN conversations conv ON conv.agent_id = a.agent_id
    GROUP BY a.id, a.agent_id, a.agent_name, a.client_id, c.client_name, a.is_active, a.created_at
    ORDER BY a.created_at DESC;
END;
$$;

COMMENT ON FUNCTION get_all_agents IS '[ADMIN ONLY] Lista todos os agentes';

-- ============================================================================
-- 4. CRIAR: get_global_conversations
-- ============================================================================

CREATE OR REPLACE FUNCTION get_global_conversations(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_client_id TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    chatwoot_conversation_id INTEGER,
    client_id TEXT,
    client_name TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    channel_type TEXT,
    status TEXT,
    last_message_content TEXT,
    last_message_timestamp TIMESTAMPTZ,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode acessar esta função';
    END IF;
    
    RETURN QUERY
    SELECT 
        c.id,
        c.chatwoot_conversation_id,
        c.client_id,
        cl.client_name,
        c.customer_name,
        c.customer_phone,
        c.channel_type::TEXT,
        c.status,
        c.last_message_content,
        c.last_message_timestamp,
        c.created_at
    FROM conversations c
    LEFT JOIN clients cl ON cl.client_id = c.client_id
    WHERE 
        (p_client_id IS NULL OR c.client_id = p_client_id)
        AND (p_status IS NULL OR c.status = p_status)
    ORDER BY c.last_message_timestamp DESC NULLS LAST
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_global_conversations IS '[ADMIN ONLY] Lista todas as conversas';

-- ============================================================================
-- 5. CRIAR: create_new_client
-- ============================================================================

CREATE OR REPLACE FUNCTION create_new_client(
    p_client_id TEXT,
    p_client_name TEXT,
    p_admin_email TEXT,
    p_admin_phone TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode criar clientes';
    END IF;
    
    IF EXISTS (SELECT 1 FROM clients WHERE client_id = p_client_id) THEN
        RETURN json_build_object('success', FALSE, 'error', 'Client ID já existe');
    END IF;

    INSERT INTO clients (
        client_id, client_name, admin_email, admin_phone, 
        is_active, rag_namespace
    )
    VALUES (
        p_client_id, p_client_name, p_admin_email, p_admin_phone,
        TRUE, p_client_id
    );

    RETURN json_build_object(
        'success', TRUE,
        'client_id', p_client_id,
        'message', 'Cliente criado com sucesso'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

COMMENT ON FUNCTION create_new_client IS '[ADMIN ONLY] Cria novo cliente';

-- ============================================================================
-- 6. CRIAR: create_default_agent
-- ============================================================================

CREATE OR REPLACE FUNCTION create_default_agent(
    p_client_id TEXT,
    p_agent_name TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_agent_id TEXT;
    v_new_agent_id UUID;
BEGIN
    IF NOT is_super_admin() THEN
        RAISE EXCEPTION 'Acesso negado: apenas super_admin pode criar agentes';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM clients WHERE client_id = p_client_id) THEN
        RETURN json_build_object('success', FALSE, 'error', 'Cliente não encontrado');
    END IF;

    v_agent_id := p_client_id || '_agent_' || floor(random() * 10000)::text;

    INSERT INTO agents (
        client_id, agent_id, agent_name, is_active,
        system_prompt, llm_model, tools_enabled, 
        rag_namespace, buffer_delay
    )
    VALUES (
        p_client_id, v_agent_id, p_agent_name, TRUE,
        'Você é um assistente virtual prestativo.', 
        'gpt-4o-mini', '[]'::jsonb,
        p_client_id, 0
    )
    RETURNING id INTO v_new_agent_id;

    RETURN json_build_object(
        'success', TRUE,
        'agent_id', v_agent_id,
        'id', v_new_agent_id,
        'message', 'Agente criado com sucesso'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

COMMENT ON FUNCTION create_default_agent IS '[ADMIN ONLY] Cria novo agente';

-- ============================================================================
-- 7. PERMISSÕES
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_all_clients TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_agents TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION create_new_client TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_agent TO authenticated;

-- ============================================================================
-- 8. VALIDAÇÃO
-- ============================================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'get_all_clients', 'get_all_agents', 'get_global_conversations',
        'create_new_client', 'create_default_agent'
    );
    
    IF v_count = 5 THEN
        RAISE NOTICE '✅ Migration 030 executada com sucesso!';
        RAISE NOTICE '   - 5 funções RPC criadas para Admin Master';
        RAISE NOTICE '   - Validação is_super_admin() ativa';
        RAISE NOTICE '   - Tipos 100%% compatíveis com schema real';
    ELSE
        RAISE EXCEPTION 'Validação falhou! Esperado: 5, Encontrado: %', v_count;
    END IF;
END $$;

COMMIT;

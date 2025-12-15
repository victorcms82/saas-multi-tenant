-- ============================================================================
-- Migration 027: Criar Sistema de Permissões - Super Admin
-- ============================================================================
-- Data: 2025-01-20
-- Descrição: Adicionar sistema de roles e permissões para admin master
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Atualizar coluna role na tabela dashboard_users
-- ============================================================================

-- NOTA: Coluna role JÁ EXISTE com valor 'admin'
-- Vamos apenas atualizar o CHECK constraint para incluir novos roles

-- Dropar constraint antigo se existir
DO $$
BEGIN
    ALTER TABLE dashboard_users DROP CONSTRAINT IF EXISTS dashboard_users_role_check;
EXCEPTION
    WHEN undefined_object THEN NULL;
END$$;

-- Adicionar novo constraint com todos os roles
ALTER TABLE dashboard_users 
ADD CONSTRAINT dashboard_users_role_check 
CHECK (role IN ('agent', 'admin', 'manager', 'super_admin'));

-- Comentário
COMMENT ON COLUMN dashboard_users.role IS 
'Papel do usuário: agent (agente normal), admin (admin do cliente), manager (gestor do cliente), super_admin (administrador master)';

-- ============================================================================
-- PARTE 2: Atualizar usuário teste para super_admin
-- ============================================================================

UPDATE dashboard_users
SET role = 'super_admin'
WHERE email = 'teste@evolutedigital.com.br';

-- ============================================================================
-- PARTE 3: Criar função RPC is_super_admin
-- ============================================================================

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role VARCHAR(20);
BEGIN
    -- Buscar role do usuário autenticado
    SELECT role INTO v_user_role
    FROM dashboard_users
    WHERE id = auth.uid();
    
    -- Retornar true se for super_admin
    RETURN (v_user_role = 'super_admin');
END;
$$;

COMMENT ON FUNCTION is_super_admin IS 
'Verifica se o usuário autenticado é super_admin';

-- ============================================================================
-- PARTE 4: Criar função RPC get_all_clients (admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_clients()
RETURNS TABLE (
    client_id VARCHAR(100),
    client_name VARCHAR(255),
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    total_conversations BIGINT,
    total_messages BIGINT,
    total_agents BIGINT
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
        c.is_active,
        c.created_at,
        COUNT(DISTINCT conv.id) as total_conversations,
        COUNT(DISTINCT cm.id) as total_messages,
        COUNT(DISTINCT a.id) as total_agents
    FROM clients c
    LEFT JOIN conversations conv ON conv.client_id = c.client_id
    LEFT JOIN conversation_memory cm ON cm.client_id = c.client_id
    LEFT JOIN agents a ON a.client_id = c.client_id
    GROUP BY c.client_id, c.client_name, c.is_active, c.created_at
    ORDER BY c.created_at DESC;
END;
$$;

COMMENT ON FUNCTION get_all_clients IS 
'[ADMIN ONLY] Retorna lista de todos os clientes com métricas';

-- ============================================================================
-- PARTE 5: Criar função RPC get_all_agents (admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_agents()
RETURNS TABLE (
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
        a.id as agent_id,
        a.agent_name,
        a.client_id,
        c.client_name,
        a.is_active,
        a.created_at,
        COUNT(DISTINCT conv.id) as total_conversations
    FROM agents a
    LEFT JOIN clients c ON c.client_id = a.client_id
    LEFT JOIN conversations conv ON conv.client_id = a.client_id
    GROUP BY a.id, a.agent_name, a.client_id, c.client_name, a.is_active, a.created_at
    ORDER BY a.created_at DESC;
END;
$$;

COMMENT ON FUNCTION get_all_agents IS 
'[ADMIN ONLY] Retorna lista de todos os agentes de todos os clientes';

-- ============================================================================
-- PARTE 6: Criar função RPC get_global_conversations (admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_global_conversations(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_client_id VARCHAR(100) DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    conversation_uuid UUID,
    conversation_id INTEGER,
    client_id VARCHAR(100),
    client_name VARCHAR(255),
    contact_name VARCHAR(255),
    contact_phone VARCHAR(50),
    channel VARCHAR(50),
    status VARCHAR(50),
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
        c.id as conversation_uuid,
        c.chatwoot_conversation_id as conversation_id,
        c.client_id,
        cl.client_name,
        c.customer_name as contact_name,
        c.customer_phone as contact_phone,
        c.channel_type as channel,
        c.status,
        c.last_message_content as last_message,
        c.last_message_timestamp as last_message_at,
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

COMMENT ON FUNCTION get_global_conversations IS 
'[ADMIN ONLY] Retorna conversas de todos os clientes com filtros';

-- ============================================================================
-- PARTE 7: Grants de Permissão
-- ============================================================================

GRANT EXECUTE ON FUNCTION is_super_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_clients TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_agents TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_conversations TO authenticated;

-- ============================================================================
-- PARTE 8: Validação
-- ============================================================================

-- Verificar se role foi adicionada
SELECT 
    '✅ COLUNA ROLE' as tipo,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_name = 'dashboard_users'
AND column_name = 'role';

-- Verificar se usuário teste é super_admin
SELECT 
    '✅ USUÁRIO TESTE' as tipo,
    email,
    role,
    client_id
FROM dashboard_users
WHERE email = 'teste@evolutedigital.com.br';

-- Listar funções criadas
SELECT 
    '✅ FUNÇÕES CRIADAS' as tipo,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('is_super_admin', 'get_all_clients', 'get_all_agents', 'get_global_conversations')
ORDER BY routine_name;

COMMIT;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 
-- 1. ROLES:
--    - agent: Agente normal (vê apenas conversas do seu cliente)
--    - manager: Gestor do cliente (vê tudo do cliente dele)
--    - super_admin: Administrador master (vê TUDO)
--
-- 2. SEGURANÇA:
--    - Todas as funções de admin verificam is_super_admin()
--    - Se não for super_admin, retorna erro
--    - Usuário teste@evolutedigital.com.br virou super_admin
--
-- 3. PRÓXIMOS PASSOS:
--    - Criar rota /admin no Lovable
--    - Implementar UI de gestão de clientes
--    - Implementar UI de gestão de agentes
--    - Implementar analytics global
--
-- ============================================================================

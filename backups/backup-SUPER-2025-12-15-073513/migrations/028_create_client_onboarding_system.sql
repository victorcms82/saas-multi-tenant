-- ============================================================================
-- Migration 028: Sistema de Onboarding de Clientes
-- ============================================================================
-- Data: 2025-01-20
-- Descrição: Criar funções para cadastro automatizado de novos clientes
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Função para criar novo cliente (super_admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION create_new_client(
    p_client_id VARCHAR(100),
    p_client_name VARCHAR(255),
    p_contact_email VARCHAR(255),
    p_contact_phone VARCHAR(50),
    p_business_type VARCHAR(100) DEFAULT 'general'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
    v_client_exists BOOLEAN;
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acesso negado: apenas super_admin pode criar clientes'
        );
    END IF;
    
    -- Verificar se client_id já existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE client_id = p_client_id) 
    INTO v_client_exists;
    
    IF v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cliente já existe com este ID'
        );
    END IF;
    
    -- Inserir novo cliente
    INSERT INTO clients (
        client_id,
        client_name,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_client_id,
        p_client_name,
        true,
        NOW(),
        NOW()
    );
    
    -- Retornar sucesso
    v_result := json_build_object(
        'success', true,
        'client_id', p_client_id,
        'client_name', p_client_name,
        'message', 'Cliente criado com sucesso'
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

COMMENT ON FUNCTION create_new_client IS 
'[SUPER_ADMIN ONLY] Cria um novo cliente no sistema';

-- ============================================================================
-- PARTE 2: Função para criar usuário admin do cliente (super_admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION create_client_admin(
    p_email VARCHAR(255),
    p_full_name VARCHAR(255),
    p_client_id VARCHAR(100),
    p_role VARCHAR(20) DEFAULT 'admin'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
    v_user_id UUID;
    v_client_exists BOOLEAN;
    v_user_exists BOOLEAN;
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acesso negado: apenas super_admin pode criar admins'
        );
    END IF;
    
    -- Verificar se cliente existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE client_id = p_client_id) 
    INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cliente não existe'
        );
    END IF;
    
    -- Verificar se usuário já existe
    SELECT EXISTS(SELECT 1 FROM dashboard_users WHERE email = p_email) 
    INTO v_user_exists;
    
    IF v_user_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Usuário já existe com este email'
        );
    END IF;
    
    -- Gerar UUID para novo usuário
    v_user_id := gen_random_uuid();
    
    -- Inserir registro em dashboard_users
    -- NOTA: O usuário real será criado via Supabase Auth API
    INSERT INTO dashboard_users (
        id,
        email,
        full_name,
        client_id,
        role,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        p_email,
        p_full_name,
        p_client_id,
        p_role,
        true,
        NOW(),
        NOW()
    );
    
    -- Retornar dados para criar usuário no Auth
    v_result := json_build_object(
        'success', true,
        'user_id', v_user_id,
        'email', p_email,
        'full_name', p_full_name,
        'client_id', p_client_id,
        'role', p_role,
        'message', 'Registro criado. Criar usuário no Supabase Auth com este user_id'
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

COMMENT ON FUNCTION create_client_admin IS 
'[SUPER_ADMIN ONLY] Cria registro de admin para um cliente (requer criação no Auth API)';

-- ============================================================================
-- PARTE 3: Função para criar agente IA padrão (super_admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION create_default_agent(
    p_client_id VARCHAR(100),
    p_agent_name VARCHAR(255) DEFAULT 'Assistente Virtual',
    p_system_prompt TEXT DEFAULT 'Você é um assistente virtual prestativo e educado.'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
    v_agent_id VARCHAR(100);
    v_client_exists BOOLEAN;
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acesso negado: apenas super_admin pode criar agentes'
        );
    END IF;
    
    -- Verificar se cliente existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE client_id = p_client_id) 
    INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cliente não existe'
        );
    END IF;
    
    -- Gerar ID do agente
    v_agent_id := p_client_id || '_agent_default';
    
    -- Inserir agente padrão
    INSERT INTO agents (
        id,
        client_id,
        agent_name,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_agent_id,
        p_client_id,
        p_agent_name,
        true,
        NOW(),
        NOW()
    );
    
    -- Inserir configuração do prompt
    INSERT INTO ai_prompts (
        client_id,
        agent_id,
        prompt_name,
        system_prompt,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_client_id,
        v_agent_id,
        'default',
        p_system_prompt,
        true,
        NOW(),
        NOW()
    )
    ON CONFLICT (client_id, agent_id) DO UPDATE
    SET 
        system_prompt = p_system_prompt,
        updated_at = NOW();
    
    -- Retornar sucesso
    v_result := json_build_object(
        'success', true,
        'agent_id', v_agent_id,
        'agent_name', p_agent_name,
        'client_id', p_client_id,
        'message', 'Agente padrão criado com sucesso'
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

COMMENT ON FUNCTION create_default_agent IS 
'[SUPER_ADMIN ONLY] Cria agente IA padrão para um cliente';

-- ============================================================================
-- PARTE 4: Função completa de onboarding (super_admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION onboard_new_client(
    p_client_id VARCHAR(100),
    p_client_name VARCHAR(255),
    p_admin_email VARCHAR(255),
    p_admin_name VARCHAR(255),
    p_agent_name VARCHAR(255) DEFAULT 'Assistente Virtual',
    p_system_prompt TEXT DEFAULT 'Você é um assistente virtual prestativo e educado.'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
    v_client_result JSON;
    v_admin_result JSON;
    v_agent_result JSON;
    v_errors TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Verificar se é super_admin
    IF NOT is_super_admin() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acesso negado: apenas super_admin pode fazer onboarding'
        );
    END IF;
    
    -- Passo 1: Criar cliente
    v_client_result := create_new_client(
        p_client_id,
        p_client_name,
        p_admin_email,
        NULL
    );
    
    IF NOT (v_client_result->>'success')::BOOLEAN THEN
        v_errors := array_append(v_errors, 'Cliente: ' || (v_client_result->>'error'));
    END IF;
    
    -- Passo 2: Criar admin
    v_admin_result := create_client_admin(
        p_admin_email,
        p_admin_name,
        p_client_id,
        'admin'
    );
    
    IF NOT (v_admin_result->>'success')::BOOLEAN THEN
        v_errors := array_append(v_errors, 'Admin: ' || (v_admin_result->>'error'));
    END IF;
    
    -- Passo 3: Criar agente padrão
    v_agent_result := create_default_agent(
        p_client_id,
        p_agent_name,
        p_system_prompt
    );
    
    IF NOT (v_agent_result->>'success')::BOOLEAN THEN
        v_errors := array_append(v_errors, 'Agente: ' || (v_agent_result->>'error'));
    END IF;
    
    -- Verificar se houve erros
    IF array_length(v_errors, 1) > 0 THEN
        RETURN json_build_object(
            'success', false,
            'errors', v_errors,
            'message', 'Onboarding concluído com erros'
        );
    END IF;
    
    -- Retornar sucesso completo
    v_result := json_build_object(
        'success', true,
        'client', v_client_result,
        'admin', v_admin_result,
        'agent', v_agent_result,
        'message', 'Onboarding concluído com sucesso',
        'next_steps', json_build_array(
            'Criar usuário no Supabase Auth API com user_id: ' || (v_admin_result->>'user_id'),
            'Configurar senha temporária para: ' || p_admin_email,
            'Configurar integração Chatwoot',
            'Configurar webhook N8N'
        )
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

COMMENT ON FUNCTION onboard_new_client IS 
'[SUPER_ADMIN ONLY] Processo completo de onboarding: cria cliente, admin e agente padrão';

-- ============================================================================
-- PARTE 5: Função para alterar senha do próprio usuário
-- ============================================================================

CREATE OR REPLACE FUNCTION change_my_password(
    p_current_password TEXT,
    p_new_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_email VARCHAR(255);
BEGIN
    -- Buscar email do usuário autenticado
    SELECT email INTO v_user_email
    FROM dashboard_users
    WHERE id = auth.uid();
    
    IF v_user_email IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Usuário não encontrado'
        );
    END IF;
    
    -- NOTA: Esta função apenas valida permissões
    -- A alteração real deve ser feita via Supabase Auth API
    -- usando auth.updateUser() no frontend
    
    RETURN json_build_object(
        'success', true,
        'message', 'Use supabase.auth.updateUser({ password: newPassword }) no frontend',
        'user_email', v_user_email
    );
END;
$$;

COMMENT ON FUNCTION change_my_password IS 
'Valida permissão para alteração de senha (use auth.updateUser no frontend)';

-- ============================================================================
-- PARTE 6: Grants de Permissão
-- ============================================================================

GRANT EXECUTE ON FUNCTION create_new_client TO authenticated;
GRANT EXECUTE ON FUNCTION create_client_admin TO authenticated;
GRANT EXECUTE ON FUNCTION create_default_agent TO authenticated;
GRANT EXECUTE ON FUNCTION onboard_new_client TO authenticated;
GRANT EXECUTE ON FUNCTION change_my_password TO authenticated;

-- ============================================================================
-- PARTE 7: Validação
-- ============================================================================

-- Listar funções criadas
SELECT 
    '✅ FUNÇÕES DE ONBOARDING' as tipo,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'create_new_client',
    'create_client_admin', 
    'create_default_agent',
    'onboard_new_client',
    'change_my_password'
)
ORDER BY routine_name;

COMMIT;

-- ============================================================================
-- EXEMPLO DE USO
-- ============================================================================
-- 
-- 1. ONBOARDING COMPLETO:
-- 
-- SELECT onboard_new_client(
--     'novo_cliente_001',                    -- ID do cliente
--     'Nome da Empresa Ltda',                -- Nome do cliente
--     'admin@empresa.com.br',                -- Email do admin
--     'João Silva',                          -- Nome do admin
--     'Assistente da Empresa',               -- Nome do agente IA
--     'Você é o assistente virtual da Empresa...' -- Prompt do sistema
-- );
-- 
-- 2. CRIAR APENAS CLIENTE:
-- 
-- SELECT create_new_client(
--     'novo_cliente_002',
--     'Outra Empresa Ltda',
--     'contato@outra.com.br',
--     '11999999999'
-- );
-- 
-- 3. CRIAR ADMIN PARA CLIENTE EXISTENTE:
-- 
-- SELECT create_client_admin(
--     'gestor@empresa.com.br',
--     'Maria Santos',
--     'novo_cliente_001',
--     'manager'
-- );
-- 
-- ============================================================================

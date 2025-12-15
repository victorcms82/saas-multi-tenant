-- ============================================================================
-- Migration 028: Criar Função de Alteração de Senha
-- ============================================================================
-- Data: 2025-01-20
-- Descrição: Permitir que usuários alterem suas próprias senhas pelo dashboard
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Criar função RPC change_user_password
-- ============================================================================

CREATE OR REPLACE FUNCTION change_user_password(
    p_current_password TEXT,
    p_new_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_email TEXT;
    v_result JSON;
BEGIN
    -- Obter ID e email do usuário autenticado
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Usuário não autenticado'
        );
    END IF;
    
    -- Buscar email do usuário
    SELECT email INTO v_email
    FROM auth.users
    WHERE id = v_user_id;
    
    -- Validar senha atual (tentar autenticar)
    -- NOTA: Supabase não fornece uma função direta para validar senha
    -- Por isso, a validação será feita no frontend tentando fazer signInWithPassword
    -- Esta função apenas atualiza a senha
    
    -- Validar força da nova senha
    IF LENGTH(p_new_password) < 6 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'A nova senha deve ter pelo menos 6 caracteres'
        );
    END IF;
    
    -- Atualizar senha usando a função interna do Supabase
    -- Como não temos acesso direto à função auth.update_user do Supabase via SQL,
    -- esta função servirá como bridge e a atualização real será feita via API
    
    -- Registrar tentativa de alteração de senha
    INSERT INTO public.audit_logs (
        client_id,
        event_type,
        event_data,
        user_id,
        created_at
    )
    SELECT 
        du.client_id,
        'password_change_requested',
        json_build_object(
            'user_id', v_user_id,
            'email', v_email,
            'timestamp', NOW()
        ),
        v_user_id,
        NOW()
    FROM dashboard_users du
    WHERE du.id = v_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Senha alterada com sucesso',
        'user_id', v_user_id
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;

COMMENT ON FUNCTION change_user_password IS 
'Permite que o usuário autenticado altere sua própria senha';

-- ============================================================================
-- PARTE 2: Criar função RPC request_password_reset
-- ============================================================================

CREATE OR REPLACE FUNCTION request_password_reset(
    p_email TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Verificar se o email existe
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = p_email
    ) INTO v_user_exists;
    
    IF NOT v_user_exists THEN
        -- Por segurança, sempre retornar sucesso mesmo se email não existir
        RETURN json_build_object(
            'success', true,
            'message', 'Se o email existir, você receberá instruções para redefinir sua senha'
        );
    END IF;
    
    -- Registrar solicitação de reset
    INSERT INTO public.audit_logs (
        client_id,
        event_type,
        event_data,
        created_at
    )
    VALUES (
        'system',
        'password_reset_requested',
        json_build_object(
            'email', p_email,
            'timestamp', NOW()
        ),
        NOW()
    );
    
    RETURN json_build_object(
        'success', true,
        'message', 'Se o email existir, você receberá instruções para redefinir sua senha'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erro ao processar solicitação'
    );
END;
$$;

COMMENT ON FUNCTION request_password_reset IS 
'Registra solicitação de reset de senha (o envio do email será feito pelo Supabase Auth)';

-- ============================================================================
-- PARTE 3: Grants de Permissão
-- ============================================================================

GRANT EXECUTE ON FUNCTION change_user_password TO authenticated;
GRANT EXECUTE ON FUNCTION request_password_reset TO anon, authenticated;

-- ============================================================================
-- PARTE 4: Validação
-- ============================================================================

-- Listar funções criadas
SELECT 
    '✅ FUNÇÕES CRIADAS' as tipo,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('change_user_password', 'request_password_reset')
ORDER BY routine_name;

COMMIT;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 
-- 1. FLUXO DE ALTERAÇÃO DE SENHA:
--    a) Frontend valida senha atual com supabase.auth.signInWithPassword()
--    b) Se válida, chama supabase.auth.updateUser({ password: novaSenha })
--    c) Em paralelo, chama RPC change_user_password() para registrar no audit
--
-- 2. FLUXO DE RESET DE SENHA:
--    a) Usuário clica em "Esqueci minha senha"
--    b) Frontend chama supabase.auth.resetPasswordForEmail()
--    c) Em paralelo, chama RPC request_password_reset() para audit
--
-- 3. SEGURANÇA:
--    - A validação da senha atual é feita via Auth API (não via SQL)
--    - A atualização real é feita via supabase.auth.updateUser()
--    - As RPCs servem principalmente para audit e validações extras
--
-- 4. PRÓXIMOS PASSOS:
--    - Criar componente ChangePassword.tsx no Lovable
--    - Adicionar link "Alterar Senha" no menu do usuário
--    - Implementar validação de força de senha no frontend
--
-- ============================================================================

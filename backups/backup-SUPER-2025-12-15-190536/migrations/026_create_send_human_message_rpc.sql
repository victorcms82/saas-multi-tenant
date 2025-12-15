-- ============================================================================
-- Migration 026: Criar RPC send_human_message para Dashboard
-- ============================================================================
-- Data: 2025-01-19
-- Descrição: Criar função RPC para enviar mensagens do agente humano
--
-- PROBLEMA:
-- - Dashboard tenta chamar send_human_message mas a RPC não existe
-- - Erro: POST /rest/v1/rpc/send_human_message 400 (Bad Request)
--
-- SOLUÇÃO:
-- - Criar RPC send_human_message que:
--   1. Salva mensagem na conversation_memory
--   2. Atualiza última atividade da conversa
--   3. (Opcional) Envia via Chatwoot API
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Dropar função antiga e criar nova send_human_message
-- ============================================================================

-- Dropar função antiga se existir (com qualquer assinatura)
DROP FUNCTION IF EXISTS send_human_message(UUID, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS send_human_message(UUID, TEXT);
DROP FUNCTION IF EXISTS send_human_message;

-- Criar nova função com assinatura única
CREATE OR REPLACE FUNCTION send_human_message(
    p_conversation_uuid UUID,
    p_message TEXT,
    p_client_id VARCHAR(100) DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_conversation_id INTEGER;
    v_client_id VARCHAR(100);
    v_message_uuid UUID;
    v_result JSON;
BEGIN
    -- 1. Buscar conversation_id e client_id
    SELECT 
        chatwoot_conversation_id,
        client_id
    INTO 
        v_conversation_id,
        v_client_id
    FROM conversations
    WHERE id = p_conversation_uuid;

    IF v_conversation_id IS NULL THEN
        RAISE EXCEPTION 'Conversa não encontrada: %', p_conversation_uuid;
    END IF;

    -- Se client_id não foi passado, usar o da conversa
    IF p_client_id IS NULL THEN
        p_client_id := v_client_id;
    END IF;

    -- 2. Salvar mensagem na conversation_memory
    INSERT INTO conversation_memory (
        conversation_id,
        conversation_uuid,
        client_id,
        message_role,
        message_content,
        sender_name,
        message_timestamp,
        has_attachments,
        attachments,
        metadata
    ) VALUES (
        v_conversation_id,
        p_conversation_uuid,
        p_client_id,
        'user',  -- Mensagem do agente humano é tratada como 'user'
        p_message,
        'Agente Humano',  -- TODO: Pegar nome do usuário logado
        NOW(),
        false,
        '[]'::JSONB,
        jsonb_build_object(
            'sent_by', 'dashboard',
            'sent_at', NOW()
        )
    )
    RETURNING id INTO v_message_uuid;

    -- 3. Atualizar última atividade da conversa
    UPDATE conversations
    SET 
        last_message_at = NOW(),
        updated_at = NOW()
    WHERE id = p_conversation_uuid;

    -- 4. Retornar resultado
    v_result := json_build_object(
        'success', true,
        'message_id', v_message_uuid,
        'conversation_id', v_conversation_id,
        'conversation_uuid', p_conversation_uuid,
        'timestamp', NOW()
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        -- Log do erro
        RAISE WARNING 'Erro em send_human_message: %', SQLERRM;
        
        -- Retornar erro como JSON
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- ============================================================================
-- PARTE 2: Criar função takeover_conversation (assumir conversa)
-- ============================================================================

-- Dropar função antiga se existir
DROP FUNCTION IF EXISTS takeover_conversation(UUID);
DROP FUNCTION IF EXISTS takeover_conversation;

CREATE OR REPLACE FUNCTION takeover_conversation(
    p_conversation_uuid UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Atualizar status para "Em Atendimento" (status_id = 1)
    UPDATE conversations
    SET 
        status_id = 1,  -- 1 = Em Atendimento
        updated_at = NOW()
    WHERE id = p_conversation_uuid;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Conversa não encontrada: %', p_conversation_uuid;
    END IF;

    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'conversation_uuid', p_conversation_uuid,
        'new_status_id', 1,
        'timestamp', NOW()
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Erro em takeover_conversation: %', SQLERRM;
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- ============================================================================
-- PARTE 3: Criar função return_to_ai (devolver para IA)
-- ============================================================================

-- Dropar função antiga se existir
DROP FUNCTION IF EXISTS return_to_ai(UUID);
DROP FUNCTION IF EXISTS return_to_ai;

CREATE OR REPLACE FUNCTION return_to_ai(
    p_conversation_uuid UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Atualizar status para "Precisa Atenção" (status_id = 2)
    UPDATE conversations
    SET 
        status_id = 2,  -- 2 = Precisa Atenção (IA assume)
        updated_at = NOW()
    WHERE id = p_conversation_uuid;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Conversa não encontrada: %', p_conversation_uuid;
    END IF;

    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'conversation_uuid', p_conversation_uuid,
        'new_status_id', 2,
        'timestamp', NOW()
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Erro em return_to_ai: %', SQLERRM;
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- ============================================================================
-- PARTE 4: Comentários e Documentação
-- ============================================================================

COMMENT ON FUNCTION send_human_message IS 
'Envia mensagem do agente humano (via dashboard) e salva na conversation_memory';

COMMENT ON FUNCTION takeover_conversation IS 
'Assume conversa (muda status para "Em Atendimento")';

COMMENT ON FUNCTION return_to_ai IS 
'Devolve conversa para IA (muda status para "Precisa Atenção")';

-- ============================================================================
-- PARTE 5: Grants de Permissão
-- ============================================================================

-- Permitir acesso autenticado às funções
GRANT EXECUTE ON FUNCTION send_human_message TO authenticated;
GRANT EXECUTE ON FUNCTION takeover_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION return_to_ai TO authenticated;

-- ============================================================================
-- PARTE 6: Validação
-- ============================================================================

-- Testar send_human_message
DO $$
DECLARE
    v_test_result JSON;
BEGIN
    -- Teste com conversa da Maria Silva
    SELECT send_human_message(
        'ed7108e3-95d4-4afd-b0ce-4c93b058ee1b'::UUID,
        'Teste de mensagem do agente humano',
        'clinica_sorriso_001'
    ) INTO v_test_result;
    
    RAISE NOTICE '✅ Teste send_human_message: %', v_test_result::TEXT;
END;
$$;

-- Listar funções criadas
SELECT 
    '✅ FUNÇÕES CRIADAS' as tipo,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('send_human_message', 'takeover_conversation', 'return_to_ai')
ORDER BY routine_name;

COMMIT;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 
-- 1. FLUXO DE USO:
--    a) Dashboard chama takeover_conversation() → status_id = 1
--    b) Agente envia mensagens via send_human_message()
--    c) Dashboard chama return_to_ai() → status_id = 2
--
-- 2. INTEGRAÇÃO LOVABLE:
--    - Trocar chamadas diretas ao Supabase por essas RPCs
--    - Exemplo: await supabase.rpc('send_human_message', { ... })
--
-- 3. SEGURANÇA:
--    - SECURITY DEFINER permite acesso controlado
--    - authenticated garante que apenas usuários logados podem usar
--    - TODO: Adicionar verificação de permissões por client_id
--
-- 4. PRÓXIMOS PASSOS:
--    - Adicionar integração com Chatwoot API em send_human_message
--    - Adicionar log de auditoria (quem assumiu, quando, etc)
--    - Adicionar notificações (email/webhook quando conversa assumida)
--
-- ============================================================================

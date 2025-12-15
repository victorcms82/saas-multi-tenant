-- ============================================================================
-- Migration 029: Corrigir função create_default_agent
-- ============================================================================
-- Descrição: Atualiza create_default_agent para preencher TODAS as colunas 
--            NOT NULL da tabela agents (id, agent_id, system_prompt, rag_namespace)
-- Data: 2025-11-20
-- ============================================================================

-- Remover versões antigas da função
DROP FUNCTION IF EXISTS create_default_agent(VARCHAR, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS create_default_agent(VARCHAR, VARCHAR);

-- Criar versão corrigida com todos os campos obrigatórios
CREATE OR REPLACE FUNCTION create_default_agent(
    p_client_id VARCHAR(100),
    p_agent_name VARCHAR(255) DEFAULT 'Assistente Virtual',
    p_system_prompt TEXT DEFAULT 'Você é um assistente virtual prestativo e educado. Ajude os clientes com suas dúvidas de forma clara e objetiva.'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
    v_agent_id VARCHAR(100);
    v_rag_namespace VARCHAR(255);
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
    
    -- Gerar valores para campos obrigatórios
    v_id := gen_random_uuid();                    -- UUID para chave primária
    v_agent_id := 'default';                      -- Identificador do agente
    v_rag_namespace := p_client_id || '/default'; -- Namespace RAG
    
    -- Inserir agente com TODOS os campos NOT NULL
    INSERT INTO agents (
        id,
        agent_id,
        client_id,
        agent_name,
        system_prompt,
        rag_namespace,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_id,
        v_agent_id,
        p_client_id,
        p_agent_name,
        p_system_prompt,
        v_rag_namespace,
        true,
        NOW(),
        NOW()
    );
    
    -- Retornar sucesso com dados criados
    RETURN json_build_object(
        'success', true,
        'id', v_id::TEXT,
        'agent_id', v_agent_id,
        'rag_namespace', v_rag_namespace,
        'message', 'Agente criado com sucesso'
    );
END;
$$;

COMMENT ON FUNCTION create_default_agent IS 
'[SUPER_ADMIN ONLY] Cria agente IA padrão para um cliente com todos os campos obrigatórios preenchidos';

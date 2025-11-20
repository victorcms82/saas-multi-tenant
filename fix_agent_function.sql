-- Corrigir função create_default_agent
DROP FUNCTION IF EXISTS create_default_agent(VARCHAR, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS create_default_agent(VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION create_default_agent(
    p_client_id VARCHAR(100),
    p_agent_name VARCHAR(255) DEFAULT 'Assistente Virtual'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_agent_id UUID;
    v_client_exists BOOLEAN;
BEGIN
    IF NOT is_super_admin() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acesso negado: apenas super_admin pode criar agentes'
        );
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM clients WHERE client_id = p_client_id) 
    INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cliente não existe'
        );
    END IF;
    
    v_agent_id := gen_random_uuid();
    
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
    
    RETURN json_build_object(
        'success', true,
        'agent_id', v_agent_id::TEXT,
        'message', 'Agente criado com sucesso'
    );
END;
$$;

-- ============================================================================
-- Migration 019: Criar Sistema de Memória de Conversação
-- ============================================================================
-- Descrição: Implementa tabela para armazenar histórico de mensagens
--            Permite que o bot mantenha contexto entre mensagens
--            Inclui TTL automático para limpeza de mensagens antigas
-- ============================================================================
-- Autor: AI Assistant
-- Data: 2025-11-12
-- ============================================================================

-- ============================================================================
-- 1. Criar Tabela conversation_memory
-- ============================================================================

CREATE TABLE IF NOT EXISTS conversation_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identificação (multi-tenant)
    client_id VARCHAR(100) NOT NULL,
    conversation_id INTEGER NOT NULL,
    
    -- Dados da mensagem
    message_role VARCHAR(20) NOT NULL CHECK (message_role IN ('user', 'assistant', 'system')),
    message_content TEXT NOT NULL,
    message_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadados
    contact_id INTEGER,
    agent_id VARCHAR(100) DEFAULT 'default',
    channel VARCHAR(50) DEFAULT 'whatsapp',
    
    -- Dados adicionais
    has_attachments BOOLEAN DEFAULT FALSE,
    attachments JSONB DEFAULT '[]'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Controle
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Índices para performance
    CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE
);

-- ============================================================================
-- 2. Criar Índices
-- ============================================================================

-- Índice composto para busca rápida de histórico
CREATE INDEX IF NOT EXISTS idx_conversation_memory_lookup 
ON conversation_memory(client_id, conversation_id, message_timestamp DESC);

-- Índice para limpeza por data
CREATE INDEX IF NOT EXISTS idx_conversation_memory_cleanup 
ON conversation_memory(created_at);

-- Índice para busca por contact_id
CREATE INDEX IF NOT EXISTS idx_conversation_memory_contact 
ON conversation_memory(contact_id);

-- ============================================================================
-- 3. Habilitar RLS (Row Level Security)
-- ============================================================================

ALTER TABLE conversation_memory ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT - Usuários só podem ver mensagens do próprio tenant
CREATE POLICY conversation_memory_select_policy
ON conversation_memory
FOR SELECT
USING (
    client_id = current_setting('app.current_client_id', true)
);

-- Policy: INSERT - Usuários só podem inserir mensagens no próprio tenant
CREATE POLICY conversation_memory_insert_policy
ON conversation_memory
FOR INSERT
WITH CHECK (
    client_id = current_setting('app.current_client_id', true)
);

-- Policy: DELETE - Usuários só podem deletar mensagens do próprio tenant
CREATE POLICY conversation_memory_delete_policy
ON conversation_memory
FOR DELETE
USING (
    client_id = current_setting('app.current_client_id', true)
);

-- ============================================================================
-- 4. Criar Função RPC: get_conversation_history
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversation_history(
    p_client_id VARCHAR(100),
    p_conversation_id INTEGER,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    message_role VARCHAR(20),
    message_content TEXT,
    message_timestamp TIMESTAMP WITH TIME ZONE,
    has_attachments BOOLEAN,
    contact_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Dupla validação de segurança
    PERFORM set_config('app.current_client_id', p_client_id, true);
    
    RETURN QUERY
    SELECT 
        cm.message_role,
        cm.message_content,
        cm.message_timestamp,
        cm.has_attachments,
        cm.contact_id
    FROM conversation_memory cm
    WHERE 
        cm.client_id = p_client_id
        AND cm.conversation_id = p_conversation_id
    ORDER BY cm.message_timestamp DESC
    LIMIT p_limit;
END;
$$;

-- ============================================================================
-- 5. Criar Função RPC: save_conversation_message
-- ============================================================================

CREATE OR REPLACE FUNCTION save_conversation_message(
    p_client_id VARCHAR(100),
    p_conversation_id INTEGER,
    p_message_role VARCHAR(20),
    p_message_content TEXT,
    p_contact_id INTEGER DEFAULT NULL,
    p_agent_id VARCHAR(100) DEFAULT 'default',
    p_channel VARCHAR(50) DEFAULT 'whatsapp',
    p_has_attachments BOOLEAN DEFAULT FALSE,
    p_attachments JSONB DEFAULT '[]'::jsonb,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_message_id UUID;
BEGIN
    -- Validação de segurança
    PERFORM set_config('app.current_client_id', p_client_id, true);
    
    -- Validar role
    IF p_message_role NOT IN ('user', 'assistant', 'system') THEN
        RAISE EXCEPTION 'Invalid message_role. Must be: user, assistant, or system';
    END IF;
    
    -- Inserir mensagem
    INSERT INTO conversation_memory (
        client_id,
        conversation_id,
        message_role,
        message_content,
        contact_id,
        agent_id,
        channel,
        has_attachments,
        attachments,
        metadata
    ) VALUES (
        p_client_id,
        p_conversation_id,
        p_message_role,
        p_message_content,
        p_contact_id,
        p_agent_id,
        p_channel,
        p_has_attachments,
        p_attachments,
        p_metadata
    )
    RETURNING id INTO v_message_id;
    
    RETURN v_message_id;
END;
$$;

-- ============================================================================
-- 6. Criar Função de Limpeza Automática (TTL)
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_old_conversation_memory(
    p_days_to_keep INTEGER DEFAULT 30
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM conversation_memory
    WHERE created_at < NOW() - INTERVAL '1 day' * p_days_to_keep;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$;

-- ============================================================================
-- 7. Comentários para Documentação
-- ============================================================================

COMMENT ON TABLE conversation_memory IS 'Armazena histórico de mensagens das conversas para manter contexto entre interações';
COMMENT ON COLUMN conversation_memory.message_role IS 'Papel da mensagem: user (cliente), assistant (bot), system (instruções)';
COMMENT ON COLUMN conversation_memory.message_content IS 'Conteúdo da mensagem enviada ou recebida';
COMMENT ON COLUMN conversation_memory.metadata IS 'Dados adicionais como tokens usados, tempo de resposta, etc';

COMMENT ON FUNCTION get_conversation_history IS 'Busca últimas N mensagens de uma conversa específica, ordenadas da mais recente para mais antiga';
COMMENT ON FUNCTION save_conversation_message IS 'Salva uma nova mensagem no histórico da conversa';
COMMENT ON FUNCTION cleanup_old_conversation_memory IS 'Remove mensagens antigas do histórico (padrão: 30 dias)';

-- ============================================================================
-- 8. Grants de Permissão
-- ============================================================================

-- Permitir acesso anônimo (via API) às funções RPC
GRANT EXECUTE ON FUNCTION get_conversation_history TO anon, authenticated;
GRANT EXECUTE ON FUNCTION save_conversation_message TO anon, authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_conversation_memory TO postgres, authenticated;

-- ============================================================================
-- FIM DA MIGRATION 019
-- ============================================================================

-- Para aplicar esta migration, execute:
-- psql -h <HOST> -p 5432 -U postgres -d postgres -f 019_create_conversation_memory.sql

-- Para testar:
-- SELECT * FROM get_conversation_history('estetica_bella_rede', 6, 5);

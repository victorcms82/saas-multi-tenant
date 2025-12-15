-- ============================================================================
-- Migration 021: Tabela de Configuração de Memória por Agente/Cliente
-- ============================================================================
-- Permite configurar memória (tempo + quantidade) dinamicamente por agente
-- ============================================================================

-- Criar tabela de configuração de memória
CREATE TABLE IF NOT EXISTS memory_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id VARCHAR(100) NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
    agent_id VARCHAR(100) NOT NULL DEFAULT 'default',
    
    -- Configurações de memória
    memory_limit INTEGER DEFAULT 50,           -- Quantidade máxima de mensagens
    memory_hours_back INTEGER DEFAULT 24,      -- Janela de tempo em horas
    memory_enabled BOOLEAN DEFAULT true,       -- Habilitar/desabilitar memória
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint: 1 configuração por cliente + agente
    UNIQUE(client_id, agent_id)
);

-- Comentários
COMMENT ON TABLE memory_config IS 'Configurações de memória de conversa por agente e cliente';
COMMENT ON COLUMN memory_config.memory_limit IS 'Número máximo de mensagens a buscar no histórico';
COMMENT ON COLUMN memory_config.memory_hours_back IS 'Janela de tempo em horas para buscar mensagens (NULL = sem limite)';
COMMENT ON COLUMN memory_config.memory_enabled IS 'Se false, agente não terá memória';

-- Índices
CREATE INDEX idx_memory_config_lookup ON memory_config(client_id, agent_id);

-- RLS Policies
ALTER TABLE memory_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "memory_config_select_policy" ON memory_config
    FOR SELECT USING (client_id = current_setting('app.current_client_id', true));

CREATE POLICY "memory_config_insert_policy" ON memory_config
    FOR INSERT WITH CHECK (client_id = current_setting('app.current_client_id', true));

CREATE POLICY "memory_config_update_policy" ON memory_config
    FOR UPDATE USING (client_id = current_setting('app.current_client_id', true));

CREATE POLICY "memory_config_delete_policy" ON memory_config
    FOR DELETE USING (client_id = current_setting('app.current_client_id', true));

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON memory_config TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON memory_config TO authenticated;

-- ============================================================================
-- Função RPC: Buscar configuração de memória
-- ============================================================================

CREATE OR REPLACE FUNCTION get_memory_config(
    p_client_id VARCHAR,
    p_agent_id VARCHAR DEFAULT 'default'
)
RETURNS TABLE(
    memory_limit INTEGER,
    memory_hours_back INTEGER,
    memory_enabled BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Configurar client_id para RLS
    PERFORM set_config('app.current_client_id', p_client_id, true);
    
    -- Buscar configuração específica do agente
    RETURN QUERY
    SELECT 
        mc.memory_limit,
        mc.memory_hours_back,
        mc.memory_enabled
    FROM memory_config mc
    WHERE mc.client_id = p_client_id
      AND mc.agent_id = p_agent_id
    LIMIT 1;
    
    -- Se não encontrar, retornar configuração padrão
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            50::INTEGER as memory_limit,           -- Padrão: 50 mensagens
            24::INTEGER as memory_hours_back,      -- Padrão: 24 horas
            true::BOOLEAN as memory_enabled;       -- Padrão: habilitado
    END IF;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_memory_config(VARCHAR, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION get_memory_config(VARCHAR, VARCHAR) TO authenticated;

-- ============================================================================
-- Inserir configurações padrão para clientes existentes
-- ============================================================================

INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
SELECT 
    client_id,
    'default' as agent_id,
    50 as memory_limit,
    24 as memory_hours_back,
    true as memory_enabled
FROM clients
ON CONFLICT (client_id, agent_id) DO NOTHING;

-- ============================================================================
-- EXEMPLOS DE USO:
-- ============================================================================

-- Buscar configuração do agente 'default' da Bella Estética
-- SELECT * FROM get_memory_config('estetica_bella_rede', 'default');

-- Inserir/atualizar configuração personalizada
-- INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
-- VALUES ('estetica_bella_rede', 'default', 100, 72, true)
-- ON CONFLICT (client_id, agent_id) 
-- DO UPDATE SET 
--   memory_limit = EXCLUDED.memory_limit,
--   memory_hours_back = EXCLUDED.memory_hours_back,
--   memory_enabled = EXCLUDED.memory_enabled,
--   updated_at = NOW();

-- Desabilitar memória para um agente específico
-- UPDATE memory_config 
-- SET memory_enabled = false, updated_at = NOW()
-- WHERE client_id = 'estetica_bella_rede' AND agent_id = 'default';

-- ============================================================================
-- CONFIGURAÇÕES SUGERIDAS POR TIPO DE NEGÓCIO:
-- ============================================================================
-- Atendimento rápido (fast food, delivery):
--   memory_limit: 20, memory_hours_back: 3 (3 horas)
--
-- Atendimento médio (ecommerce, suporte):
--   memory_limit: 50, memory_hours_back: 24 (1 dia)
--
-- Atendimento complexo (healthcare, legal):
--   memory_limit: 100, memory_hours_back: 168 (1 semana)
--
-- Relacionamento longo prazo (CRM, consultoria):
--   memory_limit: 200, memory_hours_back: 720 (1 mês)
-- ============================================================================

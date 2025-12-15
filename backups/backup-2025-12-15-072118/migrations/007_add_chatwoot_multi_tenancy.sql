-- Migration 007: Adicionar colunas Chatwoot à tabela clients
-- Permite mapear cada cliente a uma Inbox específica

-- Adicionar colunas para Chatwoot multi-tenancy
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS chatwoot_inbox_id INTEGER,
ADD COLUMN IF NOT EXISTS chatwoot_agent_id INTEGER,
ADD COLUMN IF NOT EXISTS chatwoot_agent_email TEXT,
ADD COLUMN IF NOT EXISTS chatwoot_access_granted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS chatwoot_setup_at TIMESTAMPTZ;

-- Comentários
COMMENT ON COLUMN clients.chatwoot_inbox_id IS 'ID da Inbox do Chatwoot específica do cliente';
COMMENT ON COLUMN clients.chatwoot_agent_id IS 'ID do Agent do Chatwoot criado para o cliente';
COMMENT ON COLUMN clients.chatwoot_agent_email IS 'Email do Agent (cliente) no Chatwoot';
COMMENT ON COLUMN clients.chatwoot_access_granted IS 'Se o cliente tem acesso ao Chatwoot';
COMMENT ON COLUMN clients.chatwoot_setup_at IS 'Data/hora da configuração do Chatwoot';

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_clients_chatwoot_inbox ON clients(chatwoot_inbox_id);
CREATE INDEX IF NOT EXISTS idx_clients_chatwoot_agent ON clients(chatwoot_agent_id);

-- Atualizar client de teste (clinica_sorriso_001)
-- Você vai rodar isso APÓS criar a Inbox pelo script
-- UPDATE clients 
-- SET 
--   chatwoot_inbox_id = 123,  -- Substituir pelo ID real
--   chatwoot_agent_id = 456,  -- Substituir pelo ID real
--   chatwoot_agent_email = 'joao@clinicasorriso.com.br',
--   chatwoot_access_granted = TRUE,
--   chatwoot_setup_at = NOW()
-- WHERE client_id = 'clinica_sorriso_001';

SELECT 'Migration 007 concluída com sucesso!' AS resultado;

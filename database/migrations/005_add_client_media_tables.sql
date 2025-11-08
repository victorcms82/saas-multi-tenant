-- ============================================================================
-- MIGRATION 005: Client Media & Send Rules
-- ============================================================================
-- Tabelas para armazenar mídia do CLIENTE (acervo) e regras de envio

-- 1. Tabela de Mídia do Cliente (Acervo)
CREATE TABLE IF NOT EXISTS client_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id TEXT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  agent_id TEXT, -- Opcional: mídia específica por agente
  
  -- Arquivo
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('image', 'video', 'document', 'audio')),
  file_url TEXT NOT NULL, -- URL do Supabase Storage
  file_size_bytes BIGINT,
  mime_type TEXT,
  
  -- Metadata para busca e organização
  title TEXT,
  description TEXT,
  tags TEXT[] DEFAULT '{}', -- Ex: ['consultorio', 'recepcao', 'unidade_centro']
  category TEXT, -- Ex: 'branding', 'facilities', 'team', 'services'
  
  -- Controle
  is_active BOOLEAN DEFAULT true,
  upload_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Foreign key para agent (se especificado)
  FOREIGN KEY (client_id, agent_id) REFERENCES agents(client_id, agent_id) ON DELETE CASCADE
);

-- Índices para busca rápida
CREATE INDEX idx_client_media_client ON client_media(client_id);
CREATE INDEX idx_client_media_agent ON client_media(client_id, agent_id);
CREATE INDEX idx_client_media_tags ON client_media USING GIN(tags);
CREATE INDEX idx_client_media_type ON client_media(file_type);
CREATE INDEX idx_client_media_category ON client_media(category);
CREATE INDEX idx_client_media_active ON client_media(is_active) WHERE is_active = true;

COMMENT ON TABLE client_media IS 'Acervo de mídia do cliente (fotos, vídeos, documentos)';
COMMENT ON COLUMN client_media.client_id IS 'ID do cliente dono da mídia';
COMMENT ON COLUMN client_media.agent_id IS 'ID do agente (se mídia for específica)';
COMMENT ON COLUMN client_media.tags IS 'Tags para busca: consultorio, equipe, unidade_x, etc';
COMMENT ON COLUMN client_media.category IS 'Categoria: branding, facilities, team, services';

-- 2. Tabela de Regras de Envio de Mídia
CREATE TABLE IF NOT EXISTS media_send_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id TEXT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  agent_id TEXT, -- Opcional: regra específica por agente
  
  -- Tipo de regra
  rule_type TEXT NOT NULL CHECK (rule_type IN ('keyword_trigger', 'conversation_phase', 'llm_decision')),
  rule_name TEXT, -- Nome descritivo da regra
  
  -- Regra: Keyword Trigger
  keywords TEXT[], -- Ex: ['unidade centro', 'consultório', 'equipe']
  match_type TEXT DEFAULT 'contains' CHECK (match_type IN ('contains', 'exact', 'regex')),
  
  -- Regra: Conversation Phase
  message_number INTEGER, -- Enviar na mensagem N (1-based)
  message_range INT4RANGE, -- Ou em um range: [5,10] = mensagens 5 a 10
  
  -- Regra: LLM Decision
  llm_prompt TEXT, -- Prompt para LLM decidir: "Se cliente perguntar sobre X, envie esta mídia"
  
  -- Mídia a enviar
  media_id UUID REFERENCES client_media(id) ON DELETE CASCADE,
  
  -- Controle
  priority INTEGER DEFAULT 1, -- Prioridade (menor = maior prioridade)
  is_active BOOLEAN DEFAULT true,
  send_once BOOLEAN DEFAULT false, -- Enviar apenas uma vez por conversa?
  cooldown_hours INTEGER, -- Cooldown entre envios (NULL = sem cooldown)
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Foreign key para agent (se especificado)
  FOREIGN KEY (client_id, agent_id) REFERENCES agents(client_id, agent_id) ON DELETE CASCADE
);

-- Índices
CREATE INDEX idx_media_rules_client ON media_send_rules(client_id);
CREATE INDEX idx_media_rules_agent ON media_send_rules(client_id, agent_id);
CREATE INDEX idx_media_rules_type ON media_send_rules(rule_type);
CREATE INDEX idx_media_rules_keywords ON media_send_rules USING GIN(keywords);
CREATE INDEX idx_media_rules_active ON media_send_rules(is_active) WHERE is_active = true;

COMMENT ON TABLE media_send_rules IS 'Regras de quando enviar mídia do acervo';
COMMENT ON COLUMN media_send_rules.rule_type IS 'Tipo: keyword_trigger, conversation_phase, llm_decision';
COMMENT ON COLUMN media_send_rules.keywords IS 'Palavras-chave que disparam envio (keyword_trigger)';
COMMENT ON COLUMN media_send_rules.message_number IS 'Número da mensagem para envio (conversation_phase)';
COMMENT ON COLUMN media_send_rules.send_once IS 'Enviar apenas uma vez por conversa?';

-- 3. Tabela de Log de Envios (para controle de send_once e cooldown)
CREATE TABLE IF NOT EXISTS media_send_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id TEXT NOT NULL,
  agent_id TEXT,
  conversation_id TEXT NOT NULL, -- ID da conversa no Chatwoot
  
  rule_id UUID REFERENCES media_send_rules(id) ON DELETE SET NULL,
  media_id UUID REFERENCES client_media(id) ON DELETE SET NULL,
  
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata
  triggered_by TEXT, -- 'keyword', 'phase', 'llm_decision'
  trigger_value TEXT -- Qual keyword, qual fase, etc
);

CREATE INDEX idx_media_log_conversation ON media_send_log(conversation_id);
CREATE INDEX idx_media_log_client ON media_send_log(client_id);
CREATE INDEX idx_media_log_rule ON media_send_log(rule_id);

COMMENT ON TABLE media_send_log IS 'Log de envios de mídia (para send_once e cooldown)';

-- 4. Function para buscar mídia por tags
CREATE OR REPLACE FUNCTION search_client_media(
  p_client_id TEXT,
  p_agent_id TEXT DEFAULT NULL,
  p_tags TEXT[] DEFAULT NULL,
  p_file_type TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
  media_id UUID,
  file_name TEXT,
  file_url TEXT,
  file_type TEXT,
  tags TEXT[],
  title TEXT,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.id,
    cm.file_name,
    cm.file_url,
    cm.file_type,
    cm.tags,
    cm.title,
    cm.description
  FROM client_media cm
  WHERE cm.client_id = p_client_id
    AND cm.is_active = true
    AND (p_agent_id IS NULL OR cm.agent_id = p_agent_id OR cm.agent_id IS NULL)
    AND (p_tags IS NULL OR cm.tags && p_tags) -- Overlap de tags
    AND (p_file_type IS NULL OR cm.file_type = p_file_type)
    AND (p_category IS NULL OR cm.category = p_category)
  ORDER BY cm.created_at DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION search_client_media IS 'Buscar mídia do cliente por tags, tipo, categoria';

-- 5. Dados de exemplo (REMOVER EM PRODUÇÃO)
DO $$
BEGIN
  -- Exemplo de mídia para clinica_sorriso_001
  INSERT INTO client_media (client_id, agent_id, file_name, file_type, file_url, title, description, tags, category)
  VALUES 
    (
      'clinica_sorriso_001',
      'default',
      'consultorio-recepcao.jpg',
      'image',
      'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/consultorio-recepcao.jpg',
      'Recepção do Consultório',
      'Foto da recepção moderna e aconchegante',
      ARRAY['consultorio', 'recepcao', 'ambiente'],
      'facilities'
    ),
    (
      'clinica_sorriso_001',
      'default',
      'equipe-completa.jpg',
      'image',
      'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/equipe-completa.jpg',
      'Equipe Clínica Sorriso',
      'Foto da equipe completa de dentistas e recepcionistas',
      ARRAY['equipe', 'time', 'profissionais'],
      'team'
    ),
    (
      'clinica_sorriso_001',
      'default',
      'cardapio-servicos.pdf',
      'document',
      'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/cardapio-servicos.pdf',
      'Cardápio de Serviços',
      'Lista completa de tratamentos e preços',
      ARRAY['servicos', 'precos', 'tratamentos'],
      'services'
    );
  
  -- Exemplos de regras
  INSERT INTO media_send_rules (client_id, agent_id, rule_type, rule_name, keywords, media_id, priority)
  VALUES
    (
      'clinica_sorriso_001',
      'default',
      'keyword_trigger',
      'Enviar foto consultório quando perguntar',
      ARRAY['consultório', 'consultorio', 'ambiente', 'onde fica'],
      (SELECT id FROM client_media WHERE file_name = 'consultorio-recepcao.jpg' LIMIT 1),
      1
    ),
    (
      'clinica_sorriso_001',
      'default',
      'keyword_trigger',
      'Enviar foto equipe quando perguntar',
      ARRAY['equipe', 'time', 'dentistas', 'profissionais'],
      (SELECT id FROM client_media WHERE file_name = 'equipe-completa.jpg' LIMIT 1),
      2
    ),
    (
      'clinica_sorriso_001',
      'default',
      'conversation_phase',
      'Enviar cardápio na 5ª mensagem',
      NULL,
      (SELECT id FROM client_media WHERE file_name = 'cardapio-servicos.pdf' LIMIT 1),
      3
    );
    
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'MIGRATION 005: Client Media - EXECUTADA';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Tabelas criadas:';
  RAISE NOTICE '  ✅ client_media (acervo de mídia)';
  RAISE NOTICE '  ✅ media_send_rules (regras de envio)';
  RAISE NOTICE '  ✅ media_send_log (histórico)';
  RAISE NOTICE '';
  RAISE NOTICE 'Function criada:';
  RAISE NOTICE '  ✅ search_client_media()';
  RAISE NOTICE '';
  RAISE NOTICE 'Dados de exemplo inseridos:';
  RAISE NOTICE '  📸 3 mídias para clinica_sorriso_001';
  RAISE NOTICE '  📋 3 regras de envio';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;

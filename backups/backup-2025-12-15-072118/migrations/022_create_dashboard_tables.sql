-- ============================================================================
-- MIGRATION 022: Criar Estrutura Completa para Dashboard
-- ============================================================================
-- Data: 17/11/2025
-- Descrição: Adiciona tabelas e campos necessários para o dashboard funcionar:
--            - Tabela conversations (metadados das conversas)
--            - Tabela dashboard_users (autenticação)
--            - Sistema de takeover (assumir conversa)
--            - Atualizar conversation_memory com campos necessários
--            - Funções RPC otimizadas
-- ============================================================================

-- ============================================================================
-- PARTE 1: Criar Tabela CONVERSATIONS (Metadados das Conversas)
-- ============================================================================

CREATE TABLE IF NOT EXISTS conversations (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Multi-tenancy
  client_id TEXT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  agent_id TEXT NOT NULL DEFAULT 'default',
  
  -- Identificação Externa (Chatwoot)
  chatwoot_conversation_id INTEGER NOT NULL,
  chatwoot_inbox_id INTEGER,
  chatwoot_account_id INTEGER DEFAULT 1,
  
  -- Dados do Cliente/Contato
  customer_name TEXT,
  customer_phone TEXT,
  customer_email TEXT,
  customer_avatar_url TEXT,
  chatwoot_contact_id INTEGER,
  
  -- Status da Conversa
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'needs_human', 'human_takeover', 'resolved', 'archived')
  ),
  
  -- Sistema de Takeover (Assumir Conversa)
  assigned_to UUID REFERENCES auth.users(id), -- Usuário que assumiu
  taken_over_at TIMESTAMPTZ, -- Quando foi assumido
  taken_over_by_name TEXT, -- Nome de quem assumiu
  ai_paused BOOLEAN DEFAULT false, -- IA está pausada?
  
  -- Contadores
  unread_count INTEGER DEFAULT 0,
  total_messages INTEGER DEFAULT 0,
  
  -- Última Atividade
  last_message_content TEXT,
  last_message_timestamp TIMESTAMPTZ,
  last_message_sender TEXT, -- 'customer', 'agent_ai', 'agent_human'
  
  -- Metadata
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  tags TEXT[] DEFAULT '{}',
  notes TEXT,
  custom_attributes JSONB DEFAULT '{}',
  
  -- Tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT unique_chatwoot_conversation UNIQUE (chatwoot_conversation_id),
  CONSTRAINT conversations_client_agent_fk 
    FOREIGN KEY (client_id, agent_id) 
    REFERENCES agents(client_id, agent_id)
    ON DELETE CASCADE
);

-- Comentários
COMMENT ON TABLE conversations IS 'Metadados das conversas do Chatwoot com sistema de takeover';
COMMENT ON COLUMN conversations.status IS 'active=IA atendendo | needs_human=precisa atenção | human_takeover=humano assumiu | resolved=finalizada';
COMMENT ON COLUMN conversations.assigned_to IS 'ID do usuário do dashboard que assumiu a conversa';
COMMENT ON COLUMN conversations.ai_paused IS 'TRUE quando humano assume, FALSE quando IA está ativa';

-- Índices
CREATE INDEX idx_conversations_client_agent ON conversations(client_id, agent_id);
CREATE INDEX idx_conversations_status ON conversations(status) WHERE status IN ('active', 'needs_human', 'human_takeover');
CREATE INDEX idx_conversations_chatwoot ON conversations(chatwoot_conversation_id);
CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC);
CREATE INDEX idx_conversations_assigned ON conversations(assigned_to) WHERE assigned_to IS NOT NULL;

-- Trigger para updated_at
CREATE TRIGGER on_conversations_updated 
  BEFORE UPDATE ON conversations 
  FOR EACH ROW 
  EXECUTE FUNCTION handle_updated_at();

-- ============================================================================
-- PARTE 2: Criar Tabela DASHBOARD_USERS (Autenticação)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dashboard_users (
  -- Identificação
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Vinculação com Cliente
  client_id TEXT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  
  -- Dados do Usuário
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  
  -- Permissões
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (
    role IN ('owner', 'admin', 'operator', 'viewer')
  ),
  
  -- Configurações Pessoais
  preferences JSONB DEFAULT '{
    "notifications": {
      "browser": true,
      "sound": true,
      "whatsapp": false,
      "email_digest": true
    },
    "theme": "light",
    "language": "pt-BR"
  }'::jsonb,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  
  -- Tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_user_client UNIQUE (id, client_id)
);

-- Comentários
COMMENT ON TABLE dashboard_users IS 'Usuários do dashboard vinculados aos clientes';
COMMENT ON COLUMN dashboard_users.role IS 'owner=dono | admin=administrador | operator=atendente | viewer=visualizador';

-- Índices
CREATE INDEX idx_dashboard_users_client ON dashboard_users(client_id);
CREATE INDEX idx_dashboard_users_email ON dashboard_users(email);
CREATE INDEX idx_dashboard_users_active ON dashboard_users(is_active) WHERE is_active = true;

-- Trigger para updated_at
CREATE TRIGGER on_dashboard_users_updated 
  BEFORE UPDATE ON dashboard_users 
  FOR EACH ROW 
  EXECUTE FUNCTION handle_updated_at();

-- ============================================================================
-- PARTE 3: Atualizar Tabela CONVERSATION_MEMORY (Campos Adicionais)
-- ============================================================================

-- Adicionar referência para conversation UUID (se não existir)
ALTER TABLE conversation_memory 
  ADD COLUMN IF NOT EXISTS conversation_uuid UUID REFERENCES conversations(id) ON DELETE CASCADE;

-- Adicionar campos de sender (se não existirem)
ALTER TABLE conversation_memory
  ADD COLUMN IF NOT EXISTS sender_name TEXT,
  ADD COLUMN IF NOT EXISTS sender_avatar_url TEXT;

-- Adicionar índice para busca por conversation_uuid
CREATE INDEX IF NOT EXISTS idx_conversation_memory_uuid 
  ON conversation_memory(conversation_uuid, message_timestamp DESC);

-- ============================================================================
-- PARTE 4: ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS nas novas tabelas
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_users ENABLE ROW LEVEL SECURITY;

-- Policies para CONVERSATIONS
CREATE POLICY "Users can view conversations of their client"
  ON conversations FOR SELECT
  USING (
    client_id IN (
      SELECT client_id FROM dashboard_users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update conversations of their client"
  ON conversations FOR UPDATE
  USING (
    client_id IN (
      SELECT client_id FROM dashboard_users WHERE id = auth.uid()
    )
  );

-- Policies para DASHBOARD_USERS
CREATE POLICY "Users can view own profile"
  ON dashboard_users FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON dashboard_users FOR UPDATE
  USING (id = auth.uid());

-- Atualizar policy de CONVERSATION_MEMORY
DROP POLICY IF EXISTS "conversation_memory_select_policy" ON conversation_memory;
CREATE POLICY "Users can view messages of their client conversations"
  ON conversation_memory FOR SELECT
  USING (
    client_id IN (
      SELECT client_id FROM dashboard_users WHERE id = auth.uid()
    )
  );

-- ============================================================================
-- PARTE 5: Função RPC - get_conversations_list
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversations_list(
  p_client_id TEXT,
  p_status_filter TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  chatwoot_conversation_id INTEGER,
  customer_name TEXT,
  customer_phone TEXT,
  status TEXT,
  unread_count INTEGER,
  last_message_content TEXT,
  last_message_timestamp TIMESTAMPTZ,
  last_message_sender TEXT,
  assigned_to_name TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.chatwoot_conversation_id,
    c.customer_name,
    c.customer_phone,
    c.status,
    c.unread_count,
    c.last_message_content,
    c.last_message_timestamp,
    c.last_message_sender,
    c.taken_over_by_name as assigned_to_name,
    c.created_at,
    c.updated_at
  FROM conversations c
  WHERE 
    c.client_id = p_client_id
    AND (p_status_filter IS NULL OR c.status = p_status_filter)
    AND c.status != 'archived'
  ORDER BY 
    CASE 
      WHEN c.status = 'needs_human' THEN 1
      WHEN c.status = 'human_takeover' THEN 2
      WHEN c.status = 'active' THEN 3
      ELSE 4
    END,
    c.updated_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_conversations_list IS 
  'Lista conversas com filtros e ordenação (needs_human primeiro)';

-- ============================================================================
-- PARTE 6: Função RPC - get_conversation_detail
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversation_detail(
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
  SELECT json_build_object(
    'conversation', (
      SELECT row_to_json(c) 
      FROM conversations c 
      WHERE c.id = p_conversation_uuid
    ),
    'messages', (
      SELECT json_agg(
        json_build_object(
          'id', cm.id,
          'role', cm.message_role,
          'content', cm.message_content,
          'timestamp', cm.message_timestamp,
          'sender_name', cm.sender_name,
          'has_attachments', cm.has_attachments,
          'attachments', cm.attachments
        )
        ORDER BY cm.message_timestamp ASC
      )
      FROM conversation_memory cm
      WHERE cm.conversation_uuid = p_conversation_uuid
    )
  ) INTO v_result;
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_conversation_detail IS 
  'Retorna conversa completa com todas as mensagens';

-- ============================================================================
-- PARTE 7: Função RPC - takeover_conversation
-- ============================================================================

CREATE OR REPLACE FUNCTION takeover_conversation(
  p_conversation_uuid UUID,
  p_user_name TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation conversations%ROWTYPE;
BEGIN
  -- Buscar conversa
  SELECT * INTO v_conversation 
  FROM conversations 
  WHERE id = p_conversation_uuid;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Conversation not found'
    );
  END IF;
  
  -- Validar que conversa pertence ao cliente do usuário
  IF NOT EXISTS (
    SELECT 1 FROM dashboard_users 
    WHERE id = auth.uid() 
      AND client_id = v_conversation.client_id
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Unauthorized'
    );
  END IF;
  
  -- Atualizar conversa
  UPDATE conversations SET
    status = 'human_takeover',
    assigned_to = auth.uid(),
    taken_over_at = NOW(),
    taken_over_by_name = p_user_name,
    ai_paused = true,
    updated_at = NOW()
  WHERE id = p_conversation_uuid;
  
  -- Adicionar mensagem do sistema
  INSERT INTO conversation_memory (
    client_id,
    conversation_id,
    conversation_uuid,
    message_role,
    message_content,
    agent_id,
    sender_name
  ) VALUES (
    v_conversation.client_id,
    v_conversation.chatwoot_conversation_id,
    p_conversation_uuid,
    'system',
    '🚨 ' || p_user_name || ' assumiu o atendimento. IA pausada.',
    v_conversation.agent_id,
    'Sistema'
  );
  
  RETURN json_build_object(
    'success', true,
    'conversation_id', p_conversation_uuid,
    'status', 'human_takeover'
  );
END;
$$;

COMMENT ON FUNCTION takeover_conversation IS 
  'Usuário assume conversa, pausa IA e registra no histórico';

-- ============================================================================
-- PARTE 8: Função RPC - release_conversation
-- ============================================================================

CREATE OR REPLACE FUNCTION release_conversation(
  p_conversation_uuid UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation conversations%ROWTYPE;
  v_user_name TEXT;
BEGIN
  -- Buscar conversa
  SELECT * INTO v_conversation 
  FROM conversations 
  WHERE id = p_conversation_uuid;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Conversation not found'
    );
  END IF;
  
  -- Buscar nome do usuário
  SELECT full_name INTO v_user_name
  FROM dashboard_users
  WHERE id = auth.uid();
  
  -- Atualizar conversa
  UPDATE conversations SET
    status = 'active',
    assigned_to = NULL,
    ai_paused = false,
    updated_at = NOW()
  WHERE id = p_conversation_uuid;
  
  -- Adicionar mensagem do sistema
  INSERT INTO conversation_memory (
    client_id,
    conversation_id,
    conversation_uuid,
    message_role,
    message_content,
    agent_id,
    sender_name
  ) VALUES (
    v_conversation.client_id,
    v_conversation.chatwoot_conversation_id,
    p_conversation_uuid,
    'system',
    '✅ ' || v_user_name || ' devolveu atendimento para IA. IA reativada.',
    v_conversation.agent_id,
    'Sistema'
  );
  
  RETURN json_build_object(
    'success', true,
    'conversation_id', p_conversation_uuid,
    'status', 'active'
  );
END;
$$;

COMMENT ON FUNCTION release_conversation IS 
  'Devolve conversa para IA, reativa automação';

-- ============================================================================
-- PARTE 9: Função RPC - send_human_message
-- ============================================================================

CREATE OR REPLACE FUNCTION send_human_message(
  p_conversation_uuid UUID,
  p_message_content TEXT,
  p_media_url TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation conversations%ROWTYPE;
  v_user dashboard_users%ROWTYPE;
  v_message_id UUID;
BEGIN
  -- Buscar conversa
  SELECT * INTO v_conversation 
  FROM conversations 
  WHERE id = p_conversation_uuid;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Conversation not found');
  END IF;
  
  -- Buscar usuário
  SELECT * INTO v_user 
  FROM dashboard_users 
  WHERE id = auth.uid();
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;
  
  -- Validar que conversa está em takeover
  IF v_conversation.status != 'human_takeover' OR v_conversation.assigned_to != auth.uid() THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized - conversation not in takeover');
  END IF;
  
  -- Salvar mensagem
  INSERT INTO conversation_memory (
    client_id,
    conversation_id,
    conversation_uuid,
    message_role,
    message_content,
    agent_id,
    sender_name,
    has_attachments,
    attachments
  ) VALUES (
    v_conversation.client_id,
    v_conversation.chatwoot_conversation_id,
    p_conversation_uuid,
    'agent_human',
    p_message_content,
    v_conversation.agent_id,
    v_user.full_name,
    p_media_url IS NOT NULL,
    CASE WHEN p_media_url IS NOT NULL 
      THEN jsonb_build_array(jsonb_build_object('url', p_media_url, 'type', 'file'))
      ELSE '[]'::jsonb
    END
  )
  RETURNING id INTO v_message_id;
  
  -- Atualizar última mensagem da conversa
  UPDATE conversations SET
    last_message_content = p_message_content,
    last_message_timestamp = NOW(),
    last_message_sender = 'agent_human',
    total_messages = total_messages + 1,
    updated_at = NOW()
  WHERE id = p_conversation_uuid;
  
  RETURN json_build_object(
    'success', true,
    'message_id', v_message_id,
    'conversation_id', p_conversation_uuid,
    'chatwoot_conversation_id', v_conversation.chatwoot_conversation_id
  );
END;
$$;

COMMENT ON FUNCTION send_human_message IS 
  'Envia mensagem como humano (apenas se em takeover)';

-- ============================================================================
-- PARTE 10: Função RPC - get_dashboard_stats
-- ============================================================================

CREATE OR REPLACE FUNCTION get_dashboard_stats(
  p_client_id TEXT,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_stats JSON;
BEGIN
  SELECT json_build_object(
    'today', json_build_object(
      'total_conversations', (
        SELECT COUNT(*) 
        FROM conversations 
        WHERE client_id = p_client_id 
          AND DATE(created_at) = p_date
      ),
      'active_now', (
        SELECT COUNT(*) 
        FROM conversations 
        WHERE client_id = p_client_id 
          AND status IN ('active', 'needs_human', 'human_takeover')
      ),
      'needs_human', (
        SELECT COUNT(*) 
        FROM conversations 
        WHERE client_id = p_client_id 
          AND status = 'needs_human'
      ),
      'resolved_by_ai', (
        SELECT COUNT(*) 
        FROM conversations 
        WHERE client_id = p_client_id 
          AND DATE(created_at) = p_date
          AND status = 'resolved'
          AND taken_over_at IS NULL
      ),
      'human_handled', (
        SELECT COUNT(*) 
        FROM conversations 
        WHERE client_id = p_client_id 
          AND DATE(created_at) = p_date
          AND taken_over_at IS NOT NULL
      ),
      'ai_success_rate', (
        SELECT ROUND(
          (COUNT(*) FILTER (WHERE taken_over_at IS NULL)::numeric / 
           NULLIF(COUNT(*), 0) * 100), 1
        )
        FROM conversations 
        WHERE client_id = p_client_id 
          AND DATE(created_at) = p_date
          AND status = 'resolved'
      )
    ),
    'last_7_days', (
      SELECT json_agg(
        json_build_object(
          'date', day,
          'conversations', (
            SELECT COUNT(*) 
            FROM conversations 
            WHERE client_id = p_client_id 
              AND DATE(created_at) = day
          )
        )
        ORDER BY day DESC
      )
      FROM generate_series(
        p_date - INTERVAL '6 days',
        p_date,
        INTERVAL '1 day'
      ) AS day
    )
  ) INTO v_stats;
  
  RETURN v_stats;
END;
$$;

COMMENT ON FUNCTION get_dashboard_stats IS 
  'Retorna estatísticas completas do dashboard';

-- ============================================================================
-- PARTE 11: Função Helper - sync_conversation_from_chatwoot
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_conversation_from_chatwoot(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_chatwoot_conversation_id INTEGER,
  p_customer_name TEXT DEFAULT NULL,
  p_customer_phone TEXT DEFAULT NULL,
  p_chatwoot_contact_id INTEGER DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation_uuid UUID;
BEGIN
  -- Inserir ou atualizar conversa
  INSERT INTO conversations (
    client_id,
    agent_id,
    chatwoot_conversation_id,
    customer_name,
    customer_phone,
    chatwoot_contact_id,
    status
  ) VALUES (
    p_client_id,
    p_agent_id,
    p_chatwoot_conversation_id,
    p_customer_name,
    p_customer_phone,
    p_chatwoot_contact_id,
    'active'
  )
  ON CONFLICT (chatwoot_conversation_id) 
  DO UPDATE SET
    customer_name = COALESCE(EXCLUDED.customer_name, conversations.customer_name),
    customer_phone = COALESCE(EXCLUDED.customer_phone, conversations.customer_phone),
    updated_at = NOW()
  RETURNING id INTO v_conversation_uuid;
  
  RETURN v_conversation_uuid;
END;
$$;

COMMENT ON FUNCTION sync_conversation_from_chatwoot IS 
  'Sincroniza conversa do Chatwoot (criar/atualizar)';

-- ============================================================================
-- PARTE 12: Grants de Permissão
-- ============================================================================

-- Permitir acesso às funções RPC
GRANT EXECUTE ON FUNCTION get_conversations_list TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_detail TO authenticated;
GRANT EXECUTE ON FUNCTION takeover_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION release_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION send_human_message TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats TO anon, authenticated;
GRANT EXECUTE ON FUNCTION sync_conversation_from_chatwoot TO anon, authenticated;

-- ============================================================================
-- PARTE 13: Dados de Exemplo (OPCIONAL - Comentado por Segurança)
-- ============================================================================

-- Criar usuário de teste (descomente se quiser testar)
/*
-- 1. Criar usuário no Supabase Auth (via Dashboard ou API)
-- 2. Depois rodar:

INSERT INTO dashboard_users (
  id, -- UUID do auth.users
  client_id,
  full_name,
  email,
  role
) VALUES (
  'UUID-DO-AUTH-USER', -- Substituir pelo UUID real
  'clinica_sorriso_001',
  'Dr. João Silva',
  'joao@clinicasorriso.com',
  'owner'
);

-- Criar conversas de exemplo
INSERT INTO conversations (
  client_id,
  agent_id,
  chatwoot_conversation_id,
  customer_name,
  customer_phone,
  status,
  last_message_content,
  last_message_timestamp
) VALUES 
(
  'clinica_sorriso_001',
  'default',
  1001,
  'Maria Silva',
  '+5511987654321',
  'needs_human',
  'Preciso remarcar minha consulta urgente',
  NOW() - INTERVAL '5 minutes'
),
(
  'clinica_sorriso_001',
  'default',
  1002,
  'João Santos',
  '+5511912345678',
  'active',
  'Qual o valor da limpeza?',
  NOW() - INTERVAL '1 hour'
);
*/

-- ============================================================================
-- PARTE 14: Verificação de Integridade
-- ============================================================================

DO $$
DECLARE
  v_conversations_count INTEGER;
  v_dashboard_users_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_conversations_count FROM conversations;
  SELECT COUNT(*) INTO v_dashboard_users_count FROM dashboard_users;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'MIGRATION 022: Dashboard Tables - EXECUTADA';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Tabelas criadas:';
  RAISE NOTICE '  ✅ conversations (metadados + takeover)';
  RAISE NOTICE '  ✅ dashboard_users (autenticação)';
  RAISE NOTICE '';
  RAISE NOTICE 'Tabelas atualizadas:';
  RAISE NOTICE '  ✅ conversation_memory (novos campos)';
  RAISE NOTICE '';
  RAISE NOTICE 'Funções RPC criadas:';
  RAISE NOTICE '  ✅ get_conversations_list()';
  RAISE NOTICE '  ✅ get_conversation_detail()';
  RAISE NOTICE '  ✅ takeover_conversation()';
  RAISE NOTICE '  ✅ release_conversation()';
  RAISE NOTICE '  ✅ send_human_message()';
  RAISE NOTICE '  ✅ get_dashboard_stats()';
  RAISE NOTICE '  ✅ sync_conversation_from_chatwoot()';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS habilitado em todas as tabelas';
  RAISE NOTICE '';
  RAISE NOTICE 'Dados atuais:';
  RAISE NOTICE '  Conversas: %', v_conversations_count;
  RAISE NOTICE '  Usuários Dashboard: %', v_dashboard_users_count;
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '  PRÓXIMOS PASSOS';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '1. Criar usuários no Supabase Auth:';
  RAISE NOTICE '   - Via Dashboard: Authentication → Users → Add User';
  RAISE NOTICE '   - Ou via SQL (ver Parte 13 comentada)';
  RAISE NOTICE '';
  RAISE NOTICE '2. Vincular usuários aos clientes:';
  RAISE NOTICE '   - INSERT INTO dashboard_users (...)';
  RAISE NOTICE '';
  RAISE NOTICE '3. Atualizar n8n workflows:';
  RAISE NOTICE '   - Chamar sync_conversation_from_chatwoot()';
  RAISE NOTICE '   - Atualizar conversation_memory com conversation_uuid';
  RAISE NOTICE '';
  RAISE NOTICE '4. Testar no Dashboard:';
  RAISE NOTICE '   - Login com usuário criado';
  RAISE NOTICE '   - Verificar listagem de conversas';
  RAISE NOTICE '   - Testar takeover';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- FIM DA MIGRATION 022
-- ============================================================================

-- Para aplicar esta migration:
-- 1. Acesse Supabase Dashboard → SQL Editor
-- 2. Cole TODO este arquivo
-- 3. Execute (Run)
-- 4. Verifique mensagens de sucesso

-- Rollback (se necessário):
/*
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS dashboard_users CASCADE;
ALTER TABLE conversation_memory DROP COLUMN IF EXISTS conversation_uuid;
ALTER TABLE conversation_memory DROP COLUMN IF EXISTS sender_name;
ALTER TABLE conversation_memory DROP COLUMN IF EXISTS sender_avatar_url;
DROP FUNCTION IF EXISTS get_conversations_list;
DROP FUNCTION IF EXISTS get_conversation_detail;
DROP FUNCTION IF EXISTS takeover_conversation;
DROP FUNCTION IF EXISTS release_conversation;
DROP FUNCTION IF EXISTS send_human_message;
DROP FUNCTION IF EXISTS get_dashboard_stats;
DROP FUNCTION IF EXISTS sync_conversation_from_chatwoot;
*/

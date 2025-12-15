-- ============================================================================
-- MIGRATION 023: Multi-Channel Support
-- ============================================================================
-- Data: 19/11/2025
-- Descrição: Adiciona suporte para WhatsApp, Instagram, WebChat e Email
--            - Adiciona campo channel_type na tabela conversations
--            - Adiciona campo channel_specific_data (JSONB)
--            - Atualiza get_conversations_list() para filtrar por canal
--            - Atualiza sync_conversation_from_chatwoot() para receber canal
--            - Atualiza get_conversation_detail() para retornar canal
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Criar ENUM para Tipo de Canal
-- ============================================================================

-- Dropar tipo existente se houver (para re-executar migration)
DROP TYPE IF EXISTS channel_type CASCADE;

-- Criar tipo ENUM
CREATE TYPE channel_type AS ENUM ('whatsapp', 'instagram', 'webchat', 'email');

COMMENT ON TYPE channel_type IS 'Tipos de canal suportados: WhatsApp, Instagram DM, WebChat, Email';

-- ============================================================================
-- PARTE 2: Adicionar Campos na Tabela CONVERSATIONS
-- ============================================================================

-- Adicionar campos (temporariamente NULLABLE)
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS channel_type channel_type DEFAULT 'whatsapp',
  ADD COLUMN IF NOT EXISTS channel_specific_data JSONB DEFAULT '{}'::jsonb;

-- Comentários para documentação
COMMENT ON COLUMN conversations.channel_type IS 'Tipo de canal: whatsapp, instagram, webchat ou email';
COMMENT ON COLUMN conversations.channel_specific_data IS 'Dados específicos do canal (ex: instagram_username, email_subject, session_id)';

-- Atualizar conversas existentes para 'whatsapp' (compatibilidade retroativa)
UPDATE conversations 
SET 
  channel_type = 'whatsapp',
  channel_specific_data = jsonb_build_object(
    'customer_phone', COALESCE(customer_phone, 'unknown')
  )
WHERE channel_type IS NULL OR channel_specific_data = '{}'::jsonb;

-- Tornar campos NOT NULL após UPDATE
ALTER TABLE conversations
  ALTER COLUMN channel_type SET NOT NULL,
  ALTER COLUMN channel_specific_data SET NOT NULL;

-- ============================================================================
-- PARTE 3: Adicionar Índices para Performance
-- ============================================================================

-- Índice para filtro por canal (usado em get_conversations_list)
CREATE INDEX IF NOT EXISTS idx_conversations_channel_type 
  ON conversations(channel_type);

-- Índice composto: client_id + channel_type + status (query comum)
CREATE INDEX IF NOT EXISTS idx_conversations_client_channel_status 
  ON conversations(client_id, channel_type, status)
  WHERE status IN ('active', 'needs_human', 'human_takeover');

-- Índice GIN para busca em channel_specific_data (JSONB)
CREATE INDEX IF NOT EXISTS idx_conversations_channel_data 
  ON conversations USING GIN (channel_specific_data);

-- ============================================================================
-- PARTE 4: Atualizar Função get_conversations_list (adicionar p_channel_filter)
-- ============================================================================

-- ⚠️ IMPORTANTE: Manter p_status_filter como 2º parâmetro (compatibilidade)
DROP FUNCTION IF EXISTS get_conversations_list(TEXT, TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_conversations_list(TEXT, channel_type, TEXT, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION get_conversations_list(
  p_client_id TEXT,
  p_status_filter TEXT DEFAULT NULL,           -- 2º parâmetro (mantém compatibilidade)
  p_channel_filter channel_type DEFAULT NULL,  -- 3º parâmetro (NOVO)
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  chatwoot_conversation_id INTEGER,
  customer_name TEXT,
  customer_phone TEXT,
  channel_type channel_type,         -- ⚠️ NOVO campo no retorno
  channel_specific_data JSONB,       -- ⚠️ NOVO campo no retorno
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
    c.channel_type,              -- ⚠️ NOVO
    c.channel_specific_data,     -- ⚠️ NOVO
    c.status,
    c.unread_count,
    c.last_message_content,
    c.last_message_timestamp,
    c.last_message_sender,
    c.taken_over_by_name AS assigned_to_name,
    c.created_at,
    c.updated_at
  FROM conversations c
  WHERE 
    c.client_id = p_client_id
    AND (p_status_filter IS NULL OR c.status = p_status_filter)
    AND (p_channel_filter IS NULL OR c.channel_type = p_channel_filter) -- ⚠️ NOVO filtro
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
  'Lista conversas com filtro opcional por status e canal (whatsapp, instagram, webchat, email)';

-- ============================================================================
-- PARTE 5: Atualizar Função sync_conversation_from_chatwoot
-- ============================================================================

-- ⚠️ MANTER assinatura original + 2 novos parâmetros opcionais
DROP FUNCTION IF EXISTS sync_conversation_from_chatwoot(TEXT, TEXT, INTEGER, TEXT, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION sync_conversation_from_chatwoot(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_chatwoot_conversation_id INTEGER,
  p_customer_name TEXT DEFAULT NULL,
  p_customer_phone TEXT DEFAULT NULL,
  p_chatwoot_contact_id INTEGER DEFAULT NULL,
  p_channel_type channel_type DEFAULT 'whatsapp',      -- ⚠️ NOVO (opcional)
  p_channel_specific_data JSONB DEFAULT '{}'::jsonb    -- ⚠️ NOVO (opcional)
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
    channel_type,              -- ⚠️ NOVO
    channel_specific_data,     -- ⚠️ NOVO
    status
  ) VALUES (
    p_client_id,
    p_agent_id,
    p_chatwoot_conversation_id,
    p_customer_name,
    p_customer_phone,
    p_chatwoot_contact_id,
    p_channel_type,            -- ⚠️ NOVO
    p_channel_specific_data,   -- ⚠️ NOVO
    'active'
  )
  ON CONFLICT (chatwoot_conversation_id) 
  DO UPDATE SET
    customer_name = COALESCE(EXCLUDED.customer_name, conversations.customer_name),
    customer_phone = COALESCE(EXCLUDED.customer_phone, conversations.customer_phone),
    channel_type = EXCLUDED.channel_type,                    -- ⚠️ NOVO
    channel_specific_data = EXCLUDED.channel_specific_data,  -- ⚠️ NOVO
    updated_at = NOW()
  RETURNING id INTO v_conversation_uuid;
  
  RETURN v_conversation_uuid;
END;
$$;

COMMENT ON FUNCTION sync_conversation_from_chatwoot IS 
  'Sincroniza conversa do Chatwoot (criar/atualizar) com suporte multi-canal';

-- ============================================================================
-- PARTE 6: Atualizar Função get_conversation_detail (incluir channel info)
-- ============================================================================

DROP FUNCTION IF EXISTS get_conversation_detail(UUID);

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
      SELECT json_build_object(
        'id', c.id,
        'client_id', c.client_id,
        'agent_id', c.agent_id,
        'chatwoot_conversation_id', c.chatwoot_conversation_id,
        'customer_name', c.customer_name,
        'customer_phone', c.customer_phone,
        'channel_type', c.channel_type,                -- ⚠️ NOVO
        'channel_specific_data', c.channel_specific_data, -- ⚠️ NOVO
        'status', c.status,
        'assigned_to', c.assigned_to,
        'taken_over_at', c.taken_over_at,
        'taken_over_by_name', c.taken_over_by_name,
        'ai_paused', c.ai_paused,
        'unread_count', c.unread_count,
        'last_message_content', c.last_message_content,
        'last_message_timestamp', c.last_message_timestamp,
        'last_message_sender', c.last_message_sender,
        'created_at', c.created_at,
        'updated_at', c.updated_at
      )
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
  'Retorna conversa completa com todas as mensagens e informações do canal';

-- ============================================================================
-- PARTE 7: Grants de Permissão
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_conversations_list TO anon, authenticated;
GRANT EXECUTE ON FUNCTION sync_conversation_from_chatwoot TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_detail TO authenticated;

-- ============================================================================
-- PARTE 8: Validação e Testes
-- ============================================================================

DO $$
DECLARE
  v_conversations_count INTEGER;
  v_channel_types TEXT[];
BEGIN
  -- Verificar se campos foram adicionados
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'conversations' 
    AND column_name = 'channel_type'
  ) THEN
    RAISE EXCEPTION 'Campo channel_type não foi criado';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'conversations' 
    AND column_name = 'channel_specific_data'
  ) THEN
    RAISE EXCEPTION 'Campo channel_specific_data não foi criado';
  END IF;
  
  -- Contar conversas atualizadas
  SELECT COUNT(*) INTO v_conversations_count FROM conversations;
  
  -- Verificar distribuição por canal
  SELECT array_agg(DISTINCT channel_type::text) INTO v_channel_types
  FROM conversations;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'MIGRATION 023: Multi-Channel - EXECUTADA';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Campos adicionados:';
  RAISE NOTICE '  ✅ conversations.channel_type (ENUM)';
  RAISE NOTICE '  ✅ conversations.channel_specific_data (JSONB)';
  RAISE NOTICE '';
  RAISE NOTICE 'Índices criados:';
  RAISE NOTICE '  ✅ idx_conversations_channel_type';
  RAISE NOTICE '  ✅ idx_conversations_client_channel_status';
  RAISE NOTICE '  ✅ idx_conversations_channel_data (GIN)';
  RAISE NOTICE '';
  RAISE NOTICE 'Funções atualizadas:';
  RAISE NOTICE '  ✅ get_conversations_list() (+ p_channel_filter)';
  RAISE NOTICE '  ✅ sync_conversation_from_chatwoot() (+ channel params)';
  RAISE NOTICE '  ✅ get_conversation_detail() (+ channel info)';
  RAISE NOTICE '';
  RAISE NOTICE 'Conversas atualizadas: %', v_conversations_count;
  RAISE NOTICE 'Canais configurados: %', v_channel_types;
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '  PRÓXIMOS PASSOS';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '1. Atualizar n8n workflows:';
  RAISE NOTICE '   - Passar p_channel_type ao chamar sync_conversation_from_chatwoot()';
  RAISE NOTICE '   - Exemplo: "whatsapp", "instagram", "webchat", "email"';
  RAISE NOTICE '';
  RAISE NOTICE '2. Testar no Dashboard:';
  RAISE NOTICE '   - Filtro por canal deve funcionar';
  RAISE NOTICE '   - Ícones de canal devem aparecer';
  RAISE NOTICE '';
  RAISE NOTICE '3. Criar conversas de teste:';
  RAISE NOTICE '   - WhatsApp (já existentes)';
  RAISE NOTICE '   - Instagram (adicionar via n8n)';
  RAISE NOTICE '   - WebChat (adicionar via n8n)';
  RAISE NOTICE '   - Email (adicionar via n8n)';
  RAISE NOTICE '';
END $$;

COMMIT;

-- ============================================================================
-- FIM DA MIGRATION 023
-- ============================================================================

-- Para rollback (se necessário):
/*
BEGIN;

-- Remover índices
DROP INDEX IF EXISTS idx_conversations_channel_type;
DROP INDEX IF EXISTS idx_conversations_client_channel_status;
DROP INDEX IF EXISTS idx_conversations_channel_data;

-- Remover campos
ALTER TABLE conversations DROP COLUMN IF EXISTS channel_type;
ALTER TABLE conversations DROP COLUMN IF EXISTS channel_specific_data;

-- Dropar tipo ENUM
DROP TYPE IF EXISTS channel_type CASCADE;

-- Restaurar funções originais (Migration 022)
-- (copiar código original das funções)

COMMIT;
*/

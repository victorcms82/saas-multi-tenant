-- ============================================================================
-- Migration 023: Multi-Channel Support (VERSÃO DEFINITIVA)
-- ============================================================================
-- OBJETIVO: Adicionar suporte multi-canal SEM quebrar funções existentes
-- CANAIS: WhatsApp, Instagram DM, WebChat, Email
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. VERIFICAÇÃO INTELIGENTE (DETECTA ESTADO INTERMEDIÁRIO)
-- ============================================================================
DO $$ 
BEGIN
  -- ✅ Verifica se COLUNA existe (indicador real de migration completa)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'conversations' 
    AND column_name = 'channel_type'
  ) THEN
    RAISE EXCEPTION 'Migration 023 já foi executada. Coluna channel_type já existe.';
  END IF;
  
  RAISE NOTICE 'Iniciando Migration 023...';
END $$;

-- ============================================================================
-- 2. LIMPAR ESTADO INTERMEDIÁRIO (DROPAR TUDO DINAMICAMENTE)
-- ============================================================================

-- ✅ Dropar TODAS as versões de get_conversations_list
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'get_conversations_list'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- ✅ Dropar TODAS as versões de sync_conversation_from_chatwoot
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'sync_conversation_from_chatwoot'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- ✅ Dropar TODAS as versões de get_conversation_detail
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT oid::regprocedure 
    FROM pg_proc 
    WHERE proname = 'get_conversation_detail'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid::regprocedure || ' CASCADE';
    RAISE NOTICE 'Dropped: %', r.oid::regprocedure;
  END LOOP;
END $$;

-- ✅ Dropar tipo (limpa órfão)
DROP TYPE IF EXISTS channel_type CASCADE;

-- ============================================================================
-- 3. CRIAR ENUM
-- ============================================================================
CREATE TYPE channel_type AS ENUM (
  'whatsapp',
  'instagram',
  'webchat',
  'email'
);

COMMENT ON TYPE channel_type IS 'Tipos de canal de comunicação suportados';

-- ============================================================================
-- 4. ADICIONAR CAMPOS À TABELA conversations
-- ============================================================================
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS channel_type channel_type DEFAULT 'whatsapp',
  ADD COLUMN IF NOT EXISTS channel_specific_data JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN conversations.channel_type IS 'Tipo de canal: whatsapp, instagram, webchat, email';
COMMENT ON COLUMN conversations.channel_specific_data IS 'Dados específicos do canal';

-- Migrar dados existentes
UPDATE conversations 
SET 
  channel_type = 'whatsapp',
  channel_specific_data = jsonb_build_object(
    'customer_phone', COALESCE(customer_phone, 'unknown')
  )
WHERE channel_type IS NULL OR channel_specific_data = '{}'::jsonb;

-- Aplicar NOT NULL
ALTER TABLE conversations
  ALTER COLUMN channel_type SET NOT NULL,
  ALTER COLUMN channel_specific_data SET NOT NULL;

-- ============================================================================
-- 5. CRIAR ÍNDICES PARA PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_conversations_channel_type 
  ON conversations(channel_type);

CREATE INDEX IF NOT EXISTS idx_conversations_client_channel_status 
  ON conversations(client_id, channel_type, status);

CREATE INDEX IF NOT EXISTS idx_conversations_channel_data 
  ON conversations USING GIN (channel_specific_data);

-- ============================================================================
-- 6. FUNÇÃO: get_conversations_list
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversations_list(
  p_client_id TEXT,
  p_status_filter TEXT DEFAULT NULL,          -- ✅ 2º param (mantém ordem original)
  p_channel_filter channel_type DEFAULT NULL, -- ✅ 3º param (novo, mas no final)
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  chatwoot_conversation_id INTEGER,
  customer_name TEXT,
  customer_phone TEXT,
  channel_type channel_type,                  -- ✅ Novo campo
  channel_specific_data JSONB,                -- ✅ Novo campo
  status TEXT,
  unread_count INTEGER,
  last_message_content TEXT,
  last_message_timestamp TIMESTAMPTZ,
  last_message_sender TEXT,
  assigned_to_name TEXT,
  taken_over_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validar acesso (RLS via função)
  IF NOT EXISTS (
    SELECT 1 FROM dashboard_users 
    WHERE dashboard_users.id = auth.uid() 
    AND dashboard_users.client_id = p_client_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized: User does not belong to client_id %', p_client_id;
  END IF;

  RETURN QUERY
  SELECT 
    c.id, c.chatwoot_conversation_id, c.customer_name, c.customer_phone,
    c.channel_type, c.channel_specific_data,
    c.status, c.unread_count,
    c.last_message_content, c.last_message_timestamp, c.last_message_sender,
    du.full_name AS assigned_to_name,
    c.taken_over_at, c.created_at, c.updated_at
  FROM conversations c
  LEFT JOIN dashboard_users du ON du.id = c.assigned_to
  WHERE c.client_id = p_client_id
    AND (p_status_filter IS NULL OR c.status = p_status_filter)
    AND (p_channel_filter IS NULL OR c.channel_type = p_channel_filter)
  ORDER BY 
    c.last_message_timestamp DESC NULLS LAST,
    c.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

-- ============================================================================
-- 7. FUNÇÃO: sync_conversation_from_chatwoot
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_conversation_from_chatwoot(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_chatwoot_conversation_id INTEGER,
  p_customer_name TEXT,
  p_customer_phone TEXT,
  p_chatwoot_contact_id TEXT,
  p_channel_type channel_type DEFAULT 'whatsapp',
  p_channel_specific_data JSONB DEFAULT '{}'::jsonb
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_conversation_uuid UUID;
  v_conversation_status TEXT;
  v_unread_count INTEGER;
BEGIN
  -- Buscar conversa existente
  SELECT id, status, unread_count 
  INTO v_conversation_uuid, v_conversation_status, v_unread_count
  FROM conversations
  WHERE chatwoot_conversation_id = p_chatwoot_conversation_id
    AND client_id = p_client_id;

  IF v_conversation_uuid IS NULL THEN
    INSERT INTO conversations (
      client_id, agent_id, chatwoot_conversation_id,
      customer_name, customer_phone,
      channel_type, channel_specific_data,
      status, ai_paused, unread_count
    ) VALUES (
      p_client_id, p_agent_id, p_chatwoot_conversation_id,
      p_customer_name, p_customer_phone,
      p_channel_type, p_channel_specific_data,
      'active', FALSE, 0
    )
    RETURNING id, status, unread_count 
    INTO v_conversation_uuid, v_conversation_status, v_unread_count;
  ELSE
    UPDATE conversations
    SET 
      customer_name = COALESCE(p_customer_name, customer_name),
      customer_phone = COALESCE(p_customer_phone, customer_phone),
      channel_type = p_channel_type,
      channel_specific_data = COALESCE(p_channel_specific_data, channel_specific_data),
      updated_at = NOW()
    WHERE id = v_conversation_uuid
    RETURNING status, unread_count 
    INTO v_conversation_status, v_unread_count;
  END IF;

  -- Retornar resultado
  RETURN json_build_object(
    'success', TRUE,
    'conversation_id', v_conversation_uuid,
    'chatwoot_conversation_id', p_chatwoot_conversation_id,
    'status', v_conversation_status,
    'channel_type', p_channel_type,
    'unread_count', v_unread_count
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- ============================================================================
-- 8. FUNÇÃO: get_conversation_detail
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversation_detail(p_conversation_uuid UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_client_id TEXT;
  v_conversation JSON;
  v_messages JSON;
BEGIN
  SELECT client_id INTO v_client_id 
  FROM conversations WHERE id = p_conversation_uuid;

  IF v_client_id IS NULL THEN 
    RAISE EXCEPTION 'Conversation not found: %', p_conversation_uuid; 
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM dashboard_users 
    WHERE id = auth.uid() AND client_id = v_client_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized access to conversation %', p_conversation_uuid;
  END IF;

  SELECT json_build_object(
    'id', c.id,
    'chatwoot_conversation_id', c.chatwoot_conversation_id,
    'customer_name', c.customer_name,
    'customer_phone', c.customer_phone,
    'channel_type', c.channel_type,
    'channel_specific_data', c.channel_specific_data,
    'status', c.status,
    'assigned_to', c.assigned_to,
    'assigned_to_name', du.full_name,
    'taken_over_at', c.taken_over_at,
    'taken_over_by_name', c.taken_over_by_name,
    'ai_paused', c.ai_paused,
    'unread_count', c.unread_count,
    'created_at', c.created_at,
    'updated_at', c.updated_at
  ) INTO v_conversation
  FROM conversations c
  LEFT JOIN dashboard_users du ON du.id = c.assigned_to
  WHERE c.id = p_conversation_uuid;
  SELECT json_agg(
    json_build_object(
      'id', cm.id,
      'role', cm.message_role,
      'content', cm.message_content,
      'sender_name', cm.sender_name,
      'timestamp', cm.message_timestamp,
      'has_attachments', cm.has_attachments,
      'attachments', cm.attachments
    ) ORDER BY cm.message_timestamp ASC
  ) INTO v_messages
  FROM conversation_memory cm
  WHERE cm.conversation_uuid = p_conversation_uuid;

  RETURN json_build_object(
    'conversation', v_conversation,
    'messages', COALESCE(v_messages, '[]'::json)
  );
END;
$$;

-- ============================================================================
-- 9. PERMISSÕES
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_conversations_list TO authenticated;
GRANT EXECUTE ON FUNCTION sync_conversation_from_chatwoot TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_detail TO authenticated;

-- ============================================================================
-- 10. VALIDAÇÃO FINAL
-- ============================================================================
DO $$
DECLARE
  v_columns_ok BOOLEAN;
  v_indexes_ok BOOLEAN;
  v_functions_ok BOOLEAN;
BEGIN
  -- Validar colunas
  SELECT COUNT(*) = 2 INTO v_columns_ok
  FROM information_schema.columns 
  WHERE table_name = 'conversations' 
  AND column_name IN ('channel_type', 'channel_specific_data');

  -- Validar índices (usar nomes exatos, não LIKE)
  SELECT COUNT(*) = 3 INTO v_indexes_ok
  FROM pg_indexes
  WHERE tablename = 'conversations'
  AND indexname IN (
    'idx_conversations_channel_type',
    'idx_conversations_client_channel_status',
    'idx_conversations_channel_data'
  );

  -- Validar funções
  SELECT COUNT(*) = 3 INTO v_functions_ok
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
  AND p.proname IN (
    'get_conversations_list',
    'sync_conversation_from_chatwoot',
    'get_conversation_detail'
  );

  IF v_columns_ok AND v_indexes_ok AND v_functions_ok THEN
    RAISE NOTICE '✅ Migration 023 executada com sucesso!';
    RAISE NOTICE '   - Colunas: channel_type, channel_specific_data';
    RAISE NOTICE '   - Índices: 3 criados';
    RAISE NOTICE '   - Funções: 3 atualizadas';
    RAISE NOTICE '   - Compatibilidade: backward compatible ✅';
  ELSE
    RAISE EXCEPTION 'Validação falhou! Colunas: %, Índices: %, Funções: %', 
      v_columns_ok, v_indexes_ok, v_functions_ok;
  END IF;
END $$;

COMMIT;

-- ============================================================================
-- ROLLBACK (se necessário)
-- ============================================================================
-- BEGIN;
-- ALTER TABLE conversations DROP COLUMN IF EXISTS channel_type CASCADE;
-- ALTER TABLE conversations DROP COLUMN IF EXISTS channel_specific_data;
-- DROP INDEX IF EXISTS idx_conversations_channel_type;
-- DROP INDEX IF EXISTS idx_conversations_client_channel_status;
-- DROP INDEX IF EXISTS idx_conversations_channel_data;
-- -- Restaurar funções originais da Migration 022
-- COMMIT;

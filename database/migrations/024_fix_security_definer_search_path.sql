-- ============================================================================
-- Migration 024: Fix Security Definer Search Path
-- ============================================================================
-- OBJETIVO: Corrigir warning "Function Search Path Mutable" nas funções do dashboard
-- FUNÇÕES: get_conversations_list, sync_conversation_from_chatwoot, get_conversation_detail
-- SEGURANÇA: Adicionar SET search_path = public, pg_temp para prevenir SQL injection
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. VERIFICAÇÃO
-- ============================================================================
DO $$ 
BEGIN
  -- Verificar se as funções existem
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'get_conversations_list'
  ) THEN
    RAISE EXCEPTION 'Migration 023 deve ser executada primeiro (função get_conversations_list não encontrada)';
  END IF;
  
  RAISE NOTICE 'Iniciando Migration 024 - Fix Security Definer Search Path...';
END $$;

-- ============================================================================
-- 2. FUNÇÃO: get_conversations_list (COM SEARCH_PATH FIXO)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversations_list(
  p_client_id TEXT,
  p_status_filter TEXT DEFAULT NULL,
  p_channel_filter channel_type DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  chatwoot_conversation_id INTEGER,
  customer_name TEXT,
  customer_phone TEXT,
  channel_type channel_type,
  channel_specific_data JSONB,
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
SET search_path = public, pg_temp  -- ✅ FIX: Search path fixo para segurança
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

COMMENT ON FUNCTION get_conversations_list IS 'Lista conversas com search_path fixo para segurança (Migration 024)';

-- ============================================================================
-- 3. FUNÇÃO: sync_conversation_from_chatwoot (COM SEARCH_PATH FIXO)
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
SET search_path = public, pg_temp  -- ✅ FIX: Search path fixo para segurança
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

COMMENT ON FUNCTION sync_conversation_from_chatwoot IS 'Sincroniza conversa do Chatwoot com search_path fixo (Migration 024)';

-- ============================================================================
-- 4. FUNÇÃO: get_conversation_detail (COM SEARCH_PATH FIXO)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_conversation_detail(p_conversation_uuid UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp  -- ✅ FIX: Search path fixo para segurança
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

COMMENT ON FUNCTION get_conversation_detail IS 'Detalhes da conversa com search_path fixo (Migration 024)';

-- ============================================================================
-- 5. PERMISSÕES
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_conversations_list TO authenticated;
GRANT EXECUTE ON FUNCTION sync_conversation_from_chatwoot TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_detail TO authenticated;

-- ============================================================================
-- 6. VALIDAÇÃO FINAL
-- ============================================================================
DO $$
DECLARE
  v_functions_with_search_path INTEGER;
BEGIN
  -- Validar que as 3 funções agora têm search_path configurado
  SELECT COUNT(*) INTO v_functions_with_search_path
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
  AND p.proname IN (
    'get_conversations_list',
    'sync_conversation_from_chatwoot',
    'get_conversation_detail'
  )
  AND p.proconfig IS NOT NULL  -- Tem configuração (search_path)
  AND EXISTS (
    SELECT 1 FROM unnest(p.proconfig) AS cfg
    WHERE cfg LIKE 'search_path=%'
  );

  IF v_functions_with_search_path = 3 THEN
    RAISE NOTICE '✅ Migration 024 executada com sucesso!';
    RAISE NOTICE '   - 3 funções atualizadas com search_path fixo';
    RAISE NOTICE '   - Warnings de segurança corrigidos';
    RAISE NOTICE '   - get_conversations_list ✅';
    RAISE NOTICE '   - sync_conversation_from_chatwoot ✅';
    RAISE NOTICE '   - get_conversation_detail ✅';
  ELSE
    RAISE EXCEPTION 'Validação falhou! Apenas % de 3 funções têm search_path configurado', 
      v_functions_with_search_path;
  END IF;
END $$;

COMMIT;

-- ============================================================================
-- NOTAS DE SEGURANÇA
-- ============================================================================
-- O warning "Function Search Path Mutable" ocorre quando funções SECURITY DEFINER
-- não têm um search_path explícito, permitindo potencial SQL injection.
-- 
-- Ao adicionar "SET search_path = public, pg_temp", garantimos que:
-- 1. A função sempre busca objetos no schema 'public' primeiro
-- 2. Objetos temporários (pg_temp) são permitidos
-- 3. Nenhum outro schema pode ser injetado via search_path manipulation
-- 
-- Referência: https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable
-- ============================================================================

-- ============================================================================
-- VERIFICAR EXECUÇÃO DA MIGRATION 022
-- ============================================================================

-- 1. Verificar se tabela CONVERSATIONS existe
SELECT 
  'conversations' as table_name,
  COUNT(*) as row_count,
  CASE WHEN COUNT(*) >= 0 THEN '✅ Existe' ELSE '❌ Não existe' END as status
FROM conversations;

-- 2. Verificar se tabela DASHBOARD_USERS existe
SELECT 
  'dashboard_users' as table_name,
  COUNT(*) as row_count,
  CASE WHEN COUNT(*) >= 0 THEN '✅ Existe' ELSE '❌ Não existe' END as status
FROM dashboard_users;

-- 3. Verificar novos campos em CONVERSATION_MEMORY
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'conversation_memory'
  AND column_name IN ('conversation_uuid', 'sender_name', 'sender_avatar_url')
ORDER BY column_name;

-- 4. Verificar funções RPC criadas
SELECT 
  routine_name as function_name,
  '✅ Existe' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_conversations_list',
    'get_conversation_detail',
    'takeover_conversation',
    'release_conversation',
    'send_human_message',
    'get_dashboard_stats',
    'sync_conversation_from_chatwoot'
  )
ORDER BY routine_name;

-- 5. Verificar RLS nas novas tabelas
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('conversations', 'dashboard_users');

-- 6. Verificar policies criadas
SELECT 
  tablename,
  policyname,
  cmd as command,
  CASE WHEN cmd = 'SELECT' THEN '👁️ View'
       WHEN cmd = 'UPDATE' THEN '✏️ Update'
       ELSE cmd END as action
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('conversations', 'dashboard_users', 'conversation_memory')
ORDER BY tablename, policyname;

-- 7. Verificar índices criados
SELECT 
  tablename,
  indexname,
  '✅ Criado' as status
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('conversations', 'dashboard_users', 'conversation_memory')
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- 8. Resumo Final
SELECT 
  '=== RESUMO DA MIGRATION 022 ===' as title;

SELECT 
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_name = 'conversations') as conversations_table,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_name = 'dashboard_users') as dashboard_users_table,
  (SELECT COUNT(*) FROM information_schema.columns 
   WHERE table_name = 'conversation_memory' 
   AND column_name = 'conversation_uuid') as conversation_uuid_column,
  (SELECT COUNT(*) FROM information_schema.routines 
   WHERE routine_name LIKE '%conversation%' 
   AND routine_schema = 'public') as rpc_functions_count;

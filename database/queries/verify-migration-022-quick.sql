-- Verificar tabelas criadas
SELECT 
  'conversations' as tabela,
  COUNT(*) as total_linhas,
  '✅ Existe' as status
FROM conversations
UNION ALL
SELECT 
  'dashboard_users' as tabela,
  COUNT(*) as total_linhas,
  '✅ Existe' as status
FROM dashboard_users;

-- Verificar novos campos em conversation_memory
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'conversation_memory'
  AND column_name IN ('conversation_uuid', 'sender_name', 'sender_avatar_url');

-- Verificar funções RPC
SELECT 
  routine_name as funcao,
  '✅ Criada' as status
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
  );

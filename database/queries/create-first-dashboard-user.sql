-- ============================================================================
-- CRIAR PRIMEIRO USUÁRIO DO DASHBOARD
-- ============================================================================
-- IMPORTANTE: Execute este script EM DUAS ETAPAS
-- ============================================================================

-- ============================================================================
-- ETAPA 1: Criar usuário no Supabase Auth (via Dashboard UI)
-- ============================================================================
-- 
-- 1. Acesse: Supabase Dashboard → Authentication → Users
-- 2. Clique em "Add User" → "Create new user"
-- 3. Preencha:
--    Email: teste@evolutedigital.com.br
--    Password: Teste@2024! (ou qualquer senha forte)
--    ✅ Auto Confirm User: TRUE (marcar esta opção!)
-- 4. Clique em "Create User"
-- 5. COPIE o UUID que aparece (algo como: 123e4567-e89b-12d3-a456-426614174000)
--

-- ============================================================================
-- ETAPA 2: Vincular usuário ao cliente (RODE O SQL ABAIXO)
-- ============================================================================

-- SUBSTITUA 'UUID-AQUI' pelo UUID copiado da Etapa 1
INSERT INTO dashboard_users (
  id,
  client_id,
  full_name,
  email,
  role,
  is_active
) VALUES (
  'UUID-AQUI', -- 👈 SUBSTITUIR pelo UUID do auth.users
  'clinica_sorriso_001',
  'Usuário Teste',
  'teste@evolutedigital.com.br',
  'owner'::text,
  true
);

-- ============================================================================
-- VERIFICAR SE FUNCIONOU
-- ============================================================================

-- Deve retornar 1 linha
SELECT 
  id,
  client_id,
  full_name,
  email,
  role,
  is_active,
  created_at
FROM dashboard_users
WHERE email = 'teste@evolutedigital.com.br';

-- ============================================================================
-- CRIAR CONVERSA DE TESTE (OPCIONAL - para testar o dashboard)
-- ============================================================================

-- Criar 2 conversas fictícias para visualizar no dashboard
INSERT INTO conversations (
  client_id,
  agent_id,
  chatwoot_conversation_id,
  customer_name,
  customer_phone,
  status,
  last_message_content,
  last_message_timestamp,
  unread_count
) VALUES 
-- Conversa 1: Precisa atenção humana
(
  'clinica_sorriso_001',
  'default',
  9001, -- ID fictício
  'Maria Silva',
  '+5511987654321',
  'needs_human',
  'Preciso remarcar minha consulta URGENTE para hoje!',
  NOW() - INTERVAL '5 minutes',
  3
),
-- Conversa 2: IA atendendo normalmente
(
  'clinica_sorriso_001',
  'default',
  9002, -- ID fictício
  'João Santos',
  '+5511912345678',
  'active',
  'Qual o valor da limpeza de dentes?',
  NOW() - INTERVAL '1 hour',
  1
),
-- Conversa 3: Já resolvida
(
  'clinica_sorriso_001',
  'default',
  9003,
  'Ana Costa',
  '+5511999887766',
  'resolved',
  'Obrigada! Consulta confirmada.',
  NOW() - INTERVAL '3 hours',
  0
);

-- Verificar conversas criadas
SELECT 
  customer_name,
  customer_phone,
  status,
  last_message_content,
  unread_count,
  created_at
FROM conversations
WHERE client_id = 'clinica_sorriso_001'
ORDER BY created_at DESC;

-- ============================================================================
-- TESTAR FUNÇÃO RPC (Simular o que o dashboard vai fazer)
-- ============================================================================

-- Listar conversas (igual ao dashboard)
SELECT * FROM get_conversations_list('clinica_sorriso_001', NULL, 50, 0);

-- Estatísticas (igual ao dashboard)
SELECT get_dashboard_stats('clinica_sorriso_001', CURRENT_DATE);

-- ============================================================================
-- RESUMO FINAL
-- ============================================================================

SELECT 
  'Dashboard Users' as tabela,
  COUNT(*) as total
FROM dashboard_users
WHERE client_id = 'clinica_sorriso_001'
UNION ALL
SELECT 
  'Conversations',
  COUNT(*)
FROM conversations
WHERE client_id = 'clinica_sorriso_001';

-- ============================================================================
-- PRÓXIMOS PASSOS APÓS EXECUTAR
-- ============================================================================
--
-- 1. ✅ Usuário criado no Supabase Auth
-- 2. ✅ Usuário vinculado ao cliente em dashboard_users
-- 3. ✅ Conversas de teste criadas
-- 4. 🚀 AGORA: Gerar dashboard no Lovable com o prompt
-- 5. 🔐 TESTAR: Login no dashboard com teste@evolutedigital.com.br
--

-- ============================================================================
-- VINCULAR USUÁRIO 39965c14-1859-46a5-b36c-8c8d33709701 AO CLIENTE
-- ============================================================================

-- Inserir usuário na tabela dashboard_users
INSERT INTO dashboard_users (
  id,
  client_id,
  full_name,
  email,
  role,
  is_active
) VALUES (
  '39965c14-1859-46a5-b36c-8c8d33709701',
  'clinica_sorriso_001',
  'Usuário Teste',
  'teste@evolutedigital.com.br',
  'owner',
  true
);

-- Verificar se foi inserido corretamente
SELECT 
  id,
  client_id,
  full_name,
  email,
  role,
  is_active,
  created_at
FROM dashboard_users
WHERE id = '39965c14-1859-46a5-b36c-8c8d33709701';

-- ============================================================================
-- CRIAR CONVERSAS DE TESTE
-- ============================================================================

-- Inserir 3 conversas fictícias para visualizar no dashboard
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
-- Conversa 1: URGENTE - Precisa atenção humana
(
  'clinica_sorriso_001',
  'default',
  9001,
  'Maria Silva',
  '+5511987654321',
  'needs_human',
  'Preciso remarcar minha consulta URGENTE para hoje! É emergência!',
  NOW() - INTERVAL '5 minutes',
  3
),
-- Conversa 2: IA atendendo normalmente
(
  'clinica_sorriso_001',
  'default',
  9002,
  'João Santos',
  '+5511912345678',
  'active',
  'Qual o valor da limpeza de dentes?',
  NOW() - INTERVAL '1 hour',
  1
),
-- Conversa 3: Resolvida pela IA
(
  'clinica_sorriso_001',
  'default',
  9003,
  'Ana Costa',
  '+5511999887766',
  'resolved',
  'Obrigada! Consulta confirmada para terça às 14h.',
  NOW() - INTERVAL '3 hours',
  0
);

-- Verificar conversas criadas
SELECT 
  id,
  customer_name,
  customer_phone,
  status,
  last_message_content,
  unread_count,
  created_at
FROM conversations
WHERE client_id = 'clinica_sorriso_001'
ORDER BY 
  CASE 
    WHEN status = 'needs_human' THEN 1
    WHEN status = 'active' THEN 2
    ELSE 3
  END,
  created_at DESC;

-- ============================================================================
-- TESTAR FUNÇÕES RPC (Simular Dashboard)
-- ============================================================================

-- 1. Listar conversas (igual ao dashboard)
SELECT * FROM get_conversations_list('clinica_sorriso_001', NULL, 50, 0);

-- 2. Estatísticas do dashboard
SELECT get_dashboard_stats('clinica_sorriso_001', CURRENT_DATE);

-- ============================================================================
-- RESUMO FINAL
-- ============================================================================

SELECT 
  '✅ SETUP COMPLETO!' as status,
  (SELECT COUNT(*) FROM dashboard_users WHERE client_id = 'clinica_sorriso_001') as usuarios,
  (SELECT COUNT(*) FROM conversations WHERE client_id = 'clinica_sorriso_001') as conversas;

-- ============================================================================
-- CREDENCIAIS DE LOGIN
-- ============================================================================
-- Email: teste@evolutedigital.com.br
-- Senha: (a que você definiu no Supabase Auth)
-- Client ID: clinica_sorriso_001
-- ============================================================================

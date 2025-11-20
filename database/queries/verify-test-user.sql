-- ============================================================================
-- Verificar Dados de Usuário Teste
-- ============================================================================
-- Execute este SQL no Supabase SQL Editor
-- ============================================================================

-- 1. Verificar se usuário existe em auth.users
SELECT 
  '🔍 USUÁRIO EM AUTH.USERS' as tipo,
  id,
  email,
  created_at,
  email_confirmed_at
FROM auth.users
WHERE email = 'teste@evolutedigital.com.br';

-- 2. Verificar se usuário existe em dashboard_users
SELECT 
  '🔍 USUÁRIO EM DASHBOARD_USERS' as tipo,
  id,
  email,
  full_name,
  client_id,
  role,
  is_active
FROM dashboard_users
WHERE email = 'teste@evolutedigital.com.br';

-- 3. Listar TODOS os usuários em dashboard_users
SELECT 
  '📋 TODOS USUÁRIOS EM DASHBOARD_USERS' as tipo,
  id,
  email,
  full_name,
  client_id,
  role
FROM dashboard_users
ORDER BY created_at DESC;

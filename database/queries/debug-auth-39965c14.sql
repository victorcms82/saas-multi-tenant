-- ============================================================================
-- DEBUG: VERIFICAR TODAS AS INFORMAÇÕES DO USUÁRIO
-- ============================================================================

-- 1. Verificar na tabela auth.users
SELECT 
  id,
  email,
  encrypted_password IS NOT NULL as tem_senha,
  email_confirmed_at IS NOT NULL as email_confirmado,
  confirmed_at IS NOT NULL as usuario_confirmado,
  created_at,
  updated_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data
FROM auth.users
WHERE id = '39965c14-1859-46a5-b36c-8c8d33709701';

-- 2. Verificar na tabela dashboard_users
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

-- 3. Verificar conversas do cliente
SELECT COUNT(*) as total_conversas
FROM conversations
WHERE client_id = 'clinica_sorriso_001';

-- ============================================================================
-- TENTAR REDEFINIR SENHA COM MÉTODO ALTERNATIVO
-- ============================================================================

-- Deletar e recriar o usuário com senha correta
DELETE FROM auth.users WHERE id = '39965c14-1859-46a5-b36c-8c8d33709701';

-- Recriar usuário (o Supabase vai gerar o hash correto)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '39965c14-1859-46a5-b36c-8c8d33709701',
  'authenticated',
  'authenticated',
  'teste@evolutedigital.com.br',
  crypt('Teste@2024!', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  NOW(),
  NOW(),
  '',
  ''
);

-- Verificar novamente
SELECT 
  id,
  email,
  encrypted_password IS NOT NULL as tem_senha,
  email_confirmed_at,
  created_at
FROM auth.users
WHERE id = '39965c14-1859-46a5-b36c-8c8d33709701';

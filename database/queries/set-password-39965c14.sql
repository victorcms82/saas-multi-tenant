-- ============================================================================
-- DEFINIR SENHA PARA USUÁRIO teste@evolutedigital.com.br
-- ============================================================================
-- UUID: 39965c14-1859-46a5-b36c-8c8d33709701
-- Email: teste@evolutedigital.com.br
-- Senha: Teste@2024!
-- ============================================================================

-- Atualizar senha e confirmar email
UPDATE auth.users
SET 
  encrypted_password = crypt('Teste@2024!', gen_salt('bf')),
  email_confirmed_at = NOW(),
  confirmation_token = NULL,
  email_change_token_current = NULL,
  email_change = NULL
WHERE id = '39965c14-1859-46a5-b36c-8c8d33709701';

-- Verificar se foi atualizado
SELECT 
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  created_at,
  updated_at
FROM auth.users
WHERE id = '39965c14-1859-46a5-b36c-8c8d33709701';

-- ============================================================================
-- CREDENCIAIS FINAIS
-- ============================================================================
-- Email: teste@evolutedigital.com.br
-- Senha: Teste@2024!
-- ============================================================================

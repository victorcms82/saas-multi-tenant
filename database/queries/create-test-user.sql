-- ============================================================================
-- Criar Usuário Teste para Dashboard
-- ============================================================================
-- Execute este SQL no Supabase SQL Editor
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Criar usuário em auth.users (se não existir)
-- ============================================================================

-- IMPORTANTE: Supabase Auth gerencia auth.users automaticamente
-- Usuário deve ser criado via:
-- 1. Supabase Dashboard → Authentication → Users → Invite User
-- 2. Ou via signup no frontend
-- 
-- Para testes, você pode criar manualmente:

DO $$
DECLARE
  v_user_id UUID;
  v_email TEXT := 'teste@evolutedigital.com.br';
BEGIN
  -- Verificar se usuário já existe em auth.users
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = v_email;
  
  IF v_user_id IS NULL THEN
    RAISE NOTICE '❌ Usuário não existe em auth.users';
    RAISE NOTICE 'Crie o usuário via Supabase Dashboard:';
    RAISE NOTICE '1. Authentication → Users → Invite User';
    RAISE NOTICE '2. Email: teste@evolutedigital.com.br';
    RAISE NOTICE '3. Password: Teste@2024!';
  ELSE
    RAISE NOTICE '✅ Usuário existe em auth.users: %', v_user_id;
    
    -- Verificar se existe em dashboard_users
    IF NOT EXISTS (
      SELECT 1 FROM dashboard_users WHERE id = v_user_id
    ) THEN
      RAISE NOTICE '⚠️ Usuário não existe em dashboard_users, criando...';
      
      -- Inserir em dashboard_users
      INSERT INTO dashboard_users (
        id,
        client_id,
        full_name,
        email,
        phone,
        role,
        is_active
      ) VALUES (
        v_user_id,
        'clinica_sorriso_001',
        'Usuário Teste',
        v_email,
        '+5511999999999',
        'admin',
        true
      );
      
      RAISE NOTICE '✅ Usuário criado em dashboard_users';
    ELSE
      RAISE NOTICE '✅ Usuário já existe em dashboard_users';
    END IF;
  END IF;
END $$;

-- ============================================================================
-- PARTE 2: Verificar resultado
-- ============================================================================

SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  u.id as user_id,
  u.email as auth_email,
  du.email as dashboard_email,
  du.full_name,
  du.client_id,
  du.role,
  du.is_active
FROM auth.users u
LEFT JOIN dashboard_users du ON du.id = u.id
WHERE u.email = 'teste@evolutedigital.com.br';

COMMIT;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 
-- Se o usuário NÃO existe em auth.users, você precisa criar via:
-- 
-- MÉTODO 1: Supabase Dashboard (RECOMENDADO)
-- 1. Acesse: https://vnlfgnfaortdvmraoapq.supabase.co
-- 2. Authentication → Users → Invite User
-- 3. Email: teste@evolutedigital.com.br
-- 4. Password: Teste@2024!
-- 5. Auto Confirm User: ✅ YES
-- 
-- MÉTODO 2: Via SQL (avançado)
-- INSERT INTO auth.users (
--   instance_id,
--   id,
--   aud,
--   role,
--   email,
--   encrypted_password,
--   email_confirmed_at,
--   created_at,
--   updated_at
-- ) VALUES (
--   '00000000-0000-0000-0000-000000000000',
--   gen_random_uuid(),
--   'authenticated',
--   'authenticated',
--   'teste@evolutedigital.com.br',
--   crypt('Teste@2024!', gen_salt('bf')),
--   NOW(),
--   NOW(),
--   NOW()
-- );
-- 
-- ============================================================================

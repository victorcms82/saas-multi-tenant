-- ============================================================================
-- Migration 025: Fix dashboard_users RLS for Login
-- ============================================================================
-- Data: 2025-01-19
-- Descrição: Corrigir RLS da tabela dashboard_users para permitir login
--
-- PROBLEMA IDENTIFICADO:
-- - Durante login, auth.uid() ainda não existe (usuário não autenticado)
-- - Policy "Users can view own profile" (id = auth.uid()) bloqueia query
-- - Resultado: "Database error querying schema"
--
-- SOLUÇÃO:
-- - Permitir SELECT durante autenticação usando auth.email()
-- - auth.email() retorna o email do token JWT (disponível durante login)
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: Remover policies antigas de dashboard_users
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own profile" ON dashboard_users;
DROP POLICY IF EXISTS "Users can update own profile" ON dashboard_users;

-- ============================================================================
-- PARTE 2: Criar policies corretas para dashboard_users
-- ============================================================================

-- Policy 1: SELECT durante login (usando email do JWT)
-- Durante login: auth.uid() = NULL, mas auth.email() existe no token
-- Após login: auth.uid() existe e pode usar ambos
CREATE POLICY "dashboard_users_select_policy"
  ON dashboard_users FOR SELECT
  USING (
    -- Permitir se o ID do usuário autenticado bate (após login)
    id = auth.uid()
    OR
    -- Permitir se o email do usuário autenticado bate (durante login)
    email = auth.email()
  );

-- Policy 2: UPDATE apenas do próprio perfil (após login)
CREATE POLICY "dashboard_users_update_policy"
  ON dashboard_users FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Policy 3: INSERT apenas para novos usuários (sign up)
-- Só pode inserir se o ID bate com o usuário autenticado
CREATE POLICY "dashboard_users_insert_policy"
  ON dashboard_users FOR INSERT
  WITH CHECK (id = auth.uid());

-- ============================================================================
-- PARTE 3: Comentários e Documentação
-- ============================================================================

COMMENT ON POLICY "dashboard_users_select_policy" ON dashboard_users IS
'Permite SELECT usando auth.uid() (após login) ou auth.email() (durante login)';

COMMENT ON POLICY "dashboard_users_update_policy" ON dashboard_users IS
'Permite UPDATE apenas do próprio perfil (id = auth.uid())';

COMMENT ON POLICY "dashboard_users_insert_policy" ON dashboard_users IS
'Permite INSERT apenas para o próprio usuário (durante sign up)';

-- ============================================================================
-- PARTE 4: Validação
-- ============================================================================

-- Listar todas as policies de dashboard_users
SELECT 
  '✅ POLICIES DE DASHBOARD_USERS' as tipo,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'dashboard_users'
ORDER BY policyname;

-- Verificar se RLS está habilitado
SELECT 
  '✅ RLS STATUS' as tipo,
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'dashboard_users';

COMMIT;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 
-- 1. FLUXO DE LOGIN:
--    a) Usuário envia email/senha para Supabase Auth
--    b) Supabase Auth valida credenciais em auth.users
--    c) Supabase Auth gera JWT com auth.email() e auth.uid()
--    d) Frontend tenta buscar perfil em dashboard_users
--    e) RLS permite SELECT usando auth.email() (durante login) ou auth.uid() (após login)
--
-- 2. SEGURANÇA:
--    - auth.email() vem do JWT assinado pelo Supabase (não pode ser falsificado)
--    - auth.uid() vem do JWT assinado pelo Supabase (não pode ser falsificado)
--    - Usuário só vê seu próprio perfil (email ou id)
--
-- 3. TESTADO COM:
--    - Email: teste@evolutedigital.com.br
--    - Senha: Teste@2024!
--    - Client: clinica_sorriso_001
--
-- ============================================================================

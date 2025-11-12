-- ============================================================================
-- FIX CRÍTICO: Habilitar RLS em client_subscriptions
-- ============================================================================
-- PROBLEMA: Tabela client_subscriptions não tem RLS, causando erro:
--   "BLOQUEADO: client_id 'estetica_bella_rede' não existe na tabela clients"
--
-- CAUSA: Migration 016 esqueceu de incluir client_subscriptions
-- ============================================================================

-- 1. HABILITAR RLS
ALTER TABLE client_subscriptions ENABLE ROW LEVEL SECURITY;

-- 2. CRIAR POLICY DE ISOLAMENTO
DROP POLICY IF EXISTS client_subscriptions_isolation ON client_subscriptions;
CREATE POLICY client_subscriptions_isolation ON client_subscriptions
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL  -- Admin bypass
    OR client_id = current_setting('app.current_client_id', true)
  );

-- 3. GARANTIR QUE client_id NUNCA SEJA NULL (já tem, mas confirmar)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE table_name = 'client_subscriptions' 
      AND column_name = 'client_id'
      AND constraint_name LIKE '%not_null%'
  ) THEN
    ALTER TABLE client_subscriptions 
      ALTER COLUMN client_id SET NOT NULL;
  END IF;
END $$;

-- 4. VERIFICAR RESULTADO
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ RLS ATIVO'
    ELSE '❌ RLS INATIVO'
  END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'client_subscriptions';

-- 5. LISTAR POLICIES
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd as operation,
  CASE 
    WHEN qual LIKE '%current_setting%' THEN '✅ FILTRO POR TENANT'
    ELSE '⚠️ VERIFICAR'
  END as security_check
FROM pg_policies 
WHERE tablename = 'client_subscriptions';

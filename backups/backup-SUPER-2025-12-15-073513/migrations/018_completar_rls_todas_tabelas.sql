-- ============================================================================
-- MIGRATION 018: COMPLETAR RLS EM TODAS AS TABELAS MULTI-TENANT
-- ============================================================================
-- PROBLEMA: Varias tabelas com client_id nao tinham RLS habilitado
-- DESCOBERTO: client_subscriptions causou erro 400 no workflow
-- SOLUCAO: Habilitar RLS em TODAS as tabelas que tem client_id
-- ============================================================================

-- ============================================================================
-- FASE 1: HABILITAR RLS NAS TABELAS FALTANTES
-- ============================================================================

-- Tabela: media_send_log (log de envio de midia)
ALTER TABLE media_send_log ENABLE ROW LEVEL SECURITY;

-- Tabela: media_send_rules (regras de envio de midia)
ALTER TABLE media_send_rules ENABLE ROW LEVEL SECURITY;

-- Tabela: staff (equipe/profissionais)
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- FASE 2: CRIAR POLICIES DE ISOLAMENTO
-- ============================================================================

-- Policy: media_send_log (cada cliente ve apenas seus logs)
DROP POLICY IF EXISTS media_send_log_isolation ON media_send_log;
CREATE POLICY media_send_log_isolation ON media_send_log
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL  -- Admin bypass
    OR client_id = current_setting('app.current_client_id', true)
  );

-- Policy: media_send_rules (cada cliente ve apenas suas regras)
DROP POLICY IF EXISTS media_send_rules_isolation ON media_send_rules;
CREATE POLICY media_send_rules_isolation ON media_send_rules
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL  -- Admin bypass
    OR client_id = current_setting('app.current_client_id', true)
  );

-- Policy: staff (cada cliente ve apenas sua equipe)
DROP POLICY IF EXISTS staff_isolation ON staff;
CREATE POLICY staff_isolation ON staff
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL  -- Admin bypass
    OR client_id = current_setting('app.current_client_id', true)
  );

-- ============================================================================
-- FASE 3: GARANTIR CONSTRAINTS NOT NULL EM client_id
-- ============================================================================

-- Garantir que client_id nunca seja NULL em media_send_log
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'media_send_log' 
             AND column_name = 'client_id' 
             AND is_nullable = 'YES') THEN
    ALTER TABLE media_send_log ALTER COLUMN client_id SET NOT NULL;
    RAISE NOTICE 'media_send_log.client_id: NOT NULL aplicado';
  ELSE
    RAISE NOTICE 'media_send_log.client_id: ja era NOT NULL';
  END IF;
END $$;

-- Garantir que client_id nunca seja NULL em media_send_rules
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'media_send_rules' 
             AND column_name = 'client_id' 
             AND is_nullable = 'YES') THEN
    ALTER TABLE media_send_rules ALTER COLUMN client_id SET NOT NULL;
    RAISE NOTICE 'media_send_rules.client_id: NOT NULL aplicado';
  ELSE
    RAISE NOTICE 'media_send_rules.client_id: ja era NOT NULL';
  END IF;
END $$;

-- Garantir que client_id nunca seja NULL em staff
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'staff' 
             AND column_name = 'client_id' 
             AND is_nullable = 'YES') THEN
    ALTER TABLE staff ALTER COLUMN client_id SET NOT NULL;
    RAISE NOTICE 'staff.client_id: NOT NULL aplicado';
  ELSE
    RAISE NOTICE 'staff.client_id: ja era NOT NULL';
  END IF;
END $$;

-- ============================================================================
-- FASE 4: ADICIONAR TRIGGERS DE VALIDACAO (se nao existirem)
-- ============================================================================

-- Trigger: media_send_log
DROP TRIGGER IF EXISTS trigger_validate_client_id ON media_send_log;
CREATE TRIGGER trigger_validate_client_id
  BEFORE INSERT OR UPDATE ON media_send_log
  FOR EACH ROW
  EXECUTE FUNCTION validate_client_id_on_insert();

-- Trigger: media_send_rules
DROP TRIGGER IF EXISTS trigger_validate_client_id ON media_send_rules;
CREATE TRIGGER trigger_validate_client_id
  BEFORE INSERT OR UPDATE ON media_send_rules
  FOR EACH ROW
  EXECUTE FUNCTION validate_client_id_on_insert();

-- Trigger: staff
DROP TRIGGER IF EXISTS trigger_validate_client_id ON staff;
CREATE TRIGGER trigger_validate_client_id
  BEFORE INSERT OR UPDATE ON staff
  FOR EACH ROW
  EXECUTE FUNCTION validate_client_id_on_insert();

-- ============================================================================
-- FASE 5: VERIFICACAO FINAL
-- ============================================================================

-- Listar todas as tabelas com client_id e status RLS
SELECT 
  t.tablename,
  CASE 
    WHEN t.rowsecurity THEN 'RLS ATIVO'
    ELSE 'RLS INATIVO'
  END as rls_status,
  COUNT(p.policyname) as num_policies
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename
WHERE t.schemaname = 'public'
  AND EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = t.tablename
      AND c.column_name = 'client_id'
  )
GROUP BY t.tablename, t.rowsecurity
ORDER BY t.tablename;

-- Listar tabelas SEM RLS mas COM client_id (deve ser vazio)
SELECT 
  tablename,
  'CRITICO: Tem client_id mas sem RLS' as problema
FROM pg_tables t
WHERE schemaname = 'public'
  AND rowsecurity = false
  AND EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = t.tablename
      AND c.column_name = 'client_id'
  );

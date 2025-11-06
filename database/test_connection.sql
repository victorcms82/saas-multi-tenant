-- ============================================================================
-- TEST CONNECTION SCRIPT
-- Verifica se a conexão com o Supabase está funcionando
-- ============================================================================

-- Test 1: Basic query
SELECT 'Connection successful!' as status, now() as timestamp;

-- Test 2: List existing tables
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Test 3: Check if agents table already exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'agents'
    ) THEN 'agents table EXISTS'
    ELSE 'agents table NOT FOUND'
  END as agents_status;

-- Test 4: Check if agent_templates table already exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'agent_templates'
    ) THEN 'agent_templates table EXISTS'
    ELSE 'agent_templates table NOT FOUND'
  END as templates_status;

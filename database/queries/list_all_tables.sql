-- ============================================================================
-- LISTAR TODAS AS TABELAS DO BANCO (Todos os Schemas)
-- ============================================================================

-- 1. Ver TODOS os schemas disponíveis
SELECT 
  schema_name,
  schema_owner
FROM information_schema.schemata
ORDER BY schema_name;

-- 2. Ver TODAS as tabelas de TODOS os schemas
SELECT 
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;

-- 3. Contar tabelas por schema
SELECT 
  table_schema,
  COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY table_schema
ORDER BY table_count DESC;

-- 4. Ver apenas tabelas do schema PUBLIC (o que você vê agora)
SELECT 
  table_name,
  pg_size_pretty(pg_total_relation_size(quote_ident(table_name)::regclass)) as size
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 5. Ver tabelas do Supabase (schemas internos)
SELECT 
  table_schema,
  table_name
FROM information_schema.tables
WHERE table_schema IN ('auth', 'storage', 'realtime', 'extensions')
ORDER BY table_schema, table_name;

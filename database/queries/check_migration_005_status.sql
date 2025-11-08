-- ========================================
-- Check Migration 005 Status
-- ========================================
-- Purpose: Verify if client_media tables exist
-- Expected: 3 tables (client_media, media_send_rules, media_send_log)
-- Run in: Supabase SQL Editor
-- ========================================

-- Check if client_media table exists
SELECT EXISTS (
  SELECT FROM pg_tables
  WHERE schemaname = 'public'
  AND tablename = 'client_media'
) AS client_media_exists;

-- Check if media_send_rules table exists
SELECT EXISTS (
  SELECT FROM pg_tables
  WHERE schemaname = 'public'
  AND tablename = 'media_send_rules'
) AS media_send_rules_exists;

-- Check if media_send_log table exists
SELECT EXISTS (
  SELECT FROM pg_tables
  WHERE schemaname = 'public'
  AND tablename = 'media_send_log'
) AS media_send_log_exists;

-- Check if search_client_media_rules function exists
SELECT EXISTS (
  SELECT FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
  AND p.proname = 'search_client_media_rules'
) AS rpc_function_exists;

-- ========================================
-- RESULTADO:
-- Se todos = false → Executar Migration 005 + 006
-- Se tabelas = true, function = false → Executar apenas Migration 006
-- Se todos = true → Migrations já executadas, prosseguir com HTTP nodes
-- ========================================

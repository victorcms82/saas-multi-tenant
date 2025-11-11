-- ============================================================================
-- Verificar configuração atual do chatwoot_inbox_id
-- ============================================================================

-- Ver qual location já tem inbox_id = 3
SELECT 
  location_id,
  name,
  city,
  chatwoot_inbox_id,
  is_active,
  is_primary,
  created_at
FROM locations 
WHERE client_id = 'estetica_bella_rede'
ORDER BY is_primary DESC, name;

-- Verificar se há duplicatas
SELECT 
  chatwoot_inbox_id, 
  COUNT(*) as total_locations
FROM locations
WHERE chatwoot_inbox_id IS NOT NULL
GROUP BY chatwoot_inbox_id
HAVING COUNT(*) > 1;

-- Testar o RPC com inbox_id = 3
SELECT * FROM get_location_staff_summary(3);

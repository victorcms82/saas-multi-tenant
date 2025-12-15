-- ============================================================================
-- Migration 013b: FIX - Adicionar client_id ao get_location_staff_summary
-- ============================================================================
-- Problema: RPC não retornava client_id, impossibilitando sobrescrita segura
-- Solução: Adicionar client_id como primeiro campo no RETURNS TABLE
-- ============================================================================

CREATE OR REPLACE FUNCTION get_location_staff_summary(p_inbox_id INT)
RETURNS TABLE (
  client_id TEXT,              -- ✅ ADICIONADO para segurança!
  location_id TEXT,
  location_name TEXT,
  location_type TEXT,
  address TEXT,
  city TEXT,
  phone TEXT,
  whatsapp_number TEXT,
  working_hours JSONB,
  services_offered JSONB,
  total_staff INT,
  staff_available_online INT,
  staff_list JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.client_id::TEXT,         -- ✅ ADICIONADO: Retorna client_id do banco!
    l.location_id::TEXT,
    l.name::TEXT AS location_name,
    l.location_type::TEXT,
    l.address::TEXT,
    l.city::TEXT,
    l.phone::TEXT,
    l.whatsapp_number::TEXT,
    l.working_hours,
    l.services_offered,
    COUNT(s.staff_id)::INT AS total_staff,
    COUNT(s.staff_id) FILTER (WHERE s.is_available_online = TRUE)::INT AS staff_available_online,
    jsonb_agg(
      jsonb_build_object(
        'staff_id', s.staff_id,
        'name', s.name,
        'role', s.role,
        'specialty', s.specialty,
        'services', s.services,
        'available_days', s.available_days,
        'appointment_duration', s.appointment_duration,
        'is_featured', s.is_featured,
        'rating', s.rating,
        'bio', s.short_bio
      )
      ORDER BY s.is_featured DESC, s.rating DESC NULLS LAST, s.name ASC
    ) FILTER (WHERE s.is_available_online = TRUE) AS staff_list
  FROM locations l
  LEFT JOIN staff s ON s.location_id = l.location_id AND s.is_active = TRUE
  WHERE l.chatwoot_inbox_id = p_inbox_id
    AND l.is_active = TRUE
  GROUP BY 
    l.client_id,               -- ✅ ADICIONADO ao GROUP BY
    l.location_id, l.name, l.location_type, l.address, l.city, 
    l.phone, l.whatsapp_number, l.working_hours, l.services_offered
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TESTE DE VALIDAÇÃO
-- ============================================================================

-- Deve retornar client_id = 'estetica_bella_rede' para inbox_id = 3
SELECT 
  client_id,
  location_name,
  total_staff,
  staff_available_online
FROM get_location_staff_summary(3);

-- ============================================================================
-- COMENTÁRIO ATUALIZADO
-- ============================================================================

COMMENT ON FUNCTION get_location_staff_summary(INT) IS 
'🔒 VERSÃO SEGURA: Retorna client_id + dados da localização + profissionais. 
Uso: Workflow usa client_id para prevenir spoofing e acesso cruzado entre tenants.
O client_id vem diretamente do banco baseado no inbox_id (Chatwoot), não do webhook.';

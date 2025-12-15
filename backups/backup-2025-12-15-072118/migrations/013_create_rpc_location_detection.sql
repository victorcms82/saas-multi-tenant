-- ============================================================================
-- Migration 013: Criar RPCs para Location Detection e Staff Lookup
-- ============================================================================
-- Objetivo: Funções para workflow n8n detectar localização e buscar profissionais
-- Uso: Workflow detecta inbox_id → busca localização → busca staff disponível
-- ============================================================================

-- ============================================================================
-- RPC 1: get_location_by_inbox
-- ============================================================================
-- Detecta a localização baseada no chatwoot_inbox_id
-- Uso: Workflow recebe mensagem → pega inbox_id → chama RPC → sabe qual clínica
-- ============================================================================

CREATE OR REPLACE FUNCTION get_location_by_inbox(p_inbox_id INT)
RETURNS TABLE (
  location_id TEXT,
  location_name TEXT,
  location_type TEXT,
  display_name TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  phone TEXT,
  whatsapp_number TEXT,
  email TEXT,
  website TEXT,
  working_hours JSONB,
  services_offered JSONB,
  specialties JSONB,
  timezone TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_primary BOOLEAN,
  client_id TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.location_id::TEXT,
    l.name::TEXT AS location_name,
    l.location_type::TEXT,
    l.display_name::TEXT,
    l.address::TEXT,
    l.city::TEXT,
    l.state::TEXT,
    l.zip_code::TEXT,
    l.phone::TEXT,
    l.whatsapp_number::TEXT,
    l.email::TEXT,
    l.website::TEXT,
    l.working_hours,
    l.services_offered,
    l.specialties,
    l.timezone::TEXT,
    l.latitude,
    l.longitude,
    l.is_primary,
    l.client_id::TEXT
  FROM locations l
  WHERE l.chatwoot_inbox_id = p_inbox_id
    AND l.is_active = TRUE
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentário para documentação
COMMENT ON FUNCTION get_location_by_inbox(INT) IS 
'Detecta a localização baseada no Chatwoot inbox_id. Retorna dados completos da clínica/loja. Uso: workflow n8n chama esta função para saber de qual localização veio a mensagem.';


-- ============================================================================
-- RPC 2: get_staff_by_location
-- ============================================================================
-- Busca profissionais de uma localização específica
-- Filtro opcional por serviço oferecido
-- Uso: Workflow sabe a localização → busca profissionais disponíveis para mostrar ao cliente
-- ============================================================================

CREATE OR REPLACE FUNCTION get_staff_by_location(
  p_location_id TEXT,
  p_service TEXT DEFAULT NULL,
  p_include_unavailable BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  staff_id TEXT,
  staff_name TEXT,
  display_name TEXT,
  role TEXT,
  specialty TEXT,
  specialties JSONB,
  services JSONB,
  bio TEXT,
  short_bio TEXT,
  photo_url TEXT,
  phone TEXT,
  whatsapp_number TEXT,
  email TEXT,
  calendar_id TEXT,
  calendar_email TEXT,
  available_days TEXT[],
  working_hours JSONB,
  appointment_duration INT,
  rating DECIMAL(3, 2),
  total_reviews INT,
  is_featured BOOLEAN,
  professional_id TEXT,
  professional_council TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.staff_id::TEXT,
    s.name::TEXT AS staff_name,
    s.display_name::TEXT,
    s.role::TEXT,
    s.specialty::TEXT,
    s.specialties,
    s.services,
    s.bio::TEXT,
    s.short_bio::TEXT,
    s.photo_url::TEXT,
    s.phone::TEXT,
    s.whatsapp_number::TEXT,
    s.email::TEXT,
    s.calendar_id::TEXT,
    s.calendar_email::TEXT,
    s.available_days::TEXT[],
    s.working_hours,
    s.appointment_duration,
    s.rating,
    s.total_reviews,
    s.is_featured,
    s.professional_id::TEXT,
    s.professional_council::TEXT
  FROM staff s
  WHERE s.location_id = p_location_id
    AND s.is_active = TRUE
    AND (p_include_unavailable OR s.is_available_online = TRUE)
    AND (
      p_service IS NULL 
      OR s.services @> to_jsonb(ARRAY[p_service])
      OR s.specialties @> to_jsonb(ARRAY[p_service])
    )
  ORDER BY 
    s.is_featured DESC,
    s.rating DESC NULLS LAST,
    s.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentário para documentação
COMMENT ON FUNCTION get_staff_by_location(TEXT, TEXT, BOOLEAN) IS 
'Busca profissionais de uma localização. Filtro opcional por serviço. Retorna apenas profissionais ativos e disponíveis online (exceto se p_include_unavailable=true). Ordenado por: featured → rating → nome.';


-- ============================================================================
-- RPC 3: get_available_slots (preparação para Google Calendar)
-- ============================================================================
-- Busca horários disponíveis de um profissional em uma data específica
-- Versão atual: Retorna working_hours do profissional
-- Versão futura: Integrar com Google Calendar API para verificar slots reais
-- ============================================================================

CREATE OR REPLACE FUNCTION get_available_slots(
  p_staff_id TEXT,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  staff_id TEXT,
  staff_name TEXT,
  calendar_id TEXT,
  calendar_email TEXT,
  date DATE,
  day_of_week TEXT,
  working_hours JSONB,
  appointment_duration INT,
  buffer_time INT,
  max_appointments_per_day INT,
  calendar_sync_enabled BOOLEAN,
  available_days TEXT[]
) AS $$
DECLARE
  v_day_of_week TEXT;
BEGIN
  -- Determinar dia da semana
  v_day_of_week := CASE EXTRACT(DOW FROM p_date)
    WHEN 0 THEN 'sunday'
    WHEN 1 THEN 'monday'
    WHEN 2 THEN 'tuesday'
    WHEN 3 THEN 'wednesday'
    WHEN 4 THEN 'thursday'
    WHEN 5 THEN 'friday'
    WHEN 6 THEN 'saturday'
  END;

  RETURN QUERY
  SELECT 
    s.staff_id::TEXT,
    s.name::TEXT AS staff_name,
    s.calendar_id::TEXT,
    s.calendar_email::TEXT,
    p_date AS date,
    v_day_of_week AS day_of_week,
    s.working_hours,
    s.appointment_duration,
    s.buffer_time,
    s.max_appointments_per_day,
    s.calendar_sync_enabled,
    s.available_days::TEXT[]
  FROM staff s
  WHERE s.staff_id = p_staff_id
    AND s.is_active = TRUE
    AND s.is_available_online = TRUE
    AND v_day_of_week = ANY(s.available_days);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentário para documentação
COMMENT ON FUNCTION get_available_slots(TEXT, DATE) IS 
'Retorna informações de disponibilidade de um profissional em uma data específica. Versão atual: retorna working_hours. Versão futura: integrar com Google Calendar API para verificar slots reais livres.';


-- ============================================================================
-- RPC 4: get_location_staff_summary (útil para system prompt)
-- ============================================================================
-- Retorna resumo completo: localização + lista de profissionais
-- Uso: Workflow usa para construir contexto completo para o LLM
-- ============================================================================

CREATE OR REPLACE FUNCTION get_location_staff_summary(p_inbox_id INT)
RETURNS TABLE (
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
    l.location_id, l.name, l.location_type, l.address, l.city, 
    l.phone, l.whatsapp_number, l.working_hours, l.services_offered
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentário para documentação
COMMENT ON FUNCTION get_location_staff_summary(INT) IS 
'Retorna resumo completo: dados da localização + array JSON com todos os profissionais disponíveis. Ideal para injetar no system prompt do LLM. Uso: workflow chama uma única vez e tem todo o contexto.';


-- ============================================================================
-- TESTES E VALIDAÇÃO
-- ============================================================================

-- Teste 1: Buscar localização pelo inbox_id
-- (Substitua pelo inbox_id real do Chatwoot após configuração)
SELECT * FROM get_location_by_inbox(123456);

-- Teste 2: Buscar todos os profissionais da Bella Barra
SELECT * FROM get_staff_by_location('bella_barra_001');

-- Teste 3: Buscar profissionais que fazem "harmonizacao_facial" em Ipanema
SELECT * FROM get_staff_by_location('bella_ipanema_001', 'harmonizacao_facial');

-- Teste 4: Buscar disponibilidade da Ana Silva para hoje
SELECT * FROM get_available_slots('staff_bella_barra_ana', CURRENT_DATE);

-- Teste 5: Buscar disponibilidade da Ana Silva para uma terça-feira específica
SELECT * FROM get_available_slots('staff_bella_barra_ana', '2025-11-18');

-- Teste 6: Buscar resumo completo (location + staff) pelo inbox
SELECT * FROM get_location_staff_summary(123456);


-- ============================================================================
-- PERMISSÕES (ajustar conforme sua configuração de RLS)
-- ============================================================================

-- Permitir execução anônima (para workflow n8n chamar via API)
-- ATENÇÃO: Ajuste conforme suas políticas de segurança!
-- Opção 1: Permitir execução para service_role (recomendado)
-- GRANT EXECUTE ON FUNCTION get_location_by_inbox(INT) TO service_role;
-- GRANT EXECUTE ON FUNCTION get_staff_by_location(VARCHAR, VARCHAR, BOOLEAN) TO service_role;
-- GRANT EXECUTE ON FUNCTION get_available_slots(VARCHAR, DATE) TO service_role;
-- GRANT EXECUTE ON FUNCTION get_location_staff_summary(INT) TO service_role;

-- Opção 2: Permitir execução anônima (menos seguro, mas mais simples para testes)
-- GRANT EXECUTE ON FUNCTION get_location_by_inbox(INT) TO anon;
-- GRANT EXECUTE ON FUNCTION get_staff_by_location(VARCHAR, VARCHAR, BOOLEAN) TO anon;
-- GRANT EXECUTE ON FUNCTION get_available_slots(VARCHAR, DATE) TO anon;
-- GRANT EXECUTE ON FUNCTION get_location_staff_summary(INT) TO anon;


-- ============================================================================
-- VALIDAÇÃO FINAL
-- ============================================================================

-- Listar todas as funções criadas
SELECT 
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'get_%'
ORDER BY routine_name;

-- Verificar parâmetros de cada função
SELECT 
  r.routine_name,
  p.parameter_name,
  p.data_type,
  p.parameter_mode
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p 
  ON r.specific_name = p.specific_name
WHERE r.routine_schema = 'public'
  AND r.routine_name LIKE 'get_%'
ORDER BY r.routine_name, p.ordinal_position;

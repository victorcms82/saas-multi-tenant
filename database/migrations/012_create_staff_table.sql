-- ============================================================================
-- Migration 012: Criar tabela STAFF (Equipe/Profissionais)
-- ============================================================================
-- Objetivo: Arquitetura genérica para QUALQUER tipo de profissional
-- Casos de uso:
--   - Clínicas: Médicos, dentistas, dermatologistas, fisioterapeutas
--   - Lojas: Vendedores, gerentes, atendentes, estoquistas
--   - Restaurantes: Chefs, garçons, bartenders, recepcionistas
--   - Escritórios: Advogados, contadores, consultores, secretárias
--   - Qualquer negócio com equipe de profissionais
-- ============================================================================

-- Criar tabela staff
CREATE TABLE IF NOT EXISTS staff (
  staff_id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  location_id VARCHAR(255) NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
  client_id VARCHAR(255) NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  
  -- Identificação
  name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255), -- Nome de exibição/artístico
  role VARCHAR(100), -- "dentist", "salesperson", "receptionist", "manager", "chef", "lawyer", etc.
  job_title VARCHAR(150), -- Título formal (ex: "Gerente de Vendas", "Dentista Ortodontista")
  
  -- Especialização
  specialty VARCHAR(150), -- Especialidade principal
  specialties JSONB DEFAULT '[]', -- Array de especialidades (["ortodontia", "implantes"])
  certifications JSONB DEFAULT '[]', -- Certificações e qualificações
  languages JSONB DEFAULT '["pt-BR"]', -- Idiomas falados
  
  -- Biografia
  bio TEXT,
  short_bio VARCHAR(500), -- Bio curta para cards/preview
  education TEXT, -- Formação acadêmica
  experience_years INT, -- Anos de experiência
  
  -- Mídia
  photo_url TEXT,
  profile_image_url TEXT,
  cover_image_url TEXT,
  gallery_images JSONB DEFAULT '[]',
  
  -- Integração Google Calendar (CRÍTICO para agendamento!)
  calendar_id VARCHAR(255), -- Google Calendar ID
  calendar_email VARCHAR(255), -- Email associado ao calendário
  calendar_sync_enabled BOOLEAN DEFAULT FALSE,
  
  -- Disponibilidade
  available_days VARCHAR[] DEFAULT ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'], -- Dias da semana disponíveis
  working_hours JSONB DEFAULT '[]', -- [{day: "monday", start: "09:00", end: "18:00", breaks: [{start: "12:00", end: "13:00"}]}]
  appointment_duration INT DEFAULT 60, -- Duração padrão de consulta/atendimento (minutos)
  buffer_time INT DEFAULT 0, -- Tempo de buffer entre atendimentos (minutos)
  max_appointments_per_day INT, -- Limite de atendimentos por dia
  
  -- Serviços oferecidos
  services JSONB DEFAULT '[]', -- Array de serviços que este profissional oferece
  service_prices JSONB DEFAULT '{}', -- {service_id: {price: 150, duration: 60, currency: "BRL"}}
  
  -- Contato
  phone VARCHAR(50),
  whatsapp_number VARCHAR(50),
  email VARCHAR(255),
  professional_email VARCHAR(255), -- Email profissional (ex: institucional)
  
  -- Registros profissionais
  professional_id VARCHAR(100), -- CRM, CRO, OAB, etc.
  professional_council VARCHAR(50), -- "CRM", "CRO", "OAB", "CREFITO", etc.
  professional_state VARCHAR(10), -- Estado do registro (ex: "SP", "RJ")
  
  -- Redes sociais
  instagram_handle VARCHAR(100),
  facebook_url TEXT,
  linkedin_url TEXT,
  website_url TEXT,
  
  -- Avaliações e Performance
  rating DECIMAL(3, 2), -- Avaliação média (0.00 a 5.00)
  total_reviews INT DEFAULT 0,
  total_appointments INT DEFAULT 0,
  
  -- Status e configurações
  is_active BOOLEAN DEFAULT TRUE,
  is_available_online BOOLEAN DEFAULT TRUE, -- Aceita agendamento online
  is_featured BOOLEAN DEFAULT FALSE, -- Profissional destaque
  hire_date DATE,
  termination_date DATE,
  
  -- Preferências
  preferred_contact_method VARCHAR(50) DEFAULT 'whatsapp', -- "whatsapp", "email", "phone", "sms"
  notification_settings JSONB DEFAULT '{}', -- Configurações de notificação
  booking_settings JSONB DEFAULT '{}', -- Configurações de agendamento
  
  -- Metadados
  settings JSONB DEFAULT '{}', -- Configurações customizadas
  metadata JSONB DEFAULT '{}', -- Dados adicionais flexíveis
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  
  -- Constraints
  CONSTRAINT valid_days CHECK (
    available_days <@ ARRAY['monday'::VARCHAR, 'tuesday'::VARCHAR, 'wednesday'::VARCHAR, 'thursday'::VARCHAR, 'friday'::VARCHAR, 'saturday'::VARCHAR, 'sunday'::VARCHAR]
  ),
  CONSTRAINT valid_rating CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5)),
  CONSTRAINT valid_appointment_duration CHECK (appointment_duration >= 0),
  CONSTRAINT valid_experience_years CHECK (experience_years IS NULL OR experience_years >= 0),
  CONSTRAINT valid_contact_method CHECK (
    preferred_contact_method IN ('whatsapp', 'email', 'phone', 'sms', 'app')
  )
);

-- Índices para performance
CREATE INDEX idx_staff_location ON staff(location_id);
CREATE INDEX idx_staff_client ON staff(client_id);
CREATE INDEX idx_staff_active ON staff(is_active);
CREATE INDEX idx_staff_calendar ON staff(calendar_id) WHERE calendar_id IS NOT NULL;
CREATE INDEX idx_staff_role ON staff(role);
CREATE INDEX idx_staff_specialty ON staff(specialty);
CREATE INDEX idx_staff_featured ON staff(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_staff_available_online ON staff(is_available_online) WHERE is_available_online = TRUE;

-- Índice GIN para busca em arrays JSONB
CREATE INDEX idx_staff_services ON staff USING GIN (services);
CREATE INDEX idx_staff_specialties ON staff USING GIN (specialties);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_staff_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_staff_updated_at
  BEFORE UPDATE ON staff
  FOR EACH ROW
  EXECUTE FUNCTION update_staff_updated_at();

-- Comentários para documentação
COMMENT ON TABLE staff IS 'Equipe/profissionais vinculados a localizações (médicos, vendedores, garçons, advogados, etc)';
COMMENT ON COLUMN staff.staff_id IS 'ID único do profissional';
COMMENT ON COLUMN staff.location_id IS 'Localização onde o profissional trabalha';
COMMENT ON COLUMN staff.client_id IS 'Cliente proprietário (multi-tenancy)';
COMMENT ON COLUMN staff.role IS 'Função/cargo genérico (dentist, salesperson, chef, lawyer, etc)';
COMMENT ON COLUMN staff.calendar_id IS 'Google Calendar ID para agendamentos';
COMMENT ON COLUMN staff.services IS 'Array JSON de serviços oferecidos';
COMMENT ON COLUMN staff.working_hours IS 'Horário de trabalho por dia da semana';

-- ============================================================================
-- DADOS DE EXEMPLO: Profissionais da Rede Bella
-- ============================================================================

-- Bella Barra (5 profissionais)
INSERT INTO staff (
  staff_id, location_id, client_id, name, role, specialty, specialties, bio,
  calendar_id, available_days, working_hours, appointment_duration, services,
  phone, email, professional_id, professional_council, professional_state,
  is_active, is_available_online, is_featured
) VALUES
  -- Profissional 1: Ana Silva (Gerente + Harmonização)
  (
    'staff_bella_barra_ana',
    'bella_barra_001',
    'estetica_bella_rede',
    'Ana Paula Silva',
    'aesthetic_specialist',
    'Harmonização Facial',
    '["harmonizacao_facial", "botox", "preenchimento"]'::JSONB,
    'Especialista em harmonização facial com mais de 10 anos de experiência. Formada pela USP.',
    NULL, -- Calendar ID a ser configurado
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "monday", "start": "09:00", "end": "18:00"}, {"day": "tuesday", "start": "09:00", "end": "18:00"}, {"day": "wednesday", "start": "09:00", "end": "18:00"}, {"day": "thursday", "start": "09:00", "end": "18:00"}, {"day": "friday", "start": "09:00", "end": "18:00"}]'::JSONB,
    60,
    '["harmonizacao_facial", "botox", "preenchimento"]'::JSONB,
    '+55 21 99999-1101',
    'ana.silva@bellaestetica.com.br',
    'CRM-123456',
    'CRM',
    'RJ',
    TRUE,
    TRUE,
    TRUE
  ),
  
  -- Profissional 2: Beatriz Costa
  (
    'staff_bella_barra_beatriz',
    'bella_barra_001',
    'estetica_bella_rede',
    'Beatriz Costa',
    'aesthetic_specialist',
    'Tratamentos Faciais',
    '["limpeza_de_pele", "peeling", "microagulhamento"]'::JSONB,
    'Especialista em tratamentos faciais e rejuvenescimento.',
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    '[{"day": "monday", "start": "09:00", "end": "19:00"}, {"day": "tuesday", "start": "09:00", "end": "19:00"}, {"day": "wednesday", "start": "09:00", "end": "19:00"}, {"day": "thursday", "start": "09:00", "end": "19:00"}, {"day": "friday", "start": "09:00", "end": "19:00"}, {"day": "saturday", "start": "09:00", "end": "14:00"}]'::JSONB,
    60,
    '["limpeza_de_pele", "peeling", "microagulhamento"]'::JSONB,
    '+55 21 99999-1102',
    'beatriz.costa@bellaestetica.com.br',
    NULL,
    NULL,
    NULL,
    TRUE,
    TRUE,
    FALSE
  ),
  
  -- Profissional 3: Carlos Mendes
  (
    'staff_bella_barra_carlos',
    'bella_barra_001',
    'estetica_bella_rede',
    'Carlos Mendes',
    'aesthetic_specialist',
    'Laser',
    '["laser", "depilacao_laser"]'::JSONB,
    'Especialista em tratamentos a laser.',
    NULL,
    ARRAY['tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "tuesday", "start": "10:00", "end": "19:00"}, {"day": "wednesday", "start": "10:00", "end": "19:00"}, {"day": "thursday", "start": "10:00", "end": "19:00"}, {"day": "friday", "start": "10:00", "end": "19:00"}]'::JSONB,
    45,
    '["laser", "depilacao_laser"]'::JSONB,
    '+55 21 99999-1103',
    'carlos.mendes@bellaestetica.com.br',
    NULL,
    NULL,
    NULL,
    TRUE,
    TRUE,
    FALSE
  ),
  
  -- Profissional 4: Diana Santos (Recepcionista)
  (
    'staff_bella_barra_diana',
    'bella_barra_001',
    'estetica_bella_rede',
    'Diana Santos',
    'receptionist',
    'Atendimento',
    '["atendimento", "agendamento"]'::JSONB,
    'Recepcionista responsável pelo atendimento e agendamentos.',
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    '[{"day": "monday", "start": "09:00", "end": "19:00"}, {"day": "tuesday", "start": "09:00", "end": "19:00"}, {"day": "wednesday", "start": "09:00", "end": "19:00"}, {"day": "thursday", "start": "09:00", "end": "19:00"}, {"day": "friday", "start": "09:00", "end": "19:00"}, {"day": "saturday", "start": "09:00", "end": "14:00"}]'::JSONB,
    0, -- Não faz atendimentos
    '[]'::JSONB,
    '+55 21 99999-1104',
    'diana.santos@bellaestetica.com.br',
    NULL,
    NULL,
    NULL,
    TRUE,
    FALSE, -- Não aceita agendamento online (é recepcionista)
    FALSE
  ),
  
  -- Profissional 5: Eduardo Lima
  (
    'staff_bella_barra_eduardo',
    'bella_barra_001',
    'estetica_bella_rede',
    'Eduardo Lima',
    'aesthetic_specialist',
    'Tratamentos Corporais',
    '["massagem_modeladora", "drenagem_linfatica"]'::JSONB,
    'Especialista em tratamentos corporais e drenagem linfática.',
    NULL,
    ARRAY['monday', 'wednesday', 'friday'],
    '[{"day": "monday", "start": "09:00", "end": "18:00"}, {"day": "wednesday", "start": "09:00", "end": "18:00"}, {"day": "friday", "start": "09:00", "end": "18:00"}]'::JSONB,
    90,
    '["massagem_modeladora", "drenagem_linfatica"]'::JSONB,
    '+55 21 99999-1105',
    'eduardo.lima@bellaestetica.com.br',
    NULL,
    NULL,
    NULL,
    TRUE,
    TRUE,
    FALSE
  );

-- Bella Ipanema (8 profissionais) - Vou adicionar apenas 3 para exemplo
INSERT INTO staff (
  staff_id, location_id, client_id, name, role, specialty, specialties,
  calendar_id, available_days, working_hours, appointment_duration, services,
  phone, email, is_active, is_available_online, is_featured
) VALUES
  (
    'staff_bella_ipanema_fernanda',
    'bella_ipanema_001',
    'estetica_bella_rede',
    'Fernanda Oliveira',
    'aesthetic_specialist',
    'Harmonização Facial',
    '["harmonizacao_facial", "botox", "preenchimento"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "monday", "start": "08:00", "end": "20:00"}, {"day": "tuesday", "start": "08:00", "end": "20:00"}, {"day": "wednesday", "start": "08:00", "end": "20:00"}, {"day": "thursday", "start": "08:00", "end": "20:00"}, {"day": "friday", "start": "08:00", "end": "20:00"}]'::JSONB,
    60,
    '["harmonizacao_facial", "botox", "preenchimento"]'::JSONB,
    '+55 21 99999-2201',
    'fernanda.oliveira@bellaestetica.com.br',
    TRUE,
    TRUE,
    TRUE
  ),
  (
    'staff_bella_ipanema_gabriel',
    'bella_ipanema_001',
    'estetica_bella_rede',
    'Gabriel Ferreira',
    'aesthetic_specialist',
    'Massagem',
    '["massagem_modeladora", "massagem_relaxante"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    '[{"day": "monday", "start": "08:00", "end": "20:00"}, {"day": "tuesday", "start": "08:00", "end": "20:00"}, {"day": "wednesday", "start": "08:00", "end": "20:00"}, {"day": "thursday", "start": "08:00", "end": "20:00"}, {"day": "friday", "start": "08:00", "end": "20:00"}, {"day": "saturday", "start": "09:00", "end": "15:00"}]'::JSONB,
    90,
    '["massagem_modeladora", "massagem_relaxante"]'::JSONB,
    '+55 21 99999-2202',
    'gabriel.ferreira@bellaestetica.com.br',
    TRUE,
    TRUE,
    FALSE
  ),
  (
    'staff_bella_ipanema_helena',
    'bella_ipanema_001',
    'estetica_bella_rede',
    'Helena Martins',
    'aesthetic_specialist',
    'Limpeza de Pele',
    '["limpeza_de_pele", "peeling"]'::JSONB,
    NULL,
    ARRAY['tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    '[{"day": "tuesday", "start": "08:00", "end": "20:00"}, {"day": "wednesday", "start": "08:00", "end": "20:00"}, {"day": "thursday", "start": "08:00", "end": "20:00"}, {"day": "friday", "start": "08:00", "end": "20:00"}, {"day": "saturday", "start": "09:00", "end": "15:00"}]'::JSONB,
    60,
    '["limpeza_de_pele", "peeling"]'::JSONB,
    '+55 21 99999-2203',
    'helena.martins@bellaestetica.com.br',
    TRUE,
    TRUE,
    FALSE
  );

-- Bella Copacabana (3 profissionais)
INSERT INTO staff (
  staff_id, location_id, client_id, name, role, specialty, specialties,
  calendar_id, available_days, working_hours, appointment_duration, services,
  phone, email, professional_id, professional_council, professional_state,
  is_active, is_available_online, is_featured
) VALUES
  (
    'staff_bella_copa_isabela',
    'bella_copacabana_001',
    'estetica_bella_rede',
    'Isabela Rodrigues',
    'aesthetic_specialist',
    'Harmonização Facial',
    '["botox", "preenchimento"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "monday", "start": "09:00", "end": "18:00"}, {"day": "tuesday", "start": "09:00", "end": "18:00"}, {"day": "wednesday", "start": "09:00", "end": "18:00"}, {"day": "thursday", "start": "09:00", "end": "18:00"}, {"day": "friday", "start": "09:00", "end": "18:00"}]'::JSONB,
    60,
    '["botox", "preenchimento"]'::JSONB,
    '+55 21 99999-3301',
    'isabela.rodrigues@bellaestetica.com.br',
    'CRM-789012',
    'CRM',
    'RJ',
    TRUE,
    TRUE,
    TRUE
  ),
  (
    'staff_bella_copa_joao',
    'bella_copacabana_001',
    'estetica_bella_rede',
    'João Pedro Alves',
    'aesthetic_specialist',
    'Limpeza de Pele',
    '["limpeza_de_pele", "peeling"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "monday", "start": "09:00", "end": "18:00"}, {"day": "tuesday", "start": "09:00", "end": "18:00"}, {"day": "wednesday", "start": "09:00", "end": "18:00"}, {"day": "thursday", "start": "09:00", "end": "18:00"}, {"day": "friday", "start": "09:00", "end": "18:00"}]'::JSONB,
    60,
    '["limpeza_de_pele", "peeling"]'::JSONB,
    '+55 21 99999-3302',
    'joao.alves@bellaestetica.com.br',
    NULL,
    NULL,
    NULL,
    TRUE,
    TRUE,
    FALSE
  ),
  (
    'staff_bella_copa_katia',
    'bella_copacabana_001',
    'estetica_bella_rede',
    'Kátia Souza',
    'receptionist',
    'Atendimento',
    '["atendimento"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "monday", "start": "09:00", "end": "18:00"}, {"day": "tuesday", "start": "09:00", "end": "18:00"}, {"day": "wednesday", "start": "09:00", "end": "18:00"}, {"day": "thursday", "start": "09:00", "end": "18:00"}, {"day": "friday", "start": "09:00", "end": "18:00"}]'::JSONB,
    0,
    '[]'::JSONB,
    '+55 21 99999-3303',
    'katia.souza@bellaestetica.com.br',
    NULL,
    NULL,
    NULL,
    TRUE,
    FALSE,
    FALSE
  );

-- Bella Botafogo (6 profissionais) - Adicionando 3 para exemplo
INSERT INTO staff (
  staff_id, location_id, client_id, name, role, specialty, specialties,
  calendar_id, available_days, working_hours, appointment_duration, services,
  phone, email, is_active, is_available_online, is_featured
) VALUES
  (
    'staff_bella_botafogo_laura',
    'bella_botafogo_001',
    'estetica_bella_rede',
    'Laura Nascimento',
    'aesthetic_specialist',
    'Depilação Laser',
    '["depilacao_laser"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    '[{"day": "monday", "start": "08:00", "end": "19:00"}, {"day": "tuesday", "start": "08:00", "end": "19:00"}, {"day": "wednesday", "start": "08:00", "end": "19:00"}, {"day": "thursday", "start": "08:00", "end": "19:00"}, {"day": "friday", "start": "08:00", "end": "19:00"}, {"day": "saturday", "start": "09:00", "end": "13:00"}]'::JSONB,
    45,
    '["depilacao_laser"]'::JSONB,
    '+55 21 99999-4401',
    'laura.nascimento@bellaestetica.com.br',
    TRUE,
    TRUE,
    TRUE
  ),
  (
    'staff_bella_botafogo_marcos',
    'bella_botafogo_001',
    'estetica_bella_rede',
    'Marcos Vieira',
    'aesthetic_specialist',
    'Harmonização Facial',
    '["harmonizacao_facial", "botox", "preenchimento"]'::JSONB,
    NULL,
    ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    '[{"day": "monday", "start": "08:00", "end": "19:00"}, {"day": "tuesday", "start": "08:00", "end": "19:00"}, {"day": "wednesday", "start": "08:00", "end": "19:00"}, {"day": "thursday", "start": "08:00", "end": "19:00"}, {"day": "friday", "start": "08:00", "end": "19:00"}]'::JSONB,
    60,
    '["harmonizacao_facial", "botox", "preenchimento"]'::JSONB,
    '+55 21 99999-4402',
    'marcos.vieira@bellaestetica.com.br',
    TRUE,
    TRUE,
    FALSE
  ),
  (
    'staff_bella_botafogo_natalia',
    'bella_botafogo_001',
    'estetica_bella_rede',
    'Natália Freitas',
    'aesthetic_specialist',
    'Microagulhamento',
    '["microagulhamento", "peeling"]'::JSONB,
    NULL,
    ARRAY['tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    '[{"day": "tuesday", "start": "08:00", "end": "19:00"}, {"day": "wednesday", "start": "08:00", "end": "19:00"}, {"day": "thursday", "start": "08:00", "end": "19:00"}, {"day": "friday", "start": "08:00", "end": "19:00"}, {"day": "saturday", "start": "09:00", "end": "13:00"}]'::JSONB,
    75,
    '["microagulhamento", "peeling"]'::JSONB,
    '+55 21 99999-4403',
    'natalia.freitas@bellaestetica.com.br',
    TRUE,
    TRUE,
    FALSE
  );

-- ============================================================================
-- VALIDAÇÃO
-- ============================================================================
-- Verificar criação por localização
SELECT 
  l.name as location_name,
  COUNT(s.staff_id) as total_staff,
  COUNT(s.staff_id) FILTER (WHERE s.is_available_online = TRUE) as available_online,
  COUNT(s.staff_id) FILTER (WHERE s.role = 'aesthetic_specialist') as specialists,
  COUNT(s.staff_id) FILTER (WHERE s.role = 'receptionist') as receptionists
FROM locations l
LEFT JOIN staff s ON s.location_id = l.location_id
WHERE l.client_id = 'estetica_bella_rede'
GROUP BY l.name, l.location_id
ORDER BY l.name;

-- Verificar profissionais por especialidade
SELECT 
  specialty,
  COUNT(*) as total_professionals
FROM staff
WHERE client_id = 'estetica_bella_rede' AND is_active = TRUE
GROUP BY specialty
ORDER BY total_professionals DESC;

-- Verificar profissionais disponíveis por dia
WITH staff_days AS (
  SELECT unnest(available_days) as day_of_week
  FROM staff
  WHERE client_id = 'estetica_bella_rede' AND is_available_online = TRUE
)
SELECT 
  day_of_week,
  COUNT(*) as staff_available
FROM staff_days
GROUP BY day_of_week
ORDER BY 
  CASE day_of_week
    WHEN 'monday' THEN 1
    WHEN 'tuesday' THEN 2
    WHEN 'wednesday' THEN 3
    WHEN 'thursday' THEN 4
    WHEN 'friday' THEN 5
    WHEN 'saturday' THEN 6
    WHEN 'sunday' THEN 7
  END;

COMMENT ON COLUMN staff.available_days IS 'Array de dias da semana disponíveis: [''monday'', ''tuesday'', ...]';
COMMENT ON COLUMN staff.working_hours IS 'Formato: [{"day": "monday", "start": "09:00", "end": "18:00", "breaks": []}]';

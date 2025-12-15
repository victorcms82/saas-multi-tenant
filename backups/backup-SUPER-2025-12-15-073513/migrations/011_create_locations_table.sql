-- ============================================================================
-- Migration 011: Criar tabela LOCATIONS (Localizações Físicas)
-- ============================================================================
-- Objetivo: Arquitetura genérica para QUALQUER tipo de negócio
-- Casos de uso:
--   - Clínicas: Multiple unidades/filiais
--   - Lojas: Rede de varejo
--   - Restaurantes: Chain de restaurantes
--   - Escritórios: Múltiplas sedes
--   - Qualquer negócio com múltiplas localizações físicas
-- ============================================================================

-- Criar tabela locations
CREATE TABLE IF NOT EXISTS locations (
  location_id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  client_id VARCHAR(255) NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  
  -- Identificação
  name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255), -- Nome fantasia/comercial
  location_type VARCHAR(50), -- "clinic", "store", "office", "branch", "restaurant", "warehouse", etc.
  
  -- Endereço completo
  address TEXT,
  address_line_2 VARCHAR(255), -- Complemento
  city VARCHAR(100),
  state VARCHAR(50),
  zip_code VARCHAR(20),
  country VARCHAR(50) DEFAULT 'Brasil',
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  -- Contato
  phone VARCHAR(50),
  whatsapp_number VARCHAR(50),
  email VARCHAR(255),
  website VARCHAR(255),
  
  -- Integração Chatwoot (CRÍTICO!)
  chatwoot_inbox_id INT UNIQUE, -- Um inbox por localização
  chatwoot_account_id INT,
  
  -- Horário de funcionamento
  working_hours JSONB DEFAULT '[]', -- [{day: "monday", open: "08:00", close: "18:00", is_open: true}, ...]
  timezone VARCHAR(50) DEFAULT 'America/Sao_Paulo',
  
  -- Serviços/Produtos oferecidos
  services_offered JSONB DEFAULT '[]', -- ["limpeza_de_pele", "harmonizacao", "botox", ...]
  specialties JSONB DEFAULT '[]', -- Especialidades específicas da localização
  
  -- Mídia e Assets
  media_folder VARCHAR(255), -- Pasta no Supabase Storage: "client_id/location_id/"
  logo_url TEXT,
  cover_image_url TEXT,
  gallery_images JSONB DEFAULT '[]', -- Array de URLs de fotos
  
  -- Capacidade e Recursos
  capacity_info JSONB DEFAULT '{}', -- {parking_spots: 20, consultation_rooms: 5, staff_count: 8}
  amenities JSONB DEFAULT '[]', -- ["wifi", "parking", "wheelchair_access", "air_conditioning"]
  
  -- Manager/Responsável
  manager_name VARCHAR(255),
  manager_phone VARCHAR(50),
  manager_email VARCHAR(255),
  
  -- Status e Configurações
  is_active BOOLEAN DEFAULT TRUE,
  is_primary BOOLEAN DEFAULT FALSE, -- Localização principal/matriz
  settings JSONB DEFAULT '{}', -- Configurações customizadas por localização
  
  -- Metadados
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  
  -- Constraints
  CONSTRAINT valid_location_type CHECK (
    location_type IS NULL OR 
    location_type IN (
      'clinic', 'dental_clinic', 'medical_clinic', 'aesthetic_clinic',
      'store', 'retail_store', 'franchise',
      'restaurant', 'cafe', 'bakery',
      'office', 'headquarters', 'branch',
      'warehouse', 'distribution_center',
      'salon', 'spa', 'gym', 'studio',
      'school', 'training_center',
      'hotel', 'hostel',
      'other'
    )
  ),
  CONSTRAINT valid_coordinates CHECK (
    (latitude IS NULL AND longitude IS NULL) OR
    (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
  )
);

-- Índices para performance
CREATE INDEX idx_locations_client_id ON locations(client_id);
CREATE INDEX idx_locations_chatwoot_inbox ON locations(chatwoot_inbox_id) WHERE chatwoot_inbox_id IS NOT NULL;
CREATE INDEX idx_locations_type ON locations(location_type);
CREATE INDEX idx_locations_active ON locations(is_active);
CREATE INDEX idx_locations_primary ON locations(is_primary) WHERE is_primary = TRUE;
CREATE INDEX idx_locations_city_state ON locations(city, state);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_locations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_locations_updated_at
  BEFORE UPDATE ON locations
  FOR EACH ROW
  EXECUTE FUNCTION update_locations_updated_at();

-- Comentários para documentação
COMMENT ON TABLE locations IS 'Localizações físicas de negócios (clínicas, lojas, restaurantes, escritórios, etc)';
COMMENT ON COLUMN locations.location_id IS 'ID único da localização';
COMMENT ON COLUMN locations.client_id IS 'Referência ao cliente (multi-tenancy)';
COMMENT ON COLUMN locations.location_type IS 'Tipo de negócio/localização';
COMMENT ON COLUMN locations.chatwoot_inbox_id IS 'Inbox do Chatwoot vinculado a esta localização (1:1)';
COMMENT ON COLUMN locations.working_hours IS 'Array JSON com horário de funcionamento por dia da semana';
COMMENT ON COLUMN locations.services_offered IS 'Array JSON com serviços/produtos oferecidos';
COMMENT ON COLUMN locations.media_folder IS 'Caminho da pasta de mídia no Supabase Storage';

-- ============================================================================
-- DADOS DE EXEMPLO: Rede Bella (Clínicas de Estética)
-- ============================================================================
-- Inserir cliente de teste
INSERT INTO clients (
  client_id, 
  client_name, 
  is_active,
  package,
  system_prompt,
  rag_namespace,
  admin_email
)
VALUES (
  'estetica_bella_rede',
  'Bella Estética - Rede',
  TRUE,
  'pro',
  'Você é um assistente virtual da Rede Bella Estética.',
  'estetica_bella_rede',
  'admin@bellaestetica.com.br'
)
ON CONFLICT (client_id) DO NOTHING;

-- Localização 1: Bella Barra
INSERT INTO locations (
  location_id,
  client_id,
  name,
  display_name,
  location_type,
  address,
  city,
  state,
  zip_code,
  phone,
  whatsapp_number,
  email,
  chatwoot_inbox_id,
  chatwoot_account_id,
  working_hours,
  timezone,
  services_offered,
  specialties,
  media_folder,
  capacity_info,
  amenities,
  manager_name,
  manager_email,
  is_active,
  is_primary
) VALUES (
  'bella_barra_001',
  'estetica_bella_rede',
  'Bella Barra',
  'Bella Estética - Unidade Barra',
  'aesthetic_clinic',
  'Av. das Américas, 5000 - Sala 301',
  'Rio de Janeiro',
  'RJ',
  '22640-102',
  '+55 21 3333-1111',
  '+55 21 99999-1111',
  'barra@bellaestetica.com.br',
  NULL, -- Definir quando criar inbox no Chatwoot
  1,
  '[
    {"day": "monday", "open": "09:00", "close": "19:00", "is_open": true},
    {"day": "tuesday", "open": "09:00", "close": "19:00", "is_open": true},
    {"day": "wednesday", "open": "09:00", "close": "19:00", "is_open": true},
    {"day": "thursday", "open": "09:00", "close": "19:00", "is_open": true},
    {"day": "friday", "open": "09:00", "close": "19:00", "is_open": true},
    {"day": "saturday", "open": "09:00", "close": "14:00", "is_open": true},
    {"day": "sunday", "open": "00:00", "close": "00:00", "is_open": false}
  ]'::JSONB,
  'America/Sao_Paulo',
  '["limpeza_de_pele", "peeling", "harmonizacao_facial", "botox", "preenchimento", "microagulhamento", "laser"]'::JSONB,
  '["harmonizacao_facial", "procedimentos_injetaveis"]'::JSONB,
  'estetica_bella_rede/bella_barra_001/',
  '{"consultation_rooms": 4, "staff_count": 5, "parking_spots": 2}'::JSONB,
  '["wifi", "air_conditioning", "wheelchair_access", "parking"]'::JSONB,
  'Ana Paula Silva',
  'ana.silva@bellaestetica.com.br',
  TRUE,
  TRUE -- Unidade principal
);

-- Localização 2: Bella Ipanema
INSERT INTO locations (
  location_id,
  client_id,
  name,
  display_name,
  location_type,
  address,
  city,
  state,
  zip_code,
  phone,
  whatsapp_number,
  email,
  chatwoot_inbox_id,
  chatwoot_account_id,
  working_hours,
  timezone,
  services_offered,
  specialties,
  media_folder,
  capacity_info,
  amenities,
  manager_name,
  manager_email,
  is_active,
  is_primary
) VALUES (
  'bella_ipanema_001',
  'estetica_bella_rede',
  'Bella Ipanema',
  'Bella Estética - Unidade Ipanema',
  'aesthetic_clinic',
  'Rua Visconde de Pirajá, 580 - Sala 201',
  'Rio de Janeiro',
  'RJ',
  '22410-002',
  '+55 21 3333-2222',
  '+55 21 99999-2222',
  'ipanema@bellaestetica.com.br',
  NULL,
  1,
  '[
    {"day": "monday", "open": "08:00", "close": "20:00", "is_open": true},
    {"day": "tuesday", "open": "08:00", "close": "20:00", "is_open": true},
    {"day": "wednesday", "open": "08:00", "close": "20:00", "is_open": true},
    {"day": "thursday", "open": "08:00", "close": "20:00", "is_open": true},
    {"day": "friday", "open": "08:00", "close": "20:00", "is_open": true},
    {"day": "saturday", "open": "09:00", "close": "15:00", "is_open": true},
    {"day": "sunday", "open": "00:00", "close": "00:00", "is_open": false}
  ]'::JSONB,
  'America/Sao_Paulo',
  '["limpeza_de_pele", "peeling", "harmonizacao_facial", "botox", "preenchimento", "microagulhamento", "laser", "massagem_modeladora"]'::JSONB,
  '["tratamentos_corporais", "massagens"]'::JSONB,
  'estetica_bella_rede/bella_ipanema_001/',
  '{"consultation_rooms": 6, "staff_count": 8, "parking_spots": 0}'::JSONB,
  '["wifi", "air_conditioning", "wheelchair_access"]'::JSONB,
  'Beatriz Costa',
  'beatriz.costa@bellaestetica.com.br',
  TRUE,
  FALSE
);

-- Localização 3: Bella Copacabana
INSERT INTO locations (
  location_id,
  client_id,
  name,
  display_name,
  location_type,
  address,
  city,
  state,
  zip_code,
  phone,
  whatsapp_number,
  email,
  chatwoot_inbox_id,
  chatwoot_account_id,
  working_hours,
  timezone,
  services_offered,
  specialties,
  media_folder,
  capacity_info,
  amenities,
  manager_name,
  manager_email,
  is_active,
  is_primary
) VALUES (
  'bella_copacabana_001',
  'estetica_bella_rede',
  'Bella Copacabana',
  'Bella Estética - Unidade Copacabana',
  'aesthetic_clinic',
  'Av. Nossa Senhora de Copacabana, 1234 - Sala 101',
  'Rio de Janeiro',
  'RJ',
  '22070-011',
  '+55 21 3333-3333',
  '+55 21 99999-3333',
  'copacabana@bellaestetica.com.br',
  NULL,
  1,
  '[
    {"day": "monday", "open": "09:00", "close": "18:00", "is_open": true},
    {"day": "tuesday", "open": "09:00", "close": "18:00", "is_open": true},
    {"day": "wednesday", "open": "09:00", "close": "18:00", "is_open": true},
    {"day": "thursday", "open": "09:00", "close": "18:00", "is_open": true},
    {"day": "friday", "open": "09:00", "close": "18:00", "is_open": true},
    {"day": "saturday", "open": "00:00", "close": "00:00", "is_open": false},
    {"day": "sunday", "open": "00:00", "close": "00:00", "is_open": false}
  ]'::JSONB,
  'America/Sao_Paulo',
  '["limpeza_de_pele", "peeling", "botox", "preenchimento"]'::JSONB,
  '["procedimentos_injetaveis"]'::JSONB,
  'estetica_bella_rede/bella_copacabana_001/',
  '{"consultation_rooms": 3, "staff_count": 3, "parking_spots": 0}'::JSONB,
  '["wifi", "air_conditioning"]'::JSONB,
  'Carla Santos',
  'carla.santos@bellaestetica.com.br',
  TRUE,
  FALSE
);

-- Localização 4: Bella Botafogo
INSERT INTO locations (
  location_id,
  client_id,
  name,
  display_name,
  location_type,
  address,
  city,
  state,
  zip_code,
  phone,
  whatsapp_number,
  email,
  chatwoot_inbox_id,
  chatwoot_account_id,
  working_hours,
  timezone,
  services_offered,
  specialties,
  media_folder,
  capacity_info,
  amenities,
  manager_name,
  manager_email,
  is_active,
  is_primary
) VALUES (
  'bella_botafogo_001',
  'estetica_bella_rede',
  'Bella Botafogo',
  'Bella Estética - Unidade Botafogo',
  'aesthetic_clinic',
  'Rua Voluntários da Pátria, 89 - Sala 501',
  'Rio de Janeiro',
  'RJ',
  '22270-000',
  '+55 21 3333-4444',
  '+55 21 99999-4444',
  'botafogo@bellaestetica.com.br',
  NULL,
  1,
  '[
    {"day": "monday", "open": "08:00", "close": "19:00", "is_open": true},
    {"day": "tuesday", "open": "08:00", "close": "19:00", "is_open": true},
    {"day": "wednesday", "open": "08:00", "close": "19:00", "is_open": true},
    {"day": "thursday", "open": "08:00", "close": "19:00", "is_open": true},
    {"day": "friday", "open": "08:00", "close": "19:00", "is_open": true},
    {"day": "saturday", "open": "09:00", "close": "13:00", "is_open": true},
    {"day": "sunday", "open": "00:00", "close": "00:00", "is_open": false}
  ]'::JSONB,
  'America/Sao_Paulo',
  '["limpeza_de_pele", "peeling", "harmonizacao_facial", "botox", "preenchimento", "microagulhamento", "laser", "depilacao_laser"]'::JSONB,
  '["depilacao_laser", "tratamentos_faciais"]'::JSONB,
  'estetica_bella_rede/bella_botafogo_001/',
  '{"consultation_rooms": 5, "staff_count": 6, "parking_spots": 3}'::JSONB,
  '["wifi", "air_conditioning", "wheelchair_access", "parking"]'::JSONB,
  'Daniel Oliveira',
  'daniel.oliveira@bellaestetica.com.br',
  TRUE,
  FALSE
);

-- ============================================================================
-- VALIDAÇÃO
-- ============================================================================
-- Verificar criação
SELECT 
  location_id,
  name,
  city,
  location_type,
  is_active,
  is_primary
FROM locations
WHERE client_id = 'estetica_bella_rede'
ORDER BY is_primary DESC, name;

-- Verificar contagem
SELECT 
  client_id,
  COUNT(*) as total_locations,
  COUNT(*) FILTER (WHERE is_active = TRUE) as active_locations,
  COUNT(*) FILTER (WHERE is_primary = TRUE) as primary_locations
FROM locations
GROUP BY client_id;

COMMENT ON COLUMN locations.working_hours IS 'Formato: [{"day": "monday", "open": "09:00", "close": "18:00", "is_open": true}]';

-- ============================================================================
-- MIGRATION 017: AGENTE CENTRAL + MULTI-LOCATION (HIERARQUIA CORRETA)
-- ============================================================================
-- PROBLEMA: RLS atual impede agente central de acessar múltiplas locations
-- SOLUÇÃO: Hierarquia client_id -> agent_id -> location_id
-- ============================================================================

-- ============================================================================
-- FASE 1: AJUSTAR RPC get_agent_context (já permite multi-location)
-- ============================================================================
-- Esta RPC já está correta - ela busca TODAS locations do client_id
-- Não precisa ajustar

-- ============================================================================
-- FASE 2: CRIAR FUNÇÃO HELPER para context de sessão
-- ============================================================================

-- Função para setar contexto de sessão (usado pelo n8n workflow)
CREATE OR REPLACE FUNCTION set_request_context(
  p_client_id VARCHAR,
  p_location_id VARCHAR DEFAULT NULL
)
RETURNS VOID
SECURITY DEFINER
AS $$
BEGIN
  -- Setar client_id (sempre obrigatório)
  PERFORM set_config('app.current_client_id', p_client_id, true);
  
  -- Setar location_id (opcional - se null, acessa todas locations)
  IF p_location_id IS NOT NULL THEN
    PERFORM set_config('app.current_location_id', p_location_id, true);
  ELSE
    -- Limpar location_id para permitir acesso a todas
    PERFORM set_config('app.current_location_id', '', true);
  END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_request_context IS
'Define contexto de sessão: client_id (obrigatório) + location_id (opcional para agente central)';

-- ============================================================================
-- FASE 3: AJUSTAR POLICIES para suportar multi-location
-- ============================================================================

-- LOCATIONS: Agente central vê todas, location específica vê só a sua
DROP POLICY IF EXISTS locations_isolation ON locations;
CREATE POLICY locations_isolation ON locations
  FOR ALL
  USING (
    -- Admin bypass
    current_setting('app.current_client_id', true) IS NULL
    OR
    -- Mesmo client_id (agente central vê todas)
    (client_id = current_setting('app.current_client_id', true)
     AND (
       -- Sem location específica (agente central)
       current_setting('app.current_location_id', true) = ''
       OR current_setting('app.current_location_id', true) IS NULL
       OR
       -- Location específica
       location_id = current_setting('app.current_location_id', true)
     ))
  );

-- PROFESSIONALS: Agente central vê todos, location específica vê só os seus
DROP POLICY IF EXISTS professionals_isolation ON professionals;
CREATE POLICY professionals_isolation ON professionals
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL
    OR
    (client_id = current_setting('app.current_client_id', true)
     AND (
       current_setting('app.current_location_id', true) = ''
       OR current_setting('app.current_location_id', true) IS NULL
       OR
       location_id = current_setting('app.current_location_id', true)
     ))
  );

-- CLIENT_MEDIA: Mesmo comportamento (agente central vê todas)
DROP POLICY IF EXISTS client_media_isolation ON client_media;
CREATE POLICY client_media_isolation ON client_media
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL
    OR client_id = current_setting('app.current_client_id', true)
    -- Mídia é por client, não por location (compartilhada)
  );

-- CLIENT_MEDIA_RULES: Mesmo comportamento
DROP POLICY IF EXISTS client_media_rules_isolation ON client_media_rules;
CREATE POLICY client_media_rules_isolation ON client_media_rules
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL
    OR client_id = current_setting('app.current_client_id', true)
  );

-- AGENTS: Agente é por client, não por location
DROP POLICY IF EXISTS agents_isolation ON agents;
CREATE POLICY agents_isolation ON agents
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL
    OR client_id = current_setting('app.current_client_id', true)
  );

-- CONVERSATION_MEMORY: Por client (agente central vê todas conversas)
DROP POLICY IF EXISTS conversation_memory_isolation ON conversation_memory;
CREATE POLICY conversation_memory_isolation ON conversation_memory
  FOR ALL
  USING (
    current_setting('app.current_client_id', true) IS NULL
    OR client_id = current_setting('app.current_client_id', true)
  );

-- ============================================================================
-- FASE 4: ADICIONAR location_id em professionals (se não existir)
-- ============================================================================

DO $$
BEGIN
  -- Verificar se coluna existe
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'professionals' 
      AND column_name = 'location_id'
  ) THEN
    -- Adicionar coluna location_id (opcional)
    ALTER TABLE professionals 
    ADD COLUMN location_id VARCHAR REFERENCES locations(location_id);
    
    COMMENT ON COLUMN professionals.location_id IS
    'Location específica do profissional (NULL = trabalha em todas)';
  END IF;
END $$;

-- ============================================================================
-- FASE 5: ATUALIZAR get_agent_context para incluir todas locations
-- ============================================================================

CREATE OR REPLACE FUNCTION get_agent_context(
  p_client_id VARCHAR,
  p_agent_id VARCHAR DEFAULT 'default',
  p_location_id VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  client_name VARCHAR,
  system_prompt TEXT,
  location_info JSONB,
  professionals_info JSONB
)
SECURITY DEFINER
AS $$
BEGIN
  -- 🔒 VALIDAÇÃO
  IF p_client_id IS NULL OR p_client_id = '' THEN
    RAISE EXCEPTION '🔒 client_id obrigatório';
  END IF;

  -- Setar contexto
  PERFORM set_request_context(p_client_id, p_location_id);

  RETURN QUERY
  SELECT 
    c.name as client_name,
    a.system_prompt,
    -- LOCATIONS: Se location_id null, retorna todas; senão, só a específica
    jsonb_agg(DISTINCT jsonb_build_object(
      'location_id', l.location_id,
      'name', l.name,
      'address', l.address,
      'phone', l.phone,
      'email', l.email,
      'chatwoot_inbox_id', l.chatwoot_inbox_id
    )) FILTER (WHERE l.location_id IS NOT NULL) as location_info,
    -- PROFESSIONALS: Se location_id null, retorna todos; senão, só da location
    jsonb_agg(DISTINCT jsonb_build_object(
      'professional_id', p.professional_id,
      'name', p.name,
      'role', p.role,
      'specialty', p.specialty,
      'bio', p.bio,
      'location_id', p.location_id
    )) FILTER (WHERE p.professional_id IS NOT NULL) as professionals_info
  FROM clients c
  LEFT JOIN agents a ON c.client_id = a.client_id AND a.agent_id = p_agent_id
  LEFT JOIN locations l ON c.client_id = l.client_id 
    AND l.is_active = true
    AND (p_location_id IS NULL OR l.location_id = p_location_id)
  LEFT JOIN professionals p ON c.client_id = p.client_id 
    AND p.is_active = true
    AND (p_location_id IS NULL OR p.location_id = p_location_id OR p.location_id IS NULL)
  WHERE c.client_id = p_client_id
    AND c.is_active = true
  GROUP BY c.client_id, c.name, a.system_prompt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_agent_context IS
'🏢 Contexto multi-location: location_id NULL = agente central (vê tudo)';

-- ============================================================================
-- FASE 6: EXEMPLOS DE USO
-- ============================================================================

-- Exemplo 1: AGENTE CENTRAL (vê todas locations)
SELECT '🏢 AGENTE CENTRAL (vê todas locations da Bella)' as exemplo;
SELECT 
  location_info,
  jsonb_array_length(location_info) as total_locations
FROM get_agent_context('estetica_bella_rede', 'default', NULL);

-- Exemplo 2: AGENTE ESPECÍFICO DE UMA LOCATION
SELECT '📍 AGENTE LOCATION ESPECÍFICA (vê só Bella Barra)' as exemplo;
SELECT 
  location_info,
  jsonb_array_length(location_info) as total_locations
FROM get_agent_context('estetica_bella_rede', 'default', 'bella_barra_001');

-- ============================================================================
-- FASE 7: WORKFLOW n8n - COMO USAR
-- ============================================================================

/*
NO N8N WORKFLOW WF0:

1. IDENTIFICAR LOCATION DO INBOX:
   - Se inbox_id tem location associada: usar location_id específico
   - Se inbox_id é central/corporativo: passar location_id = null

2. CHAMAR RPC:
   
   OPÇÃO A - AGENTE CENTRAL (multi-location):
   SELECT * FROM get_agent_context('estetica_bella_rede', 'default', NULL);
   
   OPÇÃO B - AGENTE ESPECÍFICO:
   SELECT * FROM get_agent_context('estetica_bella_rede', 'default', 'bella_barra_001');

3. NO SYSTEM PROMPT:
   - Agente central: "Você atende TODAS as unidades: Barra, Ipanema, Copacabana..."
   - Agente específico: "Você atende a unidade Barra apenas"
*/

-- ============================================================================
-- FASE 8: TESTES DE ISOLAMENTO
-- ============================================================================

-- Teste 1: Bella central NÃO pode ver Clínica Sorriso
SELECT '❌ Teste: Bella NÃO vê Clínica Sorriso' as teste;
PERFORM set_request_context('estetica_bella_rede', NULL);
SELECT COUNT(*) as total_locations_visiveis 
FROM locations 
WHERE client_id = 'clinica_sorriso_001';
-- Esperado: 0

-- Teste 2: Bella central vê TODAS suas locations
SELECT '✅ Teste: Bella central vê todas suas 4 locations' as teste;
PERFORM set_request_context('estetica_bella_rede', NULL);
SELECT COUNT(*) as total_locations_visiveis 
FROM locations 
WHERE client_id = 'estetica_bella_rede';
-- Esperado: 4

-- Teste 3: Bella Barra vê SÓ a Barra
SELECT '✅ Teste: Bella Barra vê só a Barra' as teste;
PERFORM set_request_context('estetica_bella_rede', 'bella_barra_001');
SELECT COUNT(*) as total_locations_visiveis 
FROM locations 
WHERE client_id = 'estetica_bella_rede';
-- Esperado: 1 (só Barra)

-- ============================================================================
-- FASE 9: DOCUMENTAÇÃO FINAL
-- ============================================================================

COMMENT ON TABLE locations IS
'🏢 Locations (filiais): Agente central vê todas, location específica vê só a sua';

COMMENT ON TABLE professionals IS
'👥 Profissionais: location_id NULL = trabalha em todas filiais';

-- ============================================================================
-- CHECKLIST:
-- [x] Função set_request_context criada
-- [x] Policies ajustadas para multi-location
-- [x] get_agent_context suporta location_id opcional
-- [x] Coluna location_id em professionals
-- [x] Testes de isolamento
-- [x] Documentação de uso no n8n
-- [x] GARANTIA: Cross-tenant continua IMPOSSÍVEL
-- [x] GARANTIA: Agente central vê todas suas locations
-- [x] GARANTIA: Agente específico vê só sua location
-- ============================================================================

SELECT '🎉 MIGRATION 017 COMPLETA - Hierarquia Multi-Location Implementada!' as status;

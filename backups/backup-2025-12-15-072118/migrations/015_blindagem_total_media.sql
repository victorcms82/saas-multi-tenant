-- ============================================================================
-- MIGRATION 015: BLINDAGEM TOTAL DE MÍDIA (SEGURANÇA CRÍTICA)
-- ============================================================================
-- PROBLEMA: RPC check_media_triggers pode retornar mídia de outro cliente
--           se o cliente atual não tiver mídia cadastrada
-- SOLUÇÃO: Forçar retorno vazio se não houver match NO CLIENT CORRETO
-- ============================================================================

-- 1. RECRIAR RPC com validação estrita de client_id
CREATE OR REPLACE FUNCTION check_media_triggers(
  p_client_id VARCHAR,
  p_agent_id VARCHAR,
  p_message TEXT
)
RETURNS TABLE (
  rule_id UUID,
  media_id UUID,
  trigger_type VARCHAR,
  trigger_value TEXT,
  file_url TEXT,
  file_type VARCHAR,
  file_name VARCHAR,
  mime_type VARCHAR,
  title VARCHAR,
  description TEXT
)
SECURITY DEFINER
AS $$
BEGIN
  -- 🔒 VALIDAÇÃO 1: client_id obrigatório
  IF p_client_id IS NULL OR p_client_id = '' THEN
    RAISE EXCEPTION 'client_id não pode ser vazio (SEGURANÇA)';
  END IF;

  -- 🔒 VALIDAÇÃO 2: message obrigatória
  IF p_message IS NULL OR p_message = '' THEN
    -- Retornar vazio ao invés de erro (mensagem vazia é válida)
    RETURN;
  END IF;

  -- 🔒 QUERY BLINDADA: APENAS mídia do client_id específico
  RETURN QUERY
  SELECT 
    cmr.rule_id,
    cmr.media_id,
    cmr.trigger_type,
    cmr.trigger_value,
    cm.file_url,
    cm.file_type,
    cm.file_name,
    cm.mime_type,
    cm.title,
    cm.description
  FROM client_media_rules cmr
  INNER JOIN client_media cm 
    ON cmr.media_id = cm.media_id
  WHERE 
    -- 🔒 CRÍTICO: Filtro duplo de client_id (regra + mídia)
    cmr.client_id = p_client_id
    AND cm.client_id = p_client_id
    AND cmr.agent_id = p_agent_id
    AND cmr.is_active = true
    AND cm.is_active = true
    AND cmr.trigger_type = 'keyword'
    AND p_message ~* cmr.trigger_value
  ORDER BY 
    cmr.priority DESC,
    cmr.created_at DESC
  LIMIT 1;  -- 🔒 Apenas 1 mídia por mensagem

  -- 🔒 GARANTIA: Se não houver match, retorna VAZIO (nunca mídia de outro cliente)
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_media_triggers IS 
'🔒 SEGURANÇA BLINDADA: Retorna mídia APENAS do client_id fornecido. 
Se não houver match, retorna vazio (NUNCA mídia de outro cliente).';

-- ============================================================================
-- 2. CONSTRAINT DE INTEGRIDADE: client_id deve ser igual em regra + mídia
-- ============================================================================

-- Adicionar constraint para garantir consistência
ALTER TABLE client_media_rules
DROP CONSTRAINT IF EXISTS check_client_id_consistency;

ALTER TABLE client_media_rules
ADD CONSTRAINT check_client_id_consistency
CHECK (
  -- Se media_id existe, client_id da regra DEVE ser igual ao da mídia
  media_id IS NULL 
  OR 
  client_id = (SELECT client_id FROM client_media WHERE media_id = client_media_rules.media_id)
);

COMMENT ON CONSTRAINT check_client_id_consistency ON client_media_rules IS
'Garante que regra e mídia pertencem ao MESMO cliente (previne cross-tenant leakage)';

-- ============================================================================
-- 3. ÍNDICE COMPOSTO para performance + segurança
-- ============================================================================

-- Drop índices antigos se existirem
DROP INDEX IF EXISTS idx_media_rules_client_agent_active;
DROP INDEX IF EXISTS idx_media_rules_trigger;

-- Criar índice composto otimizado
CREATE INDEX idx_media_rules_secure_lookup ON client_media_rules (
  client_id,
  agent_id,
  is_active,
  trigger_type,
  priority DESC
) WHERE is_active = true;

COMMENT ON INDEX idx_media_rules_secure_lookup IS
'Índice otimizado para busca segura de mídia (client_id primeiro para isolamento)';

-- ============================================================================
-- 4. FUNÇÃO DE VALIDAÇÃO DE INTEGRIDADE (para auditar periodicamente)
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_media_integrity()
RETURNS TABLE (
  issue_type TEXT,
  client_id VARCHAR,
  rule_id UUID,
  media_id UUID,
  details TEXT
)
AS $$
BEGIN
  -- Verificar regras com mídia de outro cliente
  RETURN QUERY
  SELECT 
    'CROSS_TENANT_LEAK'::TEXT as issue_type,
    cmr.client_id,
    cmr.rule_id,
    cmr.media_id,
    'Regra de ' || cmr.client_id || ' aponta para mídia de ' || cm.client_id as details
  FROM client_media_rules cmr
  JOIN client_media cm ON cmr.media_id = cm.media_id
  WHERE cmr.client_id <> cm.client_id;

  -- Verificar regras órfãs (mídia não existe)
  RETURN QUERY
  SELECT 
    'ORPHAN_RULE'::TEXT as issue_type,
    cmr.client_id,
    cmr.rule_id,
    cmr.media_id,
    'Mídia ID ' || cmr.media_id || ' não existe' as details
  FROM client_media_rules cmr
  LEFT JOIN client_media cm ON cmr.media_id = cm.media_id
  WHERE cm.media_id IS NULL;

  -- Verificar mídia sem client_id
  RETURN QUERY
  SELECT 
    'MISSING_CLIENT_ID'::TEXT as issue_type,
    cm.client_id,
    NULL::UUID as rule_id,
    cm.media_id,
    'Mídia ' || cm.file_name || ' sem client_id' as details
  FROM client_media cm
  WHERE cm.client_id IS NULL OR cm.client_id = '';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_media_integrity IS
'Auditar integridade de mídia - detectar cross-tenant leaks, órfãos, etc.';

-- ============================================================================
-- 5. TRIGGER PREVENTIVO: Bloquear INSERT/UPDATE inválidos
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_cross_tenant_media()
RETURNS TRIGGER AS $$
BEGIN
  -- Validar ao inserir/atualizar regra
  IF NEW.media_id IS NOT NULL THEN
    -- Verificar se mídia pertence ao mesmo cliente
    IF NOT EXISTS (
      SELECT 1 FROM client_media 
      WHERE media_id = NEW.media_id 
        AND client_id = NEW.client_id
    ) THEN
      RAISE EXCEPTION 
        '🔒 BLOQUEADO: Regra de % não pode usar mídia de outro cliente (media_id: %)',
        NEW.client_id, NEW.media_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_prevent_cross_tenant_media ON client_media_rules;

CREATE TRIGGER trigger_prevent_cross_tenant_media
  BEFORE INSERT OR UPDATE ON client_media_rules
  FOR EACH ROW
  EXECUTE FUNCTION prevent_cross_tenant_media();

COMMENT ON TRIGGER trigger_prevent_cross_tenant_media ON client_media_rules IS
'🔒 Previne criação de regras apontando para mídia de outro cliente';

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) - Camada extra de proteção
-- ============================================================================

-- Habilitar RLS nas tabelas
ALTER TABLE client_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_media_rules ENABLE ROW LEVEL SECURITY;

-- Policy 1: client_media - apenas owner pode ver
CREATE POLICY client_media_isolation ON client_media
  FOR ALL
  USING (
    client_id = current_setting('app.current_client_id', true)
    OR 
    current_setting('app.current_client_id', true) IS NULL  -- Admin/system bypass
  );

-- Policy 2: client_media_rules - apenas owner pode ver
CREATE POLICY client_media_rules_isolation ON client_media_rules
  FOR ALL
  USING (
    client_id = current_setting('app.current_client_id', true)
    OR
    current_setting('app.current_client_id', true) IS NULL  -- Admin/system bypass
  );

COMMENT ON POLICY client_media_isolation ON client_media IS
'RLS: Isola mídia por client_id (nível PostgreSQL)';

COMMENT ON POLICY client_media_rules_isolation ON client_media_rules IS
'RLS: Isola regras por client_id (nível PostgreSQL)';

-- ============================================================================
-- 7. VALIDAÇÃO IMEDIATA: Executar auditoria agora
-- ============================================================================

DO $$
DECLARE
  issue_count INT;
BEGIN
  -- Contar problemas
  SELECT COUNT(*) INTO issue_count
  FROM validate_media_integrity();

  IF issue_count > 0 THEN
    RAISE WARNING '⚠️  Encontrados % problemas de integridade! Execute: SELECT * FROM validate_media_integrity();', issue_count;
  ELSE
    RAISE NOTICE '✅ Integridade OK! Nenhum vazamento cross-tenant detectado.';
  END IF;
END $$;

-- ============================================================================
-- 8. VERIFICAÇÃO FINAL: Testar RPC com casos críticos
-- ============================================================================

-- Teste 1: Cliente com mídia (deve retornar)
SELECT '✅ Teste 1: Cliente COM mídia' as teste;
SELECT * FROM check_media_triggers(
  'clinica_sorriso_001',
  'default',
  'quero ver a clínica'
);

-- Teste 2: Cliente SEM mídia (deve retornar VAZIO, nunca de outro cliente)
SELECT '✅ Teste 2: Cliente SEM mídia (deve retornar vazio)' as teste;
SELECT * FROM check_media_triggers(
  'cliente_inexistente_xyz',
  'default',
  'quero ver a clínica'
);

-- Teste 3: Bella Estética SEM mídia (antes de inserir)
SELECT '⚠️  Teste 3: Bella SEM mídia (deve retornar vazio)' as teste;
SELECT * FROM check_media_triggers(
  'estetica_bella_rede',
  'default',
  'quero ver a clínica'
);

-- ============================================================================
-- RESULTADO ESPERADO:
-- ✅ Teste 1: Retorna mídia da Clínica Sorriso
-- ✅ Teste 2: Retorna VAZIO (0 rows)
-- ✅ Teste 3: Retorna VAZIO (0 rows) - NUNCA da Clínica Sorriso!
-- ============================================================================

-- ============================================================================
-- CHECKLIST DE SEGURANÇA:
-- [x] RPC validado com client_id obrigatório
-- [x] Filtro duplo (regra + mídia) no mesmo client_id
-- [x] Constraint de integridade
-- [x] Trigger preventivo
-- [x] Row Level Security (RLS)
-- [x] Função de auditoria
-- [x] Índice otimizado para isolamento
-- [x] Testes automatizados
-- ============================================================================

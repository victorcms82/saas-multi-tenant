-- ============================================================================
-- SCRIPT DE VALIDAÇÃO COMPLETA PÓS-MIGRATIONS 001 e 002
-- Data: 06/11/2025
-- Descrição: Verifica integridade do sistema após todas as migrations
-- Uso: Execute após rodar migrations 001_CUSTOM e 002
-- ============================================================================

DO $$
DECLARE
  v_errors integer := 0;
  v_warnings integer := 0;
  v_count integer;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VALIDAÇÃO DE INTEGRIDADE DO SISTEMA';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  
  -- =========================================================================
  -- 1. VERIFICAR ESTRUTURA DE TABELAS
  -- =========================================================================
  
  RAISE NOTICE '1. Verificando estrutura de tabelas...';
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agents') THEN
    RAISE WARNING '  ❌ Tabela agents não existe!';
    v_errors := v_errors + 1;
  ELSE
    RAISE NOTICE '  ✅ Tabela agents existe';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agent_templates') THEN
    RAISE WARNING '  ❌ Tabela agent_templates não existe!';
    v_errors := v_errors + 1;
  ELSE
    RAISE NOTICE '  ✅ Tabela agent_templates existe';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'client_subscriptions') THEN
    RAISE WARNING '  ❌ Tabela client_subscriptions não existe!';
    v_errors := v_errors + 1;
  ELSE
    RAISE NOTICE '  ✅ Tabela client_subscriptions existe';
  END IF;
  
  RAISE NOTICE '';
  
  -- =========================================================================
  -- 2. VERIFICAR FOREIGN KEYS
  -- =========================================================================
  
  RAISE NOTICE '2. Verificando foreign keys...';
  
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_agents_template'
  ) THEN
    RAISE NOTICE '  ✅ FK agents → agent_templates existe';
  ELSE
    RAISE WARNING '  ⚠️  FK agents → agent_templates não encontrada';
    v_warnings := v_warnings + 1;
  END IF;
  
  SELECT COUNT(*) INTO v_count
  FROM information_schema.table_constraints 
  WHERE table_name = 'client_subscriptions' 
    AND constraint_type = 'FOREIGN KEY';
  
  IF v_count >= 2 THEN
    RAISE NOTICE '  ✅ FKs de client_subscriptions existem (% encontradas)', v_count;
  ELSE
    RAISE WARNING '  ⚠️  Apenas % FKs encontradas em client_subscriptions', v_count;
    v_warnings := v_warnings + 1;
  END IF;
  
  RAISE NOTICE '';
  
  -- =========================================================================
  -- 3. VERIFICAR DADOS
  -- =========================================================================
  
  RAISE NOTICE '3. Verificando integridade de dados...';
  
  -- Agentes órfãos
  SELECT COUNT(*) INTO v_count
  FROM agents a
  LEFT JOIN clients c ON a.client_id = c.client_id
  WHERE c.client_id IS NULL;
  
  IF v_count > 0 THEN
    RAISE WARNING '  ❌ % agentes órfãos (sem cliente válido)', v_count;
    v_errors := v_errors + 1;
  ELSE
    RAISE NOTICE '  ✅ Nenhum agente órfão';
  END IF;
  
  -- Agentes sem template_id
  SELECT COUNT(*) INTO v_count FROM agents WHERE template_id IS NULL;
  
  IF v_count > 0 THEN
    RAISE WARNING '  ⚠️  % agentes sem template_id', v_count;
    v_warnings := v_warnings + 1;
  ELSE
    RAISE NOTICE '  ✅ Todos os agentes têm template_id';
  END IF;
  
  -- template_id inválido
  SELECT COUNT(*) INTO v_count
  FROM agents a
  LEFT JOIN agent_templates t ON a.template_id = t.template_id
  WHERE a.template_id IS NOT NULL AND t.template_id IS NULL;
  
  IF v_count > 0 THEN
    RAISE WARNING '  ❌ % agentes com template_id inválido', v_count;
    v_errors := v_errors + 1;
  ELSE
    RAISE NOTICE '  ✅ Todos os template_id são válidos';
  END IF;
  
  -- Assinaturas órfãs
  SELECT COUNT(*) INTO v_count
  FROM client_subscriptions s
  LEFT JOIN agents a ON s.client_id = a.client_id AND s.agent_id = a.agent_id
  WHERE a.id IS NULL;
  
  IF v_count > 0 THEN
    RAISE WARNING '  ❌ % assinaturas órfãs', v_count;
    v_errors := v_errors + 1;
  ELSE
    RAISE NOTICE '  ✅ Todas as assinaturas têm agente correspondente';
  END IF;
  
  RAISE NOTICE '';
  
  -- =========================================================================
  -- 4. ESTATÍSTICAS
  -- =========================================================================
  
  RAISE NOTICE '4. Estatísticas do sistema:';
  
  SELECT COUNT(*) INTO v_count FROM clients;
  RAISE NOTICE '  📊 Clientes: %', v_count;
  
  SELECT COUNT(*) INTO v_count FROM agents WHERE is_active = true;
  RAISE NOTICE '  📊 Agentes ativos: %', v_count;
  
  SELECT COUNT(*) INTO v_count FROM agent_templates WHERE is_active = true;
  RAISE NOTICE '  📊 Templates disponíveis: %', v_count;
  
  SELECT COUNT(*) INTO v_count FROM client_subscriptions WHERE status = 'active';
  RAISE NOTICE '  📊 Assinaturas ativas: %', v_count;
  
  SELECT COALESCE(SUM(monthly_price), 0) INTO v_count FROM client_subscriptions WHERE status = 'active';
  RAISE NOTICE '  💰 MRR Total: R$ %', v_count;
  
  RAISE NOTICE '';
  
  -- =========================================================================
  -- 5. RESULTADO FINAL
  -- =========================================================================
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RESULTADO DA VALIDAÇÃO';
  RAISE NOTICE '========================================';
  RAISE NOTICE '❌ Erros críticos: %', v_errors;
  RAISE NOTICE '⚠️  Avisos: %', v_warnings;
  RAISE NOTICE '';
  
  IF v_errors = 0 AND v_warnings = 0 THEN
    RAISE NOTICE '✅✅✅ SISTEMA 100%% ÍNTEGRO! ✅✅✅';
  ELSIF v_errors = 0 THEN
    RAISE NOTICE '✅ Sistema funcional com % avisos menores', v_warnings;
  ELSE
    RAISE WARNING '❌ Sistema com % erros críticos - REVISAR!', v_errors;
  END IF;
  
  RAISE NOTICE '========================================';
  
END $$;

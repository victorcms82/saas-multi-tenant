-- ============================================================================
-- GERENCIAMENTO DE CONFIGURAÇÕES DE MEMÓRIA
-- ============================================================================
-- Use estes comandos para configurar a memória por cliente/agente
-- ============================================================================

-- ============================================================================
-- 1. VISUALIZAR CONFIGURAÇÕES ATUAIS
-- ============================================================================

-- Ver todas as configurações
SELECT 
    c.client_name,
    mc.agent_id,
    mc.memory_limit,
    mc.memory_hours_back,
    mc.memory_enabled,
    mc.updated_at
FROM memory_config mc
JOIN clients c ON c.client_id = mc.client_id
ORDER BY c.client_name, mc.agent_id;

-- Ver configuração de um cliente específico
SELECT * FROM get_memory_config('estetica_bella_rede', 'default');

-- ============================================================================
-- 2. CONFIGURAR MEMÓRIA PARA UM CLIENTE
-- ============================================================================

-- Bella Estética - Atendimento personalizado (memória longa)
INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
VALUES ('estetica_bella_rede', 'default', 100, 72, true)
ON CONFLICT (client_id, agent_id) 
DO UPDATE SET 
  memory_limit = 100,
  memory_hours_back = 72,
  memory_enabled = true,
  updated_at = NOW();

-- Clínica Sorriso - Atendimento médio
INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
VALUES ('clinica_sorriso_001', 'default', 50, 24, true)
ON CONFLICT (client_id, agent_id) 
DO UPDATE SET 
  memory_limit = 50,
  memory_hours_back = 24,
  memory_enabled = true,
  updated_at = NOW();

-- ============================================================================
-- 3. CONFIGURAÇÕES PRÉ-DEFINIDAS POR TIPO DE NEGÓCIO
-- ============================================================================

-- Tipo 1: Atendimento Rápido (fast food, delivery, varejo)
-- Memória curta, conversas objetivas
UPDATE memory_config 
SET 
    memory_limit = 20,
    memory_hours_back = 3,
    memory_enabled = true,
    updated_at = NOW()
WHERE client_id = 'SEU_CLIENT_ID_AQUI';

-- Tipo 2: Atendimento Médio (ecommerce, suporte técnico, serviços)
-- Memória de 1 dia, contexto moderado
UPDATE memory_config 
SET 
    memory_limit = 50,
    memory_hours_back = 24,
    memory_enabled = true,
    updated_at = NOW()
WHERE client_id = 'SEU_CLIENT_ID_AQUI';

-- Tipo 3: Atendimento Complexo (healthcare, legal, financeiro)
-- Memória de 1 semana, contexto detalhado
UPDATE memory_config 
SET 
    memory_limit = 100,
    memory_hours_back = 168,
    memory_enabled = true,
    updated_at = NOW()
WHERE client_id = 'SEU_CLIENT_ID_AQUI';

-- Tipo 4: Relacionamento Longo Prazo (CRM, consultoria, educação)
-- Memória de 1 mês, contexto completo
UPDATE memory_config 
SET 
    memory_limit = 200,
    memory_hours_back = 720,
    memory_enabled = true,
    updated_at = NOW()
WHERE client_id = 'SEU_CLIENT_ID_AQUI';

-- ============================================================================
-- 4. DESABILITAR MEMÓRIA (AGENTE SEM CONTEXTO)
-- ============================================================================

-- Desabilitar memória para um cliente específico
UPDATE memory_config 
SET 
    memory_enabled = false,
    updated_at = NOW()
WHERE client_id = 'estetica_bella_rede' AND agent_id = 'default';

-- ============================================================================
-- 5. RESETAR PARA CONFIGURAÇÃO PADRÃO
-- ============================================================================

UPDATE memory_config 
SET 
    memory_limit = 50,
    memory_hours_back = 24,
    memory_enabled = true,
    updated_at = NOW()
WHERE client_id = 'estetica_bella_rede' AND agent_id = 'default';

-- ============================================================================
-- 6. CONFIGURAR DIFERENTES AGENTES DO MESMO CLIENTE
-- ============================================================================

-- Agente de vendas (memória longa)
INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
VALUES ('estetica_bella_rede', 'vendas', 100, 168, true)
ON CONFLICT (client_id, agent_id) 
DO UPDATE SET 
  memory_limit = 100,
  memory_hours_back = 168,
  updated_at = NOW();

-- Agente de suporte (memória curta)
INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
VALUES ('estetica_bella_rede', 'suporte', 30, 12, true)
ON CONFLICT (client_id, agent_id) 
DO UPDATE SET 
  memory_limit = 30,
  memory_hours_back = 12,
  updated_at = NOW();

-- ============================================================================
-- 7. APLICAR CONFIGURAÇÃO EM LOTE PARA TODOS OS CLIENTES
-- ============================================================================

-- Aplicar configuração padrão para todos os clientes
INSERT INTO memory_config (client_id, agent_id, memory_limit, memory_hours_back, memory_enabled)
SELECT 
    client_id,
    'default',
    50,
    24,
    true
FROM clients
ON CONFLICT (client_id, agent_id) DO NOTHING;

-- ============================================================================
-- 8. AUDITORIA E MONITORAMENTO
-- ============================================================================

-- Ver clientes SEM configuração de memória
SELECT c.client_id, c.client_name
FROM clients c
LEFT JOIN memory_config mc ON c.client_id = mc.client_id AND mc.agent_id = 'default'
WHERE mc.id IS NULL;

-- Ver clientes com memória desabilitada
SELECT c.client_name, mc.agent_id, mc.updated_at
FROM memory_config mc
JOIN clients c ON c.client_id = mc.client_id
WHERE mc.memory_enabled = false;

-- Ver clientes com configurações personalizadas (não padrão)
SELECT 
    c.client_name,
    mc.agent_id,
    mc.memory_limit,
    mc.memory_hours_back,
    mc.memory_enabled
FROM memory_config mc
JOIN clients c ON c.client_id = mc.client_id
WHERE mc.memory_limit != 50 OR mc.memory_hours_back != 24;

-- ============================================================================
-- 9. LIMPEZA E MANUTENÇÃO
-- ============================================================================

-- Remover configurações de clientes que não existem mais
DELETE FROM memory_config
WHERE client_id NOT IN (SELECT client_id FROM clients);

-- ============================================================================
-- REFERÊNCIA RÁPIDA:
-- ============================================================================
-- memory_limit         → Quantidade máxima de mensagens (10-200)
-- memory_hours_back    → Janela de tempo em horas (1-720)
-- memory_enabled       → true/false (habilitar/desabilitar)
--
-- Recomendações:
-- - Conversas curtas:  limit=20,  hours=3
-- - Conversas médias:  limit=50,  hours=24
-- - Conversas longas:  limit=100, hours=168
-- - Relacionamento:    limit=200, hours=720
-- ============================================================================

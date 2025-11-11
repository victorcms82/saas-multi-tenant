-- ============================================================================
-- FIX URGENTE: Corrigir encoding do system_prompt e adicionar location
-- ============================================================================

-- 1. CORRIGIR ENCODING DO SYSTEM_PROMPT (Bella Estetica)
UPDATE agents
SET system_prompt = 'Voce e um assistente de uma rede de clinicas de estetica chamada Bella Estetica. Ajude os clientes com informacoes sobre tratamentos, agendamentos e duvidas gerais sobre estetica.

Voce tem acesso as seguintes informacoes:
- Lista de profissionais da unidade
- Tratamentos disponiveis
- Horarios de atendimento
- Localizacao das unidades

Sempre seja educado, profissional e prestativo. Se nao souber algo, diga que vai verificar e retornara em breve.'
WHERE client_id = 'estetica_bella_rede' 
  AND agent_id = 'default';

-- 2. INSERIR LOCATION PARA CLINICA SORRISO (inbox_id=1)
INSERT INTO locations (
  location_id,
  client_id,
  name,
  address,
  phone,
  email,
  chatwoot_inbox_id,
  is_active,
  created_at,
  updated_at
)
VALUES (
  'sorriso_matriz_001',
  'clinica_sorriso_001',
  'Clinica Sorriso Matriz',
  'Av. Principal, 123 - Centro',
  '+55 21 98765-4321',
  'contato@clinicasorriso.com.br',
  1,  -- inbox_id
  true,
  NOW(),
  NOW()
)
ON CONFLICT (location_id) DO UPDATE
SET chatwoot_inbox_id = 1,
    client_id = 'clinica_sorriso_001',
    is_active = true;

-- 3. CORRIGIR SYSTEM_PROMPT DA CLINICA SORRISO TAMBEM (se tiver encoding errado)
UPDATE agents
SET system_prompt = 'Voce e a assistente virtual da Clinica Sorriso, especializada em odontologia de excelencia.

Sua funcao e ajudar os pacientes com:
- Informacoes sobre tratamentos dentarios
- Agendamento de consultas
- Duvidas sobre procedimentos
- Localizacao e horarios da clinica

Nossa equipe e composta por dentistas altamente qualificados, dedicados a proporcionar o melhor atendimento.

Sempre seja cordial, profissional e transmita confianca. Se nao souber responder algo, informe que ira verificar com a equipe.'
WHERE client_id = 'clinica_sorriso_001' 
  AND agent_id = 'default';

-- 4. VERIFICAR RESULTADOS
SELECT 
  'AGENTS' as tabela,
  client_id,
  agent_id,
  LEFT(system_prompt, 50) as prompt_preview,
  CASE 
    WHEN system_prompt LIKE '%Ã%' THEN '❌ ENCODING ERRADO'
    ELSE '✅ OK'
  END as status
FROM agents
WHERE client_id IN ('estetica_bella_rede', 'clinica_sorriso_001')

UNION ALL

SELECT 
  'LOCATIONS' as tabela,
  client_id,
  location_id as agent_id,
  name as prompt_preview,
  CASE 
    WHEN chatwoot_inbox_id IS NULL THEN '⚠️ SEM INBOX'
    ELSE '✅ INBOX: ' || chatwoot_inbox_id::TEXT
  END as status
FROM locations
WHERE client_id IN ('estetica_bella_rede', 'clinica_sorriso_001')
ORDER BY tabela, client_id;

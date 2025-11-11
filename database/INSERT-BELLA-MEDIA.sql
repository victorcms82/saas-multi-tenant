-- ============================================================================
-- INSERIR MÍDIA E REGRAS PARA BELLA ESTÉTICA
-- ============================================================================
-- PROBLEMA IDENTIFICADO: Bella Estética não tem imagens cadastradas!
-- Isso faz o bot enviar imagens da Clínica Sorriso por engano.
-- ============================================================================

-- PASSO 1: Inserir arquivos de mídia da Bella Estética
INSERT INTO client_media (
  client_id, 
  agent_id, 
  file_name, 
  file_type, 
  file_url, 
  title, 
  description, 
  tags, 
  category,
  is_active
)
VALUES 
  -- Imagem 1: Recepção da Bella Estética
  (
    'estetica_bella_rede',
    'default',
    'bella-recepcao-barra.jpg',
    'image',
    'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/estetica_bella_rede/bella-recepcao-barra.jpg',
    'Recepção Bella Barra',
    'Recepção moderna da unidade Bella Barra com ambiente acolhedor',
    ARRAY['recepcao', 'ambiente', 'clinica', 'bella', 'barra'],
    'facilities',
    true
  ),
  
  -- Imagem 2: Sala de Tratamento
  (
    'estetica_bella_rede',
    'default',
    'bella-sala-tratamento.jpg',
    'image',
    'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/estetica_bella_rede/bella-sala-tratamento.jpg',
    'Sala de Tratamento',
    'Sala de tratamento com equipamentos modernos de estética avançada',
    ARRAY['sala', 'tratamento', 'equipamentos', 'estetica'],
    'facilities',
    true
  ),
  
  -- Imagem 3: Equipe Bella Estética
  (
    'estetica_bella_rede',
    'default',
    'bella-equipe-completa.jpg',
    'image',
    'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/estetica_bella_rede/bella-equipe-completa.jpg',
    'Equipe Bella Estética',
    'Equipe completa de profissionais especializados em estética',
    ARRAY['equipe', 'time', 'profissionais', 'especialistas'],
    'team',
    true
  ),
  
  -- Documento 1: Tabela de Preços
  (
    'estetica_bella_rede',
    'default',
    'bella-tabela-servicos.pdf',
    'document',
    'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/estetica_bella_rede/bella-tabela-servicos.pdf',
    'Tabela de Serviços e Preços',
    'Lista completa de tratamentos estéticos e valores',
    ARRAY['servicos', 'precos', 'tratamentos', 'valores', 'tabela'],
    'services',
    true
  ),
  
  -- Imagem 4: Antes e Depois (Exemplo)
  (
    'estetica_bella_rede',
    'default',
    'bella-resultados-harmonizacao.jpg',
    'image',
    'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/estetica_bella_rede/bella-resultados-harmonizacao.jpg',
    'Resultados de Harmonização Facial',
    'Exemplos de resultados de procedimentos de harmonização facial',
    ARRAY['resultados', 'antes-depois', 'harmonizacao', 'facial'],
    'results',
    true
  )
ON CONFLICT (client_id, agent_id, file_name) DO UPDATE
SET 
  file_url = EXCLUDED.file_url,
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  tags = EXCLUDED.tags,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- PASSO 2: Criar regras de envio automático para Bella Estética
INSERT INTO client_media_rules (
  client_id,
  agent_id,
  media_id,
  trigger_type,
  trigger_value,
  priority,
  is_active
)
VALUES
  -- Regra 1: Quando perguntar sobre ambiente/localização
  (
    'estetica_bella_rede',
    'default',
    (SELECT media_id FROM client_media 
     WHERE client_id = 'estetica_bella_rede' 
       AND file_name = 'bella-recepcao-barra.jpg' 
     LIMIT 1),
    'keyword',
    'ambiente|localização|endereço|clinica|onde fica|como chegar|recepcao',
    10,
    true
  ),
  
  -- Regra 2: Quando perguntar sobre equipe/profissionais
  (
    'estetica_bella_rede',
    'default',
    (SELECT media_id FROM client_media 
     WHERE client_id = 'estetica_bella_rede' 
       AND file_name = 'bella-equipe-completa.jpg' 
     LIMIT 1),
    'keyword',
    'equipe|profissionais|especialistas|quem atende|profissional|dermatologista',
    10,
    true
  ),
  
  -- Regra 3: Quando perguntar sobre preços/serviços
  (
    'estetica_bella_rede',
    'default',
    (SELECT media_id FROM client_media 
     WHERE client_id = 'estetica_bella_rede' 
       AND file_name = 'bella-tabela-servicos.pdf' 
     LIMIT 1),
    'keyword',
    'preço|valor|quanto custa|serviços|tratamentos|procedimentos|tabela',
    10,
    true
  ),
  
  -- Regra 4: Quando perguntar sobre resultados
  (
    'estetica_bella_rede',
    'default',
    (SELECT media_id FROM client_media 
     WHERE client_id = 'estetica_bella_rede' 
       AND file_name = 'bella-resultados-harmonizacao.jpg' 
     LIMIT 1),
    'keyword',
    'resultados|antes e depois|como fica|exemplos|fotos de resultado',
    8,
    true
  )
ON CONFLICT (rule_id) DO UPDATE
SET 
  trigger_value = EXCLUDED.trigger_value,
  priority = EXCLUDED.priority,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- VERIFICAÇÃO: Listar mídia cadastrada para Bella Estética
SELECT 
  '📊 MÍDIA CADASTRADA - BELLA ESTÉTICA' as info,
  client_id,
  file_name,
  file_type,
  category,
  title,
  is_active
FROM client_media
WHERE client_id = 'estetica_bella_rede'
ORDER BY category, file_name;

-- VERIFICAÇÃO: Listar regras de envio para Bella Estética
SELECT 
  '📋 REGRAS DE ENVIO - BELLA ESTÉTICA' as info,
  cmr.rule_id,
  cm.file_name,
  cmr.trigger_type,
  cmr.trigger_value,
  cmr.priority,
  cmr.is_active
FROM client_media_rules cmr
JOIN client_media cm ON cmr.media_id = cm.media_id
WHERE cmr.client_id = 'estetica_bella_rede'
ORDER BY cmr.priority DESC, cm.file_name;

-- IMPORTANTE: Após executar este SQL, você precisa:
-- 1. Fazer upload dos arquivos reais no Supabase Storage
-- 2. Pasta: client-media/estetica_bella_rede/
-- 3. Arquivos:
--    - bella-recepcao-barra.jpg
--    - bella-sala-tratamento.jpg
--    - bella-equipe-completa.jpg
--    - bella-tabela-servicos.pdf
--    - bella-resultados-harmonizacao.jpg

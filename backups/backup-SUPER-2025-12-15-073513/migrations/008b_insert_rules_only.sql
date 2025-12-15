-- CRIAR TABELA + INSERIR REGRAS

-- Criar tabela
CREATE TABLE IF NOT EXISTS public.client_media_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id TEXT NOT NULL,
    agent_id TEXT NOT NULL DEFAULT 'default',
    media_id UUID NOT NULL REFERENCES public.client_media(id) ON DELETE CASCADE,
    trigger_type TEXT NOT NULL CHECK (trigger_type IN ('keyword', 'context', 'time', 'event')),
    trigger_value TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    times_triggered INTEGER DEFAULT 0,
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    notes TEXT,
    CONSTRAINT unique_trigger UNIQUE (client_id, agent_id, media_id, trigger_type, trigger_value)
);

-- Inserir regras de trigger
INSERT INTO public.client_media_rules (client_id, agent_id, media_id, trigger_type, trigger_value, priority, notes)
SELECT 
    'clinica_sorriso_001',
    'default',
    id,
    'keyword',
    CASE 
        WHEN title = 'Tabela de Preços' THEN 'preços|valores|quanto custa|tabela'
        WHEN title = 'Recepção do Consultório' THEN 'consultório|ambiente|estrutura|instalações'
        WHEN title = 'Equipe Clínica Sorriso' THEN 'equipe|dentistas|profissionais|time'
    END,
    1,
    'Trigger automático baseado em keywords'
FROM public.client_media
WHERE client_id = 'clinica_sorriso_001'
AND title IN ('Tabela de Preços', 'Recepção do Consultório', 'Equipe Clínica Sorriso');

-- Verificar resultado
SELECT 
    cmr.id,
    cmr.trigger_type,
    cmr.trigger_value,
    cm.title AS media_title,
    cm.file_name
FROM public.client_media_rules cmr
JOIN public.client_media cm ON cmr.media_id = cm.id
WHERE cmr.client_id = 'clinica_sorriso_001';

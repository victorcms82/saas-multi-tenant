-- Migration: Criar tabela client_media_rules
-- Descrição: Regras para disparar envio de mídia baseado em triggers (keywords, horário, contexto)
-- Data: 2025-11-10

CREATE TABLE IF NOT EXISTS public.client_media_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id TEXT NOT NULL,
    agent_id TEXT NOT NULL DEFAULT 'default',
    media_id UUID NOT NULL REFERENCES public.client_media(id) ON DELETE CASCADE,
    
    -- Tipo de trigger
    trigger_type TEXT NOT NULL CHECK (trigger_type IN ('keyword', 'context', 'time', 'event')),
    trigger_value TEXT NOT NULL, -- Palavra-chave, horário, contexto, etc
    
    -- Configurações
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0, -- Maior = mais importante
    
    -- Tracking
    times_triggered INTEGER DEFAULT 0,
    last_triggered_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    notes TEXT,
    
    -- Índices compostos
    CONSTRAINT unique_trigger UNIQUE (client_id, agent_id, media_id, trigger_type, trigger_value)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_media_rules_client ON public.client_media_rules(client_id, agent_id);
CREATE INDEX IF NOT EXISTS idx_media_rules_trigger ON public.client_media_rules(trigger_type, trigger_value);
CREATE INDEX IF NOT EXISTS idx_media_rules_active ON public.client_media_rules(is_active) WHERE is_active = true;

-- RLS (Row Level Security)
ALTER TABLE public.client_media_rules ENABLE ROW LEVEL SECURITY;

-- Policy: Permitir leitura pública (anon key)
CREATE POLICY "Allow public read access"
    ON public.client_media_rules
    FOR SELECT
    USING (true);

-- Policy: Permitir insert/update/delete com service_role
CREATE POLICY "Allow service role full access"
    ON public.client_media_rules
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_client_media_rules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.client_media_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_client_media_rules_updated_at();

-- Comentários
COMMENT ON TABLE public.client_media_rules IS 'Regras para disparar envio automático de mídias do acervo';
COMMENT ON COLUMN public.client_media_rules.trigger_type IS 'Tipo: keyword (palavra-chave), context (contexto), time (horário), event (evento)';
COMMENT ON COLUMN public.client_media_rules.trigger_value IS 'Valor do trigger: texto da keyword, regex, horário, etc';

-- Dados de exemplo
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

-- Verificar dados inseridos
SELECT 
    cmr.id,
    cmr.trigger_type,
    cmr.trigger_value,
    cm.title AS media_title,
    cm.file_name
FROM public.client_media_rules cmr
JOIN public.client_media cm ON cmr.media_id = cm.id
WHERE cmr.client_id = 'clinica_sorriso_001';

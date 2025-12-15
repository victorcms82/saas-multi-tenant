-- ATUALIZAR URLs COM IMAGENS PÚBLICAS DE TESTE
-- Unsplash oferece imagens gratuitas via URL direta

-- Foto de recepção de clínica
UPDATE public.client_media 
SET file_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&h=600&fit=crop'
WHERE title = 'Recepção do Consultório' 
AND client_id = 'clinica_sorriso_001';

-- Foto de equipe médica
UPDATE public.client_media 
SET file_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=800&h=600&fit=crop'
WHERE title = 'Equipe Clínica Sorriso' 
AND client_id = 'clinica_sorriso_001';

-- PDF de exemplo (dummy PDF válido)
UPDATE public.client_media 
SET file_url = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
WHERE title = 'Tabela de Preços' 
AND client_id = 'clinica_sorriso_001';

-- Verificar atualização
SELECT 
    title,
    file_url,
    file_type
FROM public.client_media
WHERE client_id = 'clinica_sorriso_001'
ORDER BY created_at;

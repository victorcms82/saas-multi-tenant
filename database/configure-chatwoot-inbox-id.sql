-- ============================================================================
-- Configurar chatwoot_inbox_id nas Locations
-- ============================================================================
-- Inbox ID descoberto: 3
-- Ação: Vincular as 4 locations da Rede Bella ao mesmo inbox
-- Justificativa: Por enquanto, todas as locations compartilham o mesmo inbox
--                No futuro, você pode criar inboxes separados no Chatwoot
-- ============================================================================

-- Atualizar todas as 4 locations com o inbox_id = 3
UPDATE locations 
SET chatwoot_inbox_id = 3
WHERE client_id = 'estetica_bella_rede';

-- ============================================================================
-- VALIDAÇÃO
-- ============================================================================

-- Verificar se todas as locations foram atualizadas
SELECT 
  location_id,
  name,
  city,
  chatwoot_inbox_id,
  is_active,
  is_primary
FROM locations 
WHERE client_id = 'estetica_bella_rede'
ORDER BY is_primary DESC, name;

-- Resultado esperado:
-- ┌─────────────────────┬────────────────────────┬──────────────┬────────────────────┬───────────┬────────────┐
-- │ location_id         │ name                   │ city         │ chatwoot_inbox_id  │ is_active │ is_primary │
-- ├─────────────────────┼────────────────────────┼──────────────┼────────────────────┼───────────┼────────────┤
-- │ bella_barra_001     │ Bella Estética - Barra │ Rio de Ja... │ 3                  │ true      │ true       │
-- │ bella_botafogo_001  │ Bella Estética - Bo... │ Rio de Ja... │ 3                  │ true      │ false      │
-- │ bella_copacabana... │ Bella Estética - Co... │ Rio de Ja... │ 3                  │ true      │ false      │
-- │ bella_ipanema_001   │ Bella Estética - Ip... │ Rio de Ja... │ 3                  │ true      │ false      │
-- └─────────────────────┴────────────────────────┴──────────────┴────────────────────┴───────────┴────────────┘

-- ============================================================================
-- TESTAR O RPC
-- ============================================================================

-- Agora você pode testar o RPC get_location_staff_summary com o inbox_id real
SELECT * FROM get_location_staff_summary(3);

-- Resultado esperado: 
-- Deve retornar dados da Bella Barra (location primária)
-- Com lista completa de 5 profissionais (4 especialistas + 1 recepcionista)

-- ============================================================================
-- OBSERVAÇÕES IMPORTANTES
-- ============================================================================

-- 🔴 CENÁRIO ATUAL (1 inbox para todas as locations):
--    - Todas as mensagens do WhatsApp caem no mesmo inbox
--    - O RPC sempre vai retornar a location PRIMARY (Bella Barra)
--    - Você precisa implementar lógica adicional para detectar a location correta
--      (ex: perguntar ao cliente "Qual unidade você prefere?")

-- 🟢 CENÁRIO IDEAL (1 inbox por location):
--    - Criar 4 inboxes no Chatwoot (1 para cada clínica)
--    - Cada inbox tem um número de WhatsApp diferente
--    - O RPC detecta automaticamente qual location pelo inbox_id
--    - Fluxo totalmente automático sem perguntas ao cliente

-- 📝 PARA CONFIGURAR MÚLTIPLOS INBOXES (futuro):
-- 1. No Chatwoot: Settings → Inboxes → Create New Inbox (WhatsApp)
-- 2. Anote os IDs de cada inbox criado
-- 3. Execute UPDATEs separados:
--    UPDATE locations SET chatwoot_inbox_id = 456 WHERE location_id = 'bella_ipanema_001';
--    UPDATE locations SET chatwoot_inbox_id = 789 WHERE location_id = 'bella_copacabana_001';
--    UPDATE locations SET chatwoot_inbox_id = 101 WHERE location_id = 'bella_botafogo_001';

-- ============================================================================
-- PRÓXIMO PASSO: TESTAR NO WORKFLOW
-- ============================================================================
-- 1. Abra o n8n
-- 2. Importe os nodes de NODES-MULTI-LOCATION-DETECTION.json
-- 3. Conecte os nodes conforme GUIA-INSTALACAO-MULTI-LOCATION.md
-- 4. Envie uma mensagem pelo Chatwoot
-- 5. Verifique se o RPC retorna dados da Bella Barra

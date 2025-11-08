# CLIENT MEDIA SETUP GUIDE

## 📸 Sistema de Mídia do Cliente

Este guia explica como configurar e usar o sistema de **acervo de mídia do cliente** no WF0.

---

## 🎯 Visão Geral

**O que é?**
Sistema que permite aos agentes de IA enviar **mídia pré-carregada do cliente** (fotos do consultório, documentos, cardápios, etc.) durante conversas, baseado em:
- **Keywords** na mensagem do usuário ("consultório" → envia foto do consultório)
- **Fase da conversa** (mensagem #5 → envia cardápio de serviços)
- **Decisão do LLM** (futuro: LLM decide quando enviar)

**O que NÃO é?**
❌ Não é geração de mídia por IA (DALL-E, TTS, PDF)
❌ Não é mídia que o usuário envia (isso já é processado no WF0)

---

## 🗂️ Arquitetura

### Tabelas do Sistema

```sql
client_media
├── id (UUID)
├── client_id (TEXT) → Identificação do cliente
├── agent_id (TEXT) → Agente específico (opcional)
├── file_name, file_type, file_url → Arquivo no Supabase Storage
├── title, description → Metadata
├── tags[] → Tags para busca: ['consultorio', 'equipe', 'recepcao']
├── category → Categorias: 'facilities', 'team', 'services', 'branding'
└── is_active → Ativo/Inativo

media_send_rules
├── id (UUID)
├── client_id, agent_id
├── rule_type → 'keyword_trigger', 'conversation_phase', 'llm_decision'
├── rule_name → Nome descritivo
├── keywords[] → ['consultório', 'onde fica', 'endereço']
├── message_number → Número da mensagem (para conversation_phase)
├── media_id → Referência para client_media
├── priority → Ordem de prioridade
├── send_once → Enviar apenas uma vez por conversa?
└── cooldown_hours → Cooldown entre envios

media_send_log
├── id (UUID)
├── conversation_id → ID da conversa no Chatwoot
├── rule_id, media_id → O que foi enviado
├── triggered_by → 'keyword', 'phase', 'llm_decision'
└── sent_at → Timestamp
```

---

## 🚀 Setup Inicial

### 1. Executar Migration 005

```bash
# Via Supabase SQL Editor (RECOMENDADO):
# 1. Acesse: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq
# 2. SQL Editor → New Query
# 3. Cole o conteúdo de: database/migrations/005_add_client_media_tables.sql
# 4. Run (Ctrl+Enter)

# Ou via PowerShell (se psql instalado):
cd database
.\run-migration-005.ps1
```

**Resultado esperado:**
- ✅ 3 tabelas criadas
- ✅ Function `search_client_media()` criada
- ✅ 3 mídias de exemplo inseridas
- ✅ 3 regras de exemplo inseridas

---

### 2. Configurar Supabase Storage

**2.1. Criar Bucket**
```sql
-- No Supabase SQL Editor
INSERT INTO storage.buckets (id, name, public)
VALUES ('client-media', 'client-media', true);
```

**2.2. Políticas de Acesso**
```sql
-- Leitura pública (para Chatwoot buscar arquivos)
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'client-media');

-- Upload autenticado (admin do cliente sobe arquivos)
CREATE POLICY "Authenticated upload access"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'client-media');

-- Delete autenticado
CREATE POLICY "Authenticated delete access"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'client-media');
```

**2.3. Estrutura de Pastas**
```
client-media/
├── clinica_sorriso_001/
│   ├── consultorio-recepcao.jpg
│   ├── equipe-completa.jpg
│   ├── cardapio-servicos.pdf
│   └── ...
├── pizzaria_bella_002/
│   ├── fachada.jpg
│   ├── menu-pizzas.pdf
│   └── ...
└── ...
```

---

### 3. Upload Manual de Mídia (Temporário)

**Via Supabase Dashboard:**
1. Storage → client-media bucket
2. Upload → Selecionar arquivos
3. Estrutura: `client-media/clinica_sorriso_001/foto.jpg`

**Via SQL (inserir registro após upload):**
```sql
INSERT INTO client_media (
  client_id,
  agent_id,
  file_name,
  file_type,
  file_url,
  title,
  description,
  tags,
  category
)
VALUES (
  'clinica_sorriso_001',
  'default',
  'consultorio-recepcao.jpg',
  'image',
  'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/consultorio-recepcao.jpg',
  'Recepção do Consultório',
  'Nossa recepção moderna e aconchegante',
  ARRAY['consultorio', 'recepcao', 'ambiente'],
  'facilities'
);
```

---

## 📋 Tipos de Regras

### 1. Keyword Trigger

**Envia mídia quando usuário menciona palavras-chave**

```sql
INSERT INTO media_send_rules (
  client_id,
  agent_id,
  rule_type,
  rule_name,
  keywords,
  media_id,
  priority,
  send_once
)
VALUES (
  'clinica_sorriso_001',
  'default',
  'keyword_trigger',
  'Enviar foto do consultório quando perguntar',
  ARRAY['consultório', 'consultorio', 'ambiente', 'onde fica', 'endereço'],
  (SELECT id FROM client_media WHERE file_name = 'consultorio-recepcao.jpg' LIMIT 1),
  1,
  false -- Pode enviar múltiplas vezes
);
```

**Como funciona:**
- Usuário: "Onde fica o consultório?"
- Sistema: Detecta keyword "consultório"
- Ação: Envia foto + resposta do LLM

---

### 2. Conversation Phase

**Envia mídia em um momento específico da conversa**

```sql
INSERT INTO media_send_rules (
  client_id,
  agent_id,
  rule_type,
  rule_name,
  message_number,
  media_id,
  priority,
  send_once
)
VALUES (
  'clinica_sorriso_001',
  'default',
  'conversation_phase',
  'Enviar cardápio na 5ª mensagem',
  5, -- Enviar na mensagem #5
  (SELECT id FROM client_media WHERE file_name = 'cardapio-servicos.pdf' LIMIT 1),
  3,
  true -- Enviar apenas uma vez por conversa
);
```

**Como funciona:**
- Conversa chega na 5ª mensagem
- Sistema: Conta mensagens via `media_send_log`
- Ação: Envia cardápio automaticamente

---

### 3. LLM Decision (Futuro)

**LLM decide dinamicamente se deve enviar mídia**

```sql
-- PLANEJADO - NÃO IMPLEMENTADO AINDA
INSERT INTO media_send_rules (
  client_id,
  agent_id,
  rule_type,
  rule_name,
  llm_prompt,
  media_id,
  priority
)
VALUES (
  'clinica_sorriso_001',
  'default',
  'llm_decision',
  'LLM decide sobre foto da equipe',
  'Se cliente perguntar sobre dentistas, profissionais ou equipe, envie esta foto',
  (SELECT id FROM client_media WHERE file_name = 'equipe-completa.jpg' LIMIT 1),
  2
);
```

---

## 🔧 Configurações Avançadas

### Send Once (Enviar Apenas Uma Vez)

```sql
-- Enviar apenas uma vez por conversa
send_once = true

-- Pode enviar múltiplas vezes
send_once = false
```

### Cooldown (Tempo Mínimo Entre Envios)

```sql
-- Cooldown de 24 horas
cooldown_hours = 24

-- Sem cooldown
cooldown_hours = NULL
```

### Prioridade

```sql
-- Menor número = maior prioridade
priority = 1  -- Alta prioridade
priority = 2  -- Média
priority = 3  -- Baixa

-- Sistema envia até 3 mídias por vez, ordenadas por prioridade
```

---

## 🧪 Testes

### Teste 1: Keyword Trigger

```bash
# 1. Enviar mensagem via Chatwoot:
"Onde fica o consultório?"

# 2. Verificar resposta:
# - Texto do LLM com endereço
# - Foto do consultório anexada

# 3. Verificar log:
SELECT * FROM media_send_log 
WHERE conversation_id = 'CONV_ID'
ORDER BY sent_at DESC;
```

### Teste 2: Conversation Phase

```bash
# 1. Enviar 5 mensagens na mesma conversa
# 2. Na 5ª mensagem, verificar:
# - Cardápio de serviços enviado automaticamente

# 3. Verificar contagem:
SELECT COUNT(*) 
FROM media_send_log 
WHERE conversation_id = 'CONV_ID';
```

### Teste 3: Send Once

```bash
# 1. Enviar "consultório" duas vezes
# 2. Se send_once = true:
#    → Foto enviada apenas na primeira vez
# 3. Se send_once = false:
#    → Foto enviada nas duas vezes
```

---

## 🛠️ Queries Úteis

### Buscar Mídia por Tags

```sql
SELECT * FROM search_client_media(
  p_client_id := 'clinica_sorriso_001',
  p_agent_id := 'default',
  p_tags := ARRAY['consultorio', 'recepcao']
);
```

### Ver Todas as Regras de um Cliente

```sql
SELECT 
  msr.rule_name,
  msr.rule_type,
  msr.keywords,
  msr.message_number,
  msr.priority,
  cm.file_name,
  cm.title
FROM media_send_rules msr
LEFT JOIN client_media cm ON msr.media_id = cm.id
WHERE msr.client_id = 'clinica_sorriso_001'
  AND msr.is_active = true
ORDER BY msr.priority;
```

### Histórico de Envios

```sql
SELECT 
  msl.sent_at,
  msl.triggered_by,
  msl.trigger_value,
  cm.file_name,
  msr.rule_name
FROM media_send_log msl
LEFT JOIN client_media cm ON msl.media_id = cm.id
LEFT JOIN media_send_rules msr ON msl.rule_id = msr.rule_id
WHERE msl.conversation_id = 'CONV_ID'
ORDER BY msl.sent_at DESC;
```

---

## 📊 Workflow no WF0

### Fluxo Completo

```
LLM Resposta
    ↓
Construir Resposta Final
    ↓
Verificar Regras de Mídia ← Query SQL (keywords + phase)
    ↓
Tem Mídia para Enviar? (IF)
    ├─ SIM → Preparar Mídias do Cliente
    │           ↓
    │        Registrar Log de Envio
    │           ↓
    └─ NÃO ──→ Atualizar Usage Tracking
                    ↓
                Enviar Resposta via Chatwoot (com/sem mídia)
```

### Nós Adicionados ao WF0

1. **Verificar Regras de Mídia** (Postgres)
   - Query SQL complexa
   - Busca keywords + conversation phase
   - Verifica send_once + cooldown
   - Retorna até 3 mídias

2. **Tem Mídia para Enviar?** (IF)
   - Condição: `length > 0`
   - SIM → Preparar mídias
   - NÃO → Pular para usage tracking

3. **Preparar Mídias do Cliente** (Function)
   - Monta array de attachments para Chatwoot
   - Prepara log entries para tracking

4. **Registrar Log de Envio** (Postgres)
   - INSERT em media_send_log
   - Permite controle de send_once e cooldown

---

## 🎯 Próximos Passos

### Fase 1: MVP (Atual)
- ✅ Schema criado (Migration 005)
- ✅ WF0 com busca e envio de mídia
- ⏳ Upload manual via Supabase Dashboard
- ⏳ Testes com clinica_sorriso_001

### Fase 2: Dashboard (4-6 semanas)
- Upload de mídia via interface
- CRUD de regras de envio
- Visualização de histórico
- Analytics de engajamento

### Fase 3: Automação
- LLM Decision (rule_type = 'llm_decision')
- Auto-tagging de mídia com Vision AI
- Recomendação de regras baseada em conversas

---

## 🔐 Segurança

### Políticas de Storage
- ✅ Leitura pública (Chatwoot precisa acessar URLs)
- ✅ Upload/Delete apenas autenticado
- ✅ Namespacing por client_id (isolamento)

### Validações
- ✅ Foreign keys (client_media → clients)
- ✅ Check constraints (file_type, rule_type)
- ✅ is_active para soft delete

---

## 📝 Exemplo Completo: Clínica Sorriso

### 1. Upload de Arquivos

```bash
# Via Supabase Dashboard Storage:
# client-media/clinica_sorriso_001/consultorio-recepcao.jpg
# client-media/clinica_sorriso_001/equipe-completa.jpg
# client-media/clinica_sorriso_001/cardapio-servicos.pdf
```

### 2. Inserir Mídia

```sql
INSERT INTO client_media (client_id, agent_id, file_name, file_type, file_url, title, description, tags, category)
VALUES
('clinica_sorriso_001', 'default', 'consultorio-recepcao.jpg', 'image', 
 'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/consultorio-recepcao.jpg',
 'Recepção', 'Nossa recepção moderna', ARRAY['consultorio', 'recepcao'], 'facilities'),
('clinica_sorriso_001', 'default', 'equipe-completa.jpg', 'image',
 'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/equipe-completa.jpg',
 'Equipe', 'Dentistas e recepcionistas', ARRAY['equipe', 'time'], 'team'),
('clinica_sorriso_001', 'default', 'cardapio-servicos.pdf', 'document',
 'https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/cardapio-servicos.pdf',
 'Cardápio', 'Todos os tratamentos', ARRAY['servicos', 'precos'], 'services');
```

### 3. Criar Regras

```sql
INSERT INTO media_send_rules (client_id, agent_id, rule_type, rule_name, keywords, media_id, priority)
VALUES
-- Keyword: consultório
('clinica_sorriso_001', 'default', 'keyword_trigger', 'Foto consultório',
 ARRAY['consultório', 'consultorio', 'onde fica', 'endereço'],
 (SELECT id FROM client_media WHERE file_name = 'consultorio-recepcao.jpg'), 1),

-- Keyword: equipe
('clinica_sorriso_001', 'default', 'keyword_trigger', 'Foto equipe',
 ARRAY['equipe', 'time', 'dentistas', 'profissionais'],
 (SELECT id FROM client_media WHERE file_name = 'equipe-completa.jpg'), 2),

-- Phase: mensagem 5
('clinica_sorriso_001', 'default', 'conversation_phase', 'Cardápio na msg 5',
 NULL,
 (SELECT id FROM client_media WHERE file_name = 'cardapio-servicos.pdf'), 3);
```

### 4. Testar

```
Usuário: "Oi, onde fica a clínica?"
Bot: [Texto] "Estamos na Rua das Flores, 123..."
     [Foto] consultorio-recepcao.jpg

Usuário: "Quem são os dentistas?"
Bot: [Texto] "Nossa equipe conta com..."
     [Foto] equipe-completa.jpg

Usuário: [5ª mensagem] "Quanto custa limpeza?"
Bot: [Texto] "A limpeza dental custa R$120..."
     [PDF] cardapio-servicos.pdf (enviado automaticamente)
```

---

**Versão:** 1.0
**Última atualização:** 2025-11-06
**Status:** ✅ Implementado, aguardando testes

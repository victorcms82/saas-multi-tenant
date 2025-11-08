# WF0 - SUMÁRIO DE MUDANÇAS

## 📋 Contexto da Mudança

**Problema Original:**
- WF0 incluía geração de mídia (DALL-E, TTS, PDF) como feature base
- Geração deveria ser **feature premium opcional**, não incluída no produto base
- Confusão entre "client media" (acervo pré-carregado) vs "generated media" (criado por IA)

**Decisão Estratégica:**
- **Prioridade:** WF0 vendável ASAP (MVP first)
- **Geração de mídia:** Movida para workflow separado (WF-MEDIA-GENERATION) como add-on premium
- **Client media:** Implementada no WF0 base (envio de fotos do consultório, documentos, etc.)
- **Dashboard:** Adiado para depois do WF0 estar vendendo

---

## ✅ O Que Foi Feito

### 1. Limpeza do WF0 (Remoção de Geração)

**Nós Removidos (6):**
- ❌ `check-media-generation` - Verificava se LLM pediu geração
- ❌ `generate-image` - DALL-E 3 integration
- ❌ `generate-document` - Puppeteer PDF generation
- ❌ `generate-audio` - OpenAI TTS
- ❌ `merge-generated-media` - Juntava mídia gerada
- ❌ `prepare-payload-with-media` - Preparava attachments de mídia gerada

**Nós Modificados (3):**
- 🔧 `build-response` - Removido detecção de tags `[GERAR_IMAGEM:...]`, `[GERAR_DOCUMENTO:...]`, `[GERAR_AUDIO:...]`
- 🔧 `update-usage` - Removido tracking de `images_generated`, `audios_generated`, `documents_generated`
- 🔧 `send-chatwoot` - Simplificado de "Resposta + Mídia" para apenas "Resposta" (mídia de cliente adicionada depois)

**Fluxo Simplificado:**
```
ANTES (36 nós):
build-response → check-media-generation? 
    ├─ SIM → generate-image → merge-media → prepare-payload → update-usage → send
    └─ NÃO → update-usage → send

DEPOIS (34 nós):
build-response → check-media-rules? 
    ├─ TEM → prepare-client-media → log-send → update-usage → send
    └─ NÃO → update-usage → send
```

**Arquivo Backup:**
- `WF0-Gestor-Universal-COMPLETE-BACKUP.json` (36 nós, com geração)

---

### 2. Implementação de Client Media

**Tabelas Criadas (Migration 005):**

```sql
client_media
├── Armazena acervo de mídia do cliente
├── Campos: file_url, file_type, tags[], category, title, description
└── Exemplo: fotos do consultório, cardápio de serviços, PDF institucional

media_send_rules
├── Regras de quando enviar mídia do acervo
├── Tipos: keyword_trigger, conversation_phase, llm_decision (futuro)
└── Controles: send_once, cooldown_hours, priority

media_send_log
├── Histórico de envios (para send_once e cooldown)
└── Campos: conversation_id, rule_id, triggered_by, sent_at
```

**Function Criada:**
```sql
search_client_media(client_id, agent_id, tags[], file_type, category)
-- Busca mídia do cliente por tags, tipo, categoria
```

**Dados de Exemplo (clinica_sorriso_001):**
- 📸 `consultorio-recepcao.jpg` - Foto da recepção
- 📸 `equipe-completa.jpg` - Foto da equipe
- 📄 `cardapio-servicos.pdf` - Cardápio de tratamentos

---

### 3. Novos Nós no WF0

**Nós Adicionados (4):**

1. **`check-media-rules`** (Postgres Query)
   - Busca regras ativas para o cliente/agente
   - Verifica keywords no `message_body`
   - Verifica fase da conversa (contagem de mensagens)
   - Aplica filtros: `send_once`, `cooldown_hours`
   - Retorna até 3 mídias ordenadas por prioridade

2. **`check-has-media`** (IF Statement)
   - Condição: `length > 0`
   - SIM → Preparar mídias do cliente
   - NÃO → Pular para usage tracking

3. **`prepare-client-media`** (Function)
   - Monta array `client_media_attachments` para Chatwoot
   - Prepara `media_log_entries` para tracking
   - Formato: `[{file_url, file_type, file_name, caption}]`

4. **`log-media-send`** (Postgres Insert)
   - Registra envio em `media_send_log`
   - Permite controle de `send_once` e `cooldown`
   - Tracking: rule_id, media_id, triggered_by, trigger_value

**Nó Atualizado:**
- `send-chatwoot` - Adicionado parâmetro `attachments: {{$json.client_media_attachments || []}}`

---

## 🔄 Tipos de Regras de Envio

### 1. Keyword Trigger
```sql
rule_type = 'keyword_trigger'
keywords = ['consultório', 'consultorio', 'onde fica', 'endereço']
```
**Funciona assim:**
- Usuário: "Onde fica o consultório?"
- Sistema: Detecta keyword "consultório"
- Ação: Envia foto do consultório + resposta do LLM

### 2. Conversation Phase
```sql
rule_type = 'conversation_phase'
message_number = 5
```
**Funciona assim:**
- Conversa atinge 5ª mensagem
- Sistema: Conta mensagens via `media_send_log`
- Ação: Envia cardápio automaticamente

### 3. LLM Decision (Futuro)
```sql
rule_type = 'llm_decision'
llm_prompt = 'Se cliente perguntar sobre dentistas, envie foto da equipe'
```
**Planejado, não implementado ainda**

---

## 📊 Comparação: Antes vs Depois

| Aspecto | ANTES | DEPOIS |
|---------|-------|--------|
| **Total de Nós** | 36 | 34 |
| **Geração de Mídia** | ✅ Incluída (DALL-E, TTS, PDF) | ❌ Removida (futuro workflow separado) |
| **Client Media** | ❌ Não implementado | ✅ Implementado |
| **Tabelas DB** | 3 (agents, templates, subscriptions) | 6 (+client_media, +media_send_rules, +media_send_log) |
| **Migrations** | 003 | 005 |
| **Complexidade** | Alta (geração + envio) | Média (apenas envio de acervo) |
| **Vendável?** | Não (feature premium no base) | ✅ Sim (MVP focado) |

---

## 🎯 Arquivos Criados/Modificados

### Criados
- ✅ `database/migrations/005_add_client_media_tables.sql` (430 linhas)
- ✅ `database/run-migration-005.ps1` (script PowerShell)
- ✅ `database/RUN_MIGRATION_005_MANUAL.md` (guia de execução manual)
- ✅ `workflows/CLIENT-MEDIA-SETUP.md` (guia completo de 400+ linhas)
- ✅ `workflows/WF0-Gestor-Universal-COMPLETE-BACKUP.json` (backup com geração)

### Modificados
- 🔧 `workflows/WF0-Gestor-Universal-COMPLETE.json`
  - Removido: 6 nós de geração
  - Adicionado: 4 nós de client media
  - Simplificado: build-response, update-usage, send-chatwoot
  - Conexões atualizadas

---

## 🚀 Próximos Passos (TODO)

### Imediato (1-2 dias)
1. ⏳ Executar Migration 005 no Supabase SQL Editor
2. ⏳ Configurar Supabase Storage bucket "client-media"
3. ⏳ Upload manual de 2-3 imagens de teste
4. ⏳ Importar WF0-COMPLETE.json no n8n
5. ⏳ Configurar credenciais (Supabase, OpenAI, Chatwoot)
6. ⏳ Teste end-to-end com clinica_sorriso_001

### Curto Prazo (1-2 semanas)
- Validar keyword triggers em produção
- Validar conversation phase rules
- Refinar queries SQL de busca de mídia
- Documentar casos de uso reais

### Médio Prazo (4-6 semanas)
- Dashboard Next.js para upload de mídia
- CRUD de regras de envio via UI
- Analytics de engajamento com mídia

### Longo Prazo (3+ meses)
- WF-MEDIA-GENERATION workflow separado (premium)
- LLM Decision implementation (rule_type = 'llm_decision')
- Auto-tagging de mídia com Vision AI
- Recomendação inteligente de regras

---

## 📝 Validação de Integridade

### Schema Validation
```sql
-- Verificar tabelas criadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('client_media', 'media_send_rules', 'media_send_log');

-- Verificar dados de exemplo
SELECT COUNT(*) FROM client_media; -- Esperado: 3
SELECT COUNT(*) FROM media_send_rules; -- Esperado: 3
```

### WF0 Validation
```javascript
// Nós que devem EXISTIR (34 total):
✅ webhook-chatwoot
✅ identify-client-agent
✅ filter-incoming
✅ build-response
✅ check-media-rules (NOVO)
✅ check-has-media (NOVO)
✅ prepare-client-media (NOVO)
✅ log-media-send (NOVO)
✅ update-usage
✅ send-chatwoot

// Nós que devem ter sido REMOVIDOS:
❌ check-media-generation
❌ generate-image
❌ generate-document
❌ generate-audio
❌ merge-generated-media
❌ prepare-payload-with-media
```

---

## 🔐 Segurança

### Storage Policies
```sql
-- Leitura pública (Chatwoot acessa URLs)
✅ Public read access on client-media bucket

-- Upload/Delete autenticado
✅ Authenticated upload/delete policies

-- Namespacing por client_id
✅ Estrutura: client-media/{client_id}/filename.ext
```

### Database Constraints
```sql
✅ Foreign keys: client_media → clients
✅ Check constraints: file_type IN ('image', 'video', 'document', 'audio')
✅ Check constraints: rule_type IN ('keyword_trigger', 'conversation_phase', 'llm_decision')
✅ Soft delete: is_active = false (não DELETE hard)
```

---

## 💡 Decisões de Design

### Por Que Remover Geração do WF0?
1. **Pricing:** Geração deve ser premium add-on, não feature base
2. **Complexidade:** WF0 ficou muito complexo (36 nós)
3. **MVP First:** Focar em vendável rápido, enhancements depois
4. **Arquitetura:** Workflow orchestration pattern - WF0 chama WF-MEDIA-GENERATION

### Por Que Implementar Client Media no WF0?
1. **Diferenciador:** Agentes podem enviar acervo do cliente (fotos, documentos)
2. **Simples:** Não requer IA generativa, apenas storage + rules
3. **Vendável:** Feature útil para clínicas, pizzarias, consultórios
4. **Base para Premium:** Fundação para futuras features (LLM decision, auto-tagging)

### Por Que 3 Tipos de Regras?
1. **Keyword Trigger:** Uso mais comum (80% dos casos)
2. **Conversation Phase:** Onboarding automático, envio de cardápios
3. **LLM Decision:** Futuro - flexibilidade total, mas complexo

---

## 📞 Exemplo de Uso: Clínica Sorriso

### Setup
```sql
-- 3 mídias no acervo
consultorio-recepcao.jpg (tags: ['consultorio', 'recepcao'])
equipe-completa.jpg (tags: ['equipe', 'time'])
cardapio-servicos.pdf (tags: ['servicos', 'precos'])

-- 3 regras
1. Keyword 'consultório' → envia foto consultório
2. Keyword 'equipe' → envia foto equipe  
3. Mensagem #5 → envia cardápio (automático)
```

### Conversa
```
[Msg 1]
Usuário: "Oi, onde fica a clínica?"
Bot: "Estamos na Rua das Flores, 123..."
     📸 consultorio-recepcao.jpg (triggered by keyword)

[Msg 2]
Usuário: "Quem são os dentistas?"
Bot: "Nossa equipe conta com 5 dentistas..."
     📸 equipe-completa.jpg (triggered by keyword)

[Msg 3]
Usuário: "Vocês atendem emergência?"
Bot: "Sim, atendemos emergências..."

[Msg 4]
Usuário: "Quanto custa limpeza?"
Bot: "A limpeza dental custa R$120..."

[Msg 5]
Usuário: "E clareamento?"
Bot: "O clareamento custa R$800..."
     📄 cardapio-servicos.pdf (triggered by phase = 5)
```

---

## 📚 Documentação

### Guias Criados
- ✅ `CLIENT-MEDIA-SETUP.md` - Setup completo (400+ linhas)
- ✅ `RUN_MIGRATION_005_MANUAL.md` - Execução da migration
- ⏳ `WF0-DOCUMENTATION.md` - Atualizar (remover geração, adicionar client media)

### Queries Úteis
```sql
-- Buscar mídia por tags
SELECT * FROM search_client_media(
  p_client_id := 'clinica_sorriso_001',
  p_tags := ARRAY['consultorio']
);

-- Ver regras ativas
SELECT rule_name, rule_type, keywords, message_number
FROM media_send_rules
WHERE client_id = 'clinica_sorriso_001' AND is_active = true;

-- Histórico de envios
SELECT sent_at, triggered_by, trigger_value
FROM media_send_log
WHERE conversation_id = 'CONV_123';
```

---

## ✅ Status Final

### Completo
- ✅ WF0 limpo (6 nós removidos)
- ✅ Client media implementado (4 nós adicionados)
- ✅ Migration 005 criada (3 tabelas + 1 function)
- ✅ Documentação completa (CLIENT-MEDIA-SETUP.md)
- ✅ Backup criado (WF0-COMPLETE-BACKUP.json)
- ✅ Scripts de execução (run-migration-005.ps1, manual guide)

### Pendente
- ⏳ Executar Migration 005 no Supabase
- ⏳ Configurar Storage bucket
- ⏳ Upload de imagens de teste
- ⏳ Teste end-to-end
- ⏳ Atualizar WF0-DOCUMENTATION.md

### Futuro
- ❌ WF-MEDIA-GENERATION workflow (premium)
- ❌ Dashboard Next.js
- ❌ LLM Decision implementation
- ❌ Auto-tagging com Vision AI

---

**Versão:** 1.0  
**Data:** 2025-11-06  
**Status:** 🔧 Implementado, aguardando testes  
**Próximo:** Executar Migration 005 + testes end-to-end

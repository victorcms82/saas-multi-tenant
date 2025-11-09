# Changelog - SaaS Multi-Tenant Platform

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

---

## [0.3.0] - 2025-11-09

### 🎉 Adicionado
- **Upload de Anexos PDF para Chatwoot**: Workflow agora suporta upload automático de arquivos PDF do Supabase Storage para conversas do Chatwoot
  - Node "Upload Anexo para Chatwoot" com HTTP Request multipart/form-data
  - Download binário do bucket `client-media` estruturado por `[client_id]/[filename]`
  - Compatível com PDF, DOCX, XLSX, PNG, JPG e outros formatos
  - Preservação de `client_media_attachments` através do fluxo completo

- **Multi-Tenancy Chatwoot Completo**: Sistema de isolamento por cliente implementado
  - Migration 007 adicionando colunas: `chatwoot_inbox_id`, `chatwoot_agent_id`, `chatwoot_agent_email`, `chatwoot_access_granted`, `chatwoot_setup_at`
  - Indexes criados: `idx_clients_chatwoot_inbox`, `idx_clients_chatwoot_agent`
  - Script `setup-chatwoot-client.ps1` para onboarding automatizado de clientes
  - Cada cliente tem Inbox dedicado e Agente isolado

- **Scripts de Automação**:
  - `send-real-message-chatwoot.ps1`: Enviar mensagens como cliente via API (testes)
  - `run-migration-007.ps1`: Executor de Migration 007 com fallback manual
  - `setup-chatwoot-client.ps1`: Setup automatizado de inbox + agent por cliente
  - `check-chatwoot-webhooks.ps1`: Verificar configuração de webhooks
  - `check-inbox-webhook.ps1`: Verificar webhooks específicos de inbox
  - `delete-chatwoot-webhooks.ps1`: Remover webhooks duplicados

### 🔧 Melhorado
- **Otimização do Workflow**: Removidos 1425 caracteres de console.log desnecessários
  - 5 logs removidos do "Identificar Cliente e Agente"
  - 3 logs removidos do "Preservar Contexto Após LLM"
  - 4 logs removidos do "Construir Resposta Final"
  - 1 log removido do "Preservar Dados Após Log"
  - 2 logs removidos do "Preservar Dados Após Usage Tracking"
  - Mantidos apenas console.error críticos para debugging

- **Loop Prevention**: Validado funcionamento do filtro "Filtrar Apenas Incoming"
  - Mensagens outgoing corretamente bloqueadas (previne loops infinitos)
  - Testado com webhook real e múltiplas execuções simultâneas

### 🐛 Corrigido
- **Webhook Loop**: Removida configuração duplicada de webhooks
  - Webhook estava em DOIS lugares: configurações globais + inbox específico
  - Causava 4+ execuções simultâneas por mensagem
  - Removidos ambos webhooks para evitar conflitos
  - Sistema agora processa cada mensagem uma única vez

### 📚 Documentação
- Atualizado `workflows/README.md` com:
  - Seção "Upload de Anexos PDF para Chatwoot" (nova feature)
  - Seção "Multi-Tenancy Chatwoot" (arquitetura isolada)
  - Workflow principal alterado para `WF0-Gestor-Universal-REORGANIZADO.json`
  - Status atualizado: Database 100% | Workflow 100% | WhatsApp 0%
  - Versão atualizada para 0.3.0

### 🧪 Testado
- ✅ Upload de PDF: `tabela-precos.pdf` enviado com sucesso via Chatwoot
- ✅ Multi-tenancy: Cliente `clinica_sorriso_001` com Inbox 2 e Agent 2 criados
- ✅ Real webhook: Mensagem "qual o preço da consulta?" testada via API
- ✅ Loop prevention: Outgoing messages corretamente filtradas
- ✅ Migration 007: Executada manualmente via Supabase SQL Editor

### 🏗️ Infraestrutura
- **Banco de Dados**: Migration 007 aplicada com sucesso
- **Chatwoot**: Inbox 2 e Agent 2 configurados para cliente teste
- **Git**: Commits `9e1bd9b` (attachment) e `9916e28` (cleanup) pushed para GitHub

### 📦 Arquivos Alterados
- `workflows/WF0-Gestor-Universal-REORGANIZADO.json`: Workflow otimizado em produção
- `workflows/WF0-Gestor-Universal-REORGANIZADO.json.backup`: Backup pré-limpeza
- `database/migrations/007_add_chatwoot_multi_tenancy.sql`: Nova migration
- `scripts/setup-chatwoot-client.ps1`: Script de onboarding
- `send-real-message-chatwoot.ps1`: Script de teste
- `run-migration-007.ps1`: Executor de migration
- `workflows/README.md`: Documentação atualizada
- `CHANGELOG.md`: Este arquivo

---

## [0.2.0] - 2025-11-06

### 📚 Documentação Base

**Data:** 06/11/2025  
**Autor:** GitHub Copilot + Victor Castro  
**Status:** 🟢 Documentação Atualizada

---

## 📊 O QUE FOI CRIADO/ATUALIZADO

### ✅ **1. GAPS.md (NOVO)**
**Caminho:** `/GAPS.md`

**Conteúdo completo:**
- ✅ Tabela `agents` (múltiplos agentes por cliente)
- ✅ Migração da tabela `clients` (remoção de campos específicos de agente)
- ✅ Chatwoot como Hub Central (arquitetura unificada)
- ✅ Processamento de Mídia INPUT (áudio, imagem, vídeo, documento)
- ✅ Processamento de Mídia OUTPUT (image_generate, tts_generate, envio)
- ✅ WhatsApp Múltiplos Providers (Evolution, Meta Cloud, Twilio)
- ✅ Multi-Tenancy Explícito (seção dedicada)
- ✅ Plano de Implementação (8 dias, 64h)

**Impacto:** 🔴 Crítico - Base para todas as implementações

---

### ✅ **2. DIAGRAMS.md (ATUALIZADO)**
**Caminho:** `/DIAGRAMS.md`

**Mudanças aplicadas:**

#### A) Visão Geral do Sistema
- ❌ **ANTES:** Múltiplos webhooks diretos
- ✅ **AGORA:** Chatwoot como hub central único

```
ANTES:
WhatsApp → /webhook/gestor-ia/whatsapp
Instagram → /webhook/gestor-ia/instagram

AGORA:
WhatsApp → Chatwoot → /webhook/chatwoot → n8n
Instagram → Chatwoot → /webhook/chatwoot → n8n
```

#### B) Arquitetura Multi-Tenant (NOVA SEÇÃO)
- ✅ Diagrama completo mostrando 3 clientes
- ✅ Cliente A: 3 agentes (SDR, Suporte, Cobrança)
- ✅ Cliente B: 1 agente (Recepção)
- ✅ Cliente C: 2 agentes (Vendas, SAC)
- ✅ Isolamento de dados por `client_id` + `agent_id`
- ✅ Roteamento inteligente por inbox

#### C) Fluxo Detalhado WF 0 (ATUALIZADO)
- ✅ Fase 1: Webhook Chatwoot (não mais múltiplos formatos)
- ✅ Processamento de Mídia Input adicionado:
  - 🎤 Áudio → Speech-to-Text
  - 🖼️ Imagem → Vision (Gemini)
  - 📄 Documento → OCR/Parse
  - 🎥 Vídeo → Gemini Video
- ✅ Load Agent Config (não mais Client Config)
- ✅ Suporte a `agent_id` em todas as etapas

---

## 🎯 PRINCIPAIS MUDANÇAS ARQUITETURAIS

### 1️⃣ **MÚLTIPLOS AGENTES POR CLIENTE**

**Antes:**
```sql
clients
├─ client_id: "acme-corp"
├─ system_prompt: "Você é..." (1 só!)
├─ tools_enabled: [...] (1 só!)
└─ (config única)
```

**Agora:**
```sql
clients (conta)
└─ client_id: "acme-corp"
    ├─ max_agents: 5
    └─ active_agents_count: 3

agents (múltiplos)
├─ acme-corp/sdr → system_prompt + tools próprias
├─ acme-corp/suporte → system_prompt + tools próprias
└─ acme-corp/cobranca → system_prompt + tools próprias
```

**Benefício:** Cliente pode ter múltiplos agentes especializados!

---

### 2️⃣ **CHATWOOT HUB CENTRAL**

**Antes:**
- 5+ webhooks diferentes
- Difícil manutenção
- Sem dashboard unificado

**Agora:**
- 1 webhook único `/webhook/chatwoot`
- Chatwoot gerencia todos os canais
- Dashboard unificado
- Handoff humano facilitado

**Benefício:** 70% menos código, melhor UX

---

### 3️⃣ **PROCESSAMENTO DE MÍDIA**

**Antes:**
- Apenas texto
- Mídia ignorada

**Agora:**

**Input:**
- ✅ Áudio → Transcrição automática
- ✅ Imagem → Análise via Gemini Vision
- ✅ Documento → Extração de texto
- ✅ Vídeo → Análise via Gemini

**Output:**
- ✅ Texto (já existia)
- ✅ Imagem (image_generate)
- ✅ Áudio (tts_generate)
- ✅ Documento (envio via Chatwoot)

**Benefício:** Agente multimodal completo!

---

### 4️⃣ **WHATSAPP PROVIDERS**

**Antes:**
- Apenas Evolution API

**Agora:**
- ✅ Evolution API (não-oficial, grátis)
- ✅ Meta Cloud API (oficial, $0.0036/conversa)
- ✅ Twilio (oficial BSP, $0.005/msg)

**Benefício:** Flexibilidade e compliance

---

## 📋 PRÓXIMOS PASSOS

### **Fase 1: Schema SQL (URGENTE)**

Criar migration SQL com:
```sql
-- 1. Criar tabela agents
CREATE TABLE public.agents (...);

-- 2. Migrar tabela clients
ALTER TABLE public.clients DROP COLUMN system_prompt, ...;

-- 3. Atualizar tabelas relacionadas
ALTER TABLE public.rag_documents ADD COLUMN agent_id text;
ALTER TABLE public.agent_executions ADD COLUMN agent_id text;
ALTER TABLE public.channels ADD COLUMN assigned_agent_id text;

-- 4. Migrar dados existentes
INSERT INTO agents (client_id, agent_id, system_prompt, ...)
SELECT client_id, 'default', system_prompt, ...
FROM clients;
```

---

### **Fase 2: Atualizar SUMARIO_EXECUTIVO.md**

Adicionar seções:
1. ✅ Seção 2.5: "Multi-Tenancy & Múltiplos Agentes"
2. ✅ Seção 3.X: Tabela `agents` no schema
3. ✅ Seção 9.X: "Processamento de Mídia Input"
4. ✅ Seção 9.Y: "Processamento de Mídia Output"
5. ✅ Seção 9.Z: "WhatsApp Providers"
6. ✅ Seção 9.W: "Chatwoot Hub Central Setup"

---

### **Fase 3: Atualizar Workflows**

**WF0 Part 1:**
- Aceitar apenas webhook Chatwoot
- Extrair `client_id` + `agent_id`
- Processar mídia input
- Load Agent Config

**WF0 Part 2:**
- Implementar `image_generate`
- Implementar `tts_generate`
- Suporte Gemini Vision/Video

**WF0 Part 3:**
- Enviar mídia via Chatwoot API
- Suporte a múltiplos providers WhatsApp

---

### **Fase 4: Setup Chatwoot**

- Configurar inboxes
- Conectar canais (WhatsApp, Instagram, Email)
- Custom attributes (client_id, agent_id)
- Webhook para n8n
- Testes end-to-end

---

## 🎯 VALIDAÇÃO

### ✅ **Checklist de Documentação**

- [x] GAPS.md criado com todas as correções
- [x] DIAGRAMS.md atualizado (Chatwoot hub + Multi-agent)
- [ ] SUMARIO_EXECUTIVO.md atualizar (próximo passo)
- [ ] workflows/README.md atualizar
- [ ] workflows/SETUP.md atualizar
- [ ] STATUS.md atualizar progresso

### ✅ **Cobertura de Features**

- [x] Múltiplos agentes por cliente
- [x] Chatwoot hub central
- [x] Processamento mídia input (áudio/imagem/doc/vídeo)
- [x] Processamento mídia output (imagem/áudio)
- [x] WhatsApp providers (Evolution/Meta/Twilio)
- [x] Multi-tenancy explícito
- [x] Dinamismo (tools/prompts/LLM por agente)

---

## 💡 DECISÕES ARQUITETURAIS

### 1. **Por que tabela `agents` separada?**

**Razão:** Permitir múltiplos agentes especializados por cliente.

**Exemplo Real:**
```
Acme Corp (cliente) precisa de:
- Agente SDR (vendas)
- Agente Suporte (tickets)
- Agente Cobrança (financeiro)

Cada um com:
- Personalidade diferente (system_prompt)
- Ferramentas diferentes (tools_enabled)
- Base de conhecimento diferente (rag_namespace)
- Rate limits diferentes
```

---

### 2. **Por que Chatwoot hub?**

**Razão:** Simplificação e melhor UX.

**Comparação:**
```
SEM Chatwoot:
- 5+ webhooks para manter
- 5+ adapters diferentes
- Sem dashboard para cliente
- Handoff humano complexo

COM Chatwoot:
- 1 webhook único
- 1 formato padronizado
- Dashboard bonito
- Handoff humano nativo
```

---

### 3. **Por que processar mídia?**

**Razão:** Agentes realmente inteligentes.

**Casos de Uso:**
```
Usuário: 🎤 [áudio "quero saber o preço"]
Agente: Transcreveu → Entendeu → Respondeu
        (vs ignorar o áudio)

Usuário: 📸 [foto do produto quebrado]
Agente: Analisou → Identificou problema → Abriu ticket
        (vs pedir descrição por texto)
```

---

## 📈 IMPACTO NO PROJETO

### **Antes das Correções:**
- ✅ Multi-tenancy básico (1 agente por cliente)
- ⚠️ Só texto
- ⚠️ Múltiplos webhooks
- ⚠️ Só Evolution API

**Limitação:** Cliente não pode ter múltiplos agentes especializados.

---

### **Depois das Correções:**
- ✅ Multi-tenancy avançado (N agentes por cliente)
- ✅ Multimodal (texto + áudio + imagem + vídeo + doc)
- ✅ Chatwoot hub (1 webhook, melhor UX)
- ✅ 3 WhatsApp providers (flexibilidade)

**Resultado:** Produto enterprise-ready, altamente escalável!

---

## 🚀 PRÓXIMA AÇÃO RECOMENDADA

**Prioridade 1:** Criar migration SQL
**Prioridade 2:** Atualizar SUMARIO_EXECUTIVO.md
**Prioridade 3:** Atualizar workflows

**Estimativa:** 3-4 dias para ter documentação 100% completa.

---

**Status Final:** 🟢 Documentação base atualizada  
**Próximo Marco:** Schema SQL + SUMARIO_EXECUTIVO.md completo

---

**Revisado por:** Victor Castro  
**Aprovação:** Pendente

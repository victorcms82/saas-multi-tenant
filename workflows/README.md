# Workflows n8n - Plataforma SaaS Multi-Tenant

## 📋 Visão Geral

Este diretório contém os workflows do n8n para a plataforma de agentes IA multi-tenant com suporte completo a **processamento de mídia** (áudio, imagem, vídeo, documentos) e **Chatwoot como hub central**.

---

## 🎯 Arquivos Principais

### 📦 Workflows

| Arquivo | Status | Descrição |
|---------|--------|-----------|
| `WF0-Gestor-Universal-REORGANIZADO.json` | ✅ **PRODUÇÃO** | Workflow otimizado com PDF + multi-tenancy |
| `WF0-Gestor-Universal-COMPLETE.json` | ⚠️ Anterior | Versão anterior (pré-otimização) |
| `WF0-Gestor-Universal.json` | ⚠️ Legado | Versão antiga (sem mídia) |
| `WF0-Gestor-Universal-V2-AGENTS.json` | ⚠️ Legado | Versão com multi-agente parcial |
| `WF0-Gestor-Universal-Part2-LLM.json` | ⚠️ Legado | Parte 2 antiga |
| `WF0-Gestor-Universal-Part3-Finalization.json` | ⚠️ Legado | Parte 3 antiga |

### 📚 Documentação

| Arquivo | Propósito |
|---------|-----------|
| `WF0-DOCUMENTATION.md` | 📖 Documentação técnica completa |
| `WF0-QUICK-START.md` | ⚡ Guia de instalação rápida (10 min) |
| `INTEGRATION-CHECKLIST.md` | ✅ Checklist de progresso |
| `.env.example` | ⚙️ Template de configuração |

---

## � INÍCIO RÁPIDO

### 1. Importar Workflow (2 min)

```bash
# No n8n UI
Workflows → Import from File → WF0-Gestor-Universal-REORGANIZADO.json
```

### 2. Configurar Credenciais (5 min)

Mínimo necessário:
- ✅ **Supabase Database** (PostgreSQL)
- ✅ **OpenAI API** (GPT-4o-mini/GPT-4o)
- ✅ **Chatwoot API** (hub central)

### 3. Configurar Webhook Chatwoot (2 min)

```
URL: https://seu-n8n.com/webhook/chatwoot-webhook
Event: message_created
```

### 4. Testar (1 min)

Enviar mensagem via Chatwoot e verificar resposta!

**📖 Guia completo**: Ver `WF0-QUICK-START.md`

---

## 🏗️ WF0 - Gestor Universal (REORGANIZADO)

**Workflow principal otimizado** em PRODUÇÃO com todas as funcionalidades.

### ✨ Funcionalidades

#### 0. **Upload de Anexos PDF para Chatwoot** 🆕
O agente pode fazer upload de arquivos PDF do Supabase Storage diretamente para o Chatwoot:
```
1. LLM gera resposta com nome do arquivo: "Aqui está a tabela de preços"
2. Workflow busca arquivo no bucket: [client_id]/tabela-precos.pdf
3. Download binário do Supabase Storage
4. Upload via Chatwoot API (multipart/form-data)
5. Arquivo anexado automaticamente à mensagem
```

**Fluxo técnico**:
- Node: "Upload Anexo para Chatwoot" (HTTP Request)
- Método: POST multipart/form-data
- Binary field: `attachment` (n8n Binary File)
- Payload: `{ content, message_type, private }`
- Resultado: Arquivo aparece na conversa do Chatwoot

**Compatível com**: PDF, DOCX, XLSX, PNG, JPG (qualquer tipo de arquivo)

**Requisitos**:
- `client_media_attachments` preservado no fluxo
- Supabase Storage bucket configurado: `client-media`
- Estrutura: `[client_id]/[filename]`

#### 1. **Hub Central - Chatwoot**
Todos os canais passam pelo Chatwoot:
- 📱 WhatsApp (Evolution API)
- 📧 Email
- 📸 Instagram DM
- 💬 Messenger
- ✈️ Telegram
- 🌐 Webchat

#### 2. **Processamento de Mídia**

**Áudio** → Transcrição automática (Google Speech-to-Text / Whisper)
```
Input: arquivo.mp3 (30s)
Output: "Olá, gostaria de agendar..."
Custo: $0.003 (0.5 min × $0.006/min)
```

**Imagem** → Análise com Vision AI (GPT-4V / Google Vision)
```
Input: foto.jpg
Output: "Foto de um produto branco, cilíndrico, com logo azul..."
Custo: $0.01/imagem
```

**Documentos** → Extração de texto (PDF/DOCX)
```
Input: contrato.pdf
Output: Texto completo extraído
Custo: $0 (processamento local)
```

**Vídeo** → Frames + transcrição de áudio
```
Input: video.mp4
Output: Frames-chave analisados + áudio transcrito
```

#### 3. **Multi-Tenancy Chatwoot** 🆕
Cada cliente tem **Inbox isolado** e **Agente dedicado**:
```sql
-- Tabela clients agora inclui:
chatwoot_inbox_id INTEGER       -- Inbox dedicado do cliente
chatwoot_agent_id INTEGER        -- Agente dedicado do cliente
chatwoot_agent_email TEXT        -- Email do agente
chatwoot_access_granted BOOLEAN  -- Acesso confirmado
chatwoot_setup_at TIMESTAMPTZ    -- Data de configuração
```

**Benefícios**:
- Isolamento total entre clientes (cada um vê apenas suas conversas)
- Agente dedicado com email do cliente
- Configuração via script: `setup-chatwoot-client.ps1`
- Onboarding automatizado

**Exemplo de uso**:
```powershell
.\scripts\setup-chatwoot-client.ps1 `
  -ClientId "clinica_sorriso_001" `
  -ClientName "Clínica Sorriso" `
  -ClientEmail "contato@clinicasorriso.com.br"

# Resultado:
# - Inbox ID 2 criado
# - Agent ID 2 criado
# - Database atualizado
# - Email de confirmação enviado
```

#### 4. **Multi-Agente**
- Identificação por `client_id` + `agent_id`
- Namespace RAG isolado: `{client_id}/{agent_id}`
- Configuração individual por agente

#### 5. **RAG (Retrieval-Augmented Generation)**
- Vector DB: Pinecone / Qdrant / Weaviate
- Namespace isolado por cliente/agente
- Top-K resultados mais relevantes

#### 6. **LLM + Function Calling**
- **Modelo principal**: GPT-4o-mini (70%) + GPT-4o (30%)
- **Tools disponíveis**:
  - `create_calendar_event`: Google Calendar
  - `update_sheet`: Google Sheets
  - `search_crm`: CRM integration

#### 7. **Usage Tracking Automático**
Atualiza `client_subscriptions` após cada interação:
```sql
total_messages += 1
transcription_minutes_used += audio_duration / 60
images_processed += image_count
```

#### 8. **Buffer & Agrupamento**
- Redis buffer de 5 segundos
- Agrupa mensagens enviadas rapidamente
- Previne múltiplas chamadas LLM desnecessárias

#### 9. **Geração de Mídia pelo Agente**
O agente pode **gerar e enviar** mídia automaticamente:

**Imagens** → DALL-E 3
```
LLM: "Claro! [GERAR_IMAGEM: logo moderno para clínica]"
     ↓
Workflow gera imagem → Upload Storage → Envia via Chatwoot
Custo: $0.04/imagem (1024x1024)
```

**Áudios** → OpenAI TTS
```
LLM: "[GERAR_AUDIO: Sua consulta foi confirmada para amanhã]"
     ↓
Workflow gera áudio → Upload Storage → Envia mensagem de voz
Custo: $0.015/1K caracteres
```

**Documentos** → Puppeteer/PDFKit
```
LLM: "[GERAR_DOCUMENTO: relatorio]"
     ↓
Workflow gera PDF → Upload Storage → Envia arquivo
Custo: $0 (processamento local)
```

#### 10. **Error Handling & Otimização** 🆕
### Arquitetura (36 nodes)tro "Filtrar Apenas Incoming" bloqueia mensagens outgoing
- Try/catch em todos os nodes críticos
- Retry logic com backoff exponencial
- Fallback para mensagem genérica

### Arquitetura (36 nodes)

```
Chatwoot Webhook
    ↓
Identificar Cliente/Agente (client_id + agent_id)
    ↓
Filtrar Incoming (ignorar outgoing)
    ↓
Buscar Dados do DB (agents + subscriptions)
    ↓
    ┌─── Tem Mídia? ───┐
    │                  │
    Sim               Não
    │                  │
    ↓                  ↓
[Processar Mídia]  [Texto Direto]
    │                  │
    ├─ Transcrever Áudio (Speech-to-Text)
    ├─ Analisar Imagem (Vision AI)
    └─ Extrair Documento (PDF/DOCX)
    │
    └─→ Construir Contexto Completo
            ↓
        Buffer Redis (5s)
            ↓
        Query RAG (namespace isolado)
            ↓
        LLM (GPT-4o-mini + function calling)
            ↓
        ┌─── Chamou Tool? ───┐
        │                    │
       Sim                  Não
        │                    │
        ↓                    ↓
    Executar Tools      [Resposta Direta]
    (Calendar/Sheets)        │
        │                    │
        └────────┬───────────┘
                 ↓
        Construir Resposta Final
                 ↓
        ┌─── Precisa Gerar Mídia? ───┐
        │                            │
       Sim                          Não
        │                            │
        ↓                            ↓
    [Gerar Mídia]              [Texto apenas]
        │
        ├─ DALL-E 3 (imagem)
        ├─ OpenAI TTS (áudio)
        └─ Puppeteer (PDF)
        │
        └─→ Preparar Payload com Mídia
                 ↓
        Atualizar Usage Tracking (DB)
                 ↓
        Enviar Resposta + Mídia via Chatwoot
```
        Atualizar Usage Tracking (DB)
                 ↓
        ┌─── Tem Anexos? ───┐
        │                   │
       Sim                 Não
        │                   │
        ↓                   ↓
    [Upload Anexo]    [Texto apenas]
        │
        ├─ Download do Supabase Storage
        ├─ Upload via Chatwoot API
        └─ Anexo na conversa
        │
        └─→ Enviar Resposta + Mídia/Anexo via Chatwoot
```📖 Documentação Detalhada

### Para Desenvolvedores

**`WF0-DOCUMENTATION.md`** - Documentação técnica completa:
- Arquitetura detalhada (diagramas)
- Cada componente explicado
- APIs e integrações
- Custos por operação
- Monitoramento e logs
- Troubleshooting
- Roadmap (Fases 2-4)

### Para Implementação

**`WF0-QUICK-START.md`** - Guia de instalação em 10 minutos:
- Setup passo a passo
- Configuração de credenciais
- Testes básicos
- Validação da instalação
- Troubleshooting comum

### Para Gestão

**`INTEGRATION-CHECKLIST.md`** - Acompanhamento de progresso:
- Status de cada fase
- Checklist de integrações
- Bloqueadores atuais
- Próximas ações
- Métricas de sucesso

---

## ⚙️ Configuração

---

## ⚙️ Configuração

### Credenciais Necessárias (Mínimo)

#### 1. Supabase (PostgreSQL)
```
Credential Type: Postgres
Name: Supabase Main DB

Host: db.[SEU-PROJETO].supabase.co
Port: 5432
Database: postgres
User: postgres
Password: [SUA-SENHA-SUPABASE]
SSL: Enabled
```

#### 2. Redis
```
Credential Type: Redis
Name: Redis Main

Host: [SEU-REDIS-HOST]
Port: 6379
Password: [SENHA-REDIS]
Database: 0 (para buffer) e 1 (para memória)
```

#### 3. Chatwoot API
```
Credential Type: HTTP Header Auth
Name: Chatwoot API

Header Name: api_access_token
Value: [Chatwoot Profile → Access Token]
```

### Credenciais Opcionais (Integrações Avançadas)

#### 4. Google Speech-to-Text (Transcrição de Áudio)
#### 4. Google Speech-to-Text (Transcrição de Áudio)
```
Credential Type: Google Cloud Service Account
Name: Google Cloud STT

Service Account JSON: [arquivo .json da service account]
```

#### 5. Redis (Buffer & Cache)
```
Credential Type: Redis
Name: Redis Main

Host: localhost (ou redis.upstash.com)
Port: 6379
Password: [se necessário]
```

#### 6. Pinecone/Qdrant (Vector DB para RAG)
```
Credential Type: HTTP Header Auth
Name: Pinecone API

Header Name: Api-Key
Value: [Pinecone API Key]
```

### Variáveis de Ambiente

Copie `.env.example` para `.env` e preencha:

```bash
# Obrigatório
SUPABASE_HOST=db.xxx.supabase.co
OPENAI_API_KEY=sk-...
CHATWOOT_ACCOUNT_ID=123

# Opcional (integrações avançadas)
GOOGLE_CLOUD_SERVICE_ACCOUNT_PATH=/path/to/sa.json
REDIS_HOST=localhost
PINECONE_API_KEY=...
```

---

## 🔗 Webhook & Integração

---

## 🔗 Webhook & Integração

### URL do Webhook

```
https://seu-n8n.com/webhook/chatwoot-webhook
```

### Configurar no Chatwoot

1. **Settings** → **Integrations** → **Webhooks**
2. **Add Webhook**:
   - URL: `https://seu-n8n.com/webhook/chatwoot-webhook`
   - Events: `message_created`
3. **Save**

### Custom Attributes (Importante!)

Cada conversa no Chatwoot deve ter:

```json
{
  "client_id": "clinica_sorriso_001",
  "agent_id": "default"
}
```

Isso identifica qual cliente e qual agente processar.

---

## 📊 Dados e Tracking

---

## 📊 Dados e Tracking

### Tabelas do Banco de Dados

O workflow atualiza automaticamente:

| Tabela | O que armazena |
|--------|----------------|
| `agents` | Configuração de cada agente |
| `agent_templates` | Templates (SDR, Support, etc) |
| `client_subscriptions` | Usage tracking e limites |

### Consultas Úteis

```sql
-- Ver uso atual de um cliente
SELECT 
  client_id,
  agent_id,
  total_messages,
  message_limit,
  transcription_minutes_used,
  images_processed,
  last_message_at
FROM client_subscriptions
WHERE client_id = 'clinica_sorriso_001';

-- Ver todas as assinaturas ativas
SELECT 
  s.client_id,
  s.agent_id,
  t.name as template_name,
  s.monthly_price,
  s.total_messages,
  s.message_limit
FROM client_subscriptions s
JOIN agent_templates t ON s.template_id = t.template_id
WHERE s.status = 'active';

-- Calcular MRR total
SELECT 
  SUM(monthly_price) as mrr_brl,
  SUM(monthly_price / 5.33) as mrr_usd,
  COUNT(*) as total_clientes
FROM client_subscriptions
WHERE status = 'active';
```

### Custos por Interação

| Componente | Custo | Quando |
|------------|-------|--------|
| Mensagem texto | $0.0001 | Sempre |
| Transcrição áudio | $0.006/min | Se houver áudio |
| Vision AI (imagem) | $0.01 | Se houver imagem |
| RAG query | $0.0001 | Sempre |
| Function calling | +20% LLM | Se usar tools |

**Exemplo**: Mensagem com áudio 30s + foto = $0.0134 (~R$0.071)

---

## 🧪 Testes

### Casos de Teste Recomendados

1. ✅ **Texto simples**: "Olá, teste"
2. ✅ **Áudio**: Mensagem de voz 30s
3. ✅ **Imagem**: Foto de um produto
4. ✅ **Documento**: PDF com texto
5. ✅ **Multi-modal**: Texto + áudio + imagem
6. ✅ **Function calling**: "Agende reunião amanhã 14h"

### Validar Resultados

Após cada teste, verificar:
- ✅ Resposta correta no Chatwoot
- ✅ `total_messages` incrementou
- ✅ `transcription_minutes_used` atualizado (se áudio)
- ✅ `images_processed` atualizado (se imagem)
- ✅ Execução sem erros no n8n

---

## 🐛 Troubleshooting

Ver problemas comuns e soluções detalhadas em `WF0-QUICK-START.md`

### ✅ Fase 1: Database (100%)
- Database schema completo
- **Migration 007 executada**: Multi-tenancy Chatwoot
- 1 cliente configurado (clinica_sorriso_001)
- Sistema validado

### ✅ Fase 2: Workflow (100%) 🆕
- Workflow REORGANIZADO em produção
- **Upload de anexos PDF**: ✅ Implementado e testado
- **Multi-tenancy**: ✅ Inbox dedicado por cliente
- **Loop prevention**: ✅ Filtro de mensagens outgoing
- **Código otimizado**: ✅ Console.log removidos
- Chatwoot hub configurado e testado

### ⏳ Fase 3: WhatsApp Real (0%)
- Configurar canal WhatsApp no Chatwoot
- Testar com número real
- Validar anexos via WhatsApp
- Testar com múltiplos clientes

**Status atual**: Database 100% | Workflow 100% | WhatsApp 0%
- 30 nodes implementados
- Chatwoot hub configurado
- **Pendente**: Importar no n8n e testar

### ⏳ Fase 3: Integrações (0%)
- Google Speech-to-Text
- GPT-4 Vision
- Vector DB (RAG)
- Redis buffer

**Status atual**: Database 100% | Workflow 80% | Integrações 0%

## 🚀 Próximos Passos

1. ✅ ~~Implementar upload de anexos PDF~~ (CONCLUÍDO)
2. ✅ ~~Configurar multi-tenancy Chatwoot~~ (CONCLUÍDO)
3. ✅ ~~Otimizar código do workflow~~ (CONCLUÍDO)
4. ⏳ **Configurar WhatsApp real no Chatwoot** (próximo)
5. ⏳ **Testar com múltiplos clientes** (após WhatsApp)
6. ⏳ **Deploy em produção** (após testes)

📖 **Guia completo**: `WF0-QUICK-START.md` (instalação em 10 min)

📖 **Guia completo**: `WF0-QUICK-START.md` (instalação em 10 min)

---

## 📚 Recursos

### Documentação
- `WF0-DOCUMENTATION.md` - Técnica completa
- `WF0-QUICK-START.md` - Instalação rápida
- `INTEGRATION-CHECKLIST.md` - Status
- `.env.example` - Configuração

### Comunidades
- n8n: https://community.n8n.io
- Chatwoot: https://chatwoot.com/slack
- Supabase: https://discord.supabase.com

**Versão**: 0.3.0 (WF0 REORGANIZADO - PDF + Multi-tenancy)  
**Última atualização**: 09/11/2025  
**Status**: ✅ Database | ✅ Workflow | ⏳ WhatsApp Real
**Última atualização**: 06/11/2025  
**Status**: ✅ Database | 🟡 Workflow | ⏳ Integrações

# WF0 - Gestor Universal - Documentação Completa

## 🎯 Visão Geral

Workflow completo para gestão multi-agente com suporte a **todos os canais**, **processamento de mídia** (áudio, imagem, vídeo, documentos) e **Chatwoot como hub central**.

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CHATWOOT (HUB CENTRAL)                       │
│  WhatsApp │ Email │ Instagram │ Messenger │ Telegram │ Webchat      │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  n8n Webhook   │
                    └────────┬───────┘
                             │
                             ▼
            ┌────────────────────────────────┐
            │  1. Identificar Cliente/Agente │
            │     (client_id + agent_id)      │
            └────────────┬───────────────────┘
                         │
                         ▼
            ┌────────────────────────────────┐
            │  2. Buscar Dados do DB         │
            │     (agents + subscriptions)    │
            └────────────┬───────────────────┘
                         │
                         ▼
            ┌────────────────────────────────┐
            │  3. Tem Mídia? ─────┐          │
            │     ├─ Não → Texto  │          │
            │     └─ Sim ↓        │          │
            └─────────────┬───────┴──────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
    ┌─────────┐     ┌─────────┐     ┌──────────┐
    │ Áudio   │     │ Imagem  │     │ Arquivo  │
    │ (Speech │     │ (Vision │     │ (Extract)│
    │  to     │     │   AI)   │     │          │
    │  Text)  │     │         │     │          │
    └────┬────┘     └────┬────┘     └────┬─────┘
         │               │               │
         └───────────────┼───────────────┘
                         ▼
            ┌────────────────────────────────┐
            │  4. Construir Contexto Completo│
            │     (texto + mídia processada)  │
            └────────────┬───────────────────┘
                         │
                         ▼
            ┌────────────────────────────────┐
            │  5. Buffer Redis (5s)          │
            │     (agrupar mensagens rápidas) │
            └────────────┬───────────────────┘
                         │
                         ▼
            ┌────────────────────────────────┐
            │  6. Query RAG                  │
            │     (namespace: client/agent)   │
            └────────────┬───────────────────┘
                         │
                         ▼
            ┌────────────────────────────────┐
            │  7. LLM (GPT-4o-mini)          │
            │     + Function Calling         │
            │     (Calendar, Sheets, CRM)    │
            └────────────┬───────────────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
    ┌─────────┐                    ┌─────────┐
    │ Chamou  │                    │ Resposta│
    │ Tool?   │                    │ Direta  │
    │   Sim ──┤                    │         │
    └────┬────┘                    └────┬────┘
         │                              │
         ▼                              │
    ┌─────────────┐                    │
    │ Executar    │                    │
    │ Tools       │                    │
    │ (Calendar/  │                    │
    │  Sheets)    │                    │
    └────┬────────┘                    │
         │                              │
         └──────────────┬───────────────┘
                        ▼
            ┌────────────────────────────────┐
            │  8. Atualizar Usage Tracking   │
            │     (messages, transcription,   │
            │      images_processed)          │
            └────────────┬───────────────────┘
                         │
                         ▼
            ┌────────────────────────────────┐
            │  9. Enviar Resposta            │
            │     via Chatwoot               │
            │     (texto + mídia gerada)     │
            └────────────────────────────────┘
```

---

## 📋 Componentes Principais

### 1. **Chatwoot Webhook**
- **URL**: `https://seu-n8n.com/webhook/chatwoot-webhook`
- **Método**: POST
- **Payload**: Eventos do Chatwoot (message_created, conversation_updated, etc.)

### 2. **Identificação de Cliente/Agente**
- Extrai `client_id` e `agent_id` dos custom attributes da conversa
- Identifica canal (whatsapp, email, instagram, etc.)
- Detecta tipo de conteúdo (text, image, audio, video, file)

### 3. **Processamento de Mídia**

#### 3.1. Áudio (Transcrição)
- **API Recomendada**: Google Speech-to-Text ou OpenAI Whisper
- **Input**: URL do arquivo de áudio
- **Output**: Texto transcrito + duração em segundos
- **Custo**: ~$0.006/minuto (Google) ou $0.006/minuto (Whisper)

#### 3.2. Imagem (Vision AI)
- **API Recomendada**: GPT-4 Vision ou Google Vision AI
- **Input**: URL da imagem
- **Output**: Descrição detalhada, objetos detectados, texto na imagem (OCR)
- **Custo**: ~$0.01/imagem (GPT-4V)

#### 3.3. Documentos (Extração de Texto)
- **Bibliotecas**: pdf-parse (PDF), mammoth (DOCX)
- **Input**: URL do arquivo
- **Output**: Texto extraído
- **Custo**: Processamento local (sem custo de API)

### 4. **Buffer & Agrupamento**
- **Redis**: Armazena mensagens com TTL de 5 segundos
- **Key**: `{client_id}:{agent_id}:{conversation_id}`
- **Objetivo**: Agrupar mensagens enviadas rapidamente (ex: 3 mensagens em 2 segundos)

### 5. **RAG (Retrieval-Augmented Generation)**
- **Vector DB**: Pinecone, Qdrant ou Weaviate
- **Namespace**: `{client_id}/{agent_id}` (isolamento total)
- **Query**: Contexto completo (texto + mídia processada)
- **Top K**: 3-5 resultados mais relevantes

### 6. **LLM + Function Calling**
- **Modelo Principal**: GPT-4o-mini (70%) + GPT-4o (30%)
- **Temperature**: 0.7
- **Max Tokens**: 1000-2000
- **Tools Disponíveis**:
  - `create_calendar_event`: Criar eventos no Google Calendar
  - `update_sheet`: Atualizar Google Sheets
  - `search_crm`: Buscar informações no CRM

### 7. **Usage Tracking**
Atualiza `client_subscriptions` após cada interação:

```sql
UPDATE client_subscriptions
SET 
  total_messages = total_messages + 1,
  transcription_minutes_used = transcription_minutes_used + (total_seconds / 60.0),
  images_processed = images_processed + image_count,
  last_message_at = NOW()
WHERE client_id = ? AND agent_id = ?
```

### 8. **Resposta Multi-Modal**
- **Texto**: Sempre incluído
- **Imagens**: Geradas via DALL-E ou Stable Diffusion (quando solicitado)
- **Arquivos**: PDFs, planilhas, relatórios (quando gerados por tools)

---

## 🔧 Configuração

### Credenciais Necessárias

1. **Supabase Database**
   - Host: `db.xxx.supabase.co`
   - Port: 5432
   - Database: `postgres`
   - User: `postgres`
   - Password: [Supabase Dashboard]

2. **OpenAI API**
   - API Key: `sk-...`
   - Modelos: `gpt-4o-mini`, `gpt-4o`

3. **Chatwoot API**
   - Base URL: `https://app.chatwoot.com`
   - Account ID: [Chatwoot Settings]
   - API Token: [Chatwoot Profile → Access Token]

4. **Google Cloud (Speech-to-Text)**
   - Service Account JSON
   - API habilitada: Cloud Speech-to-Text API

5. **Redis** (opcional, para buffer)
   - Host: `redis.upstash.com` (ou local)
   - Port: 6379
   - Password: [Upstash Console]

6. **Vector DB** (Pinecone/Qdrant)
   - API Key
   - Environment
   - Index Name

---

## 📊 Tracking de Custos

### Custos por Interação

| Componente           | Custo Unitário         | Quando Ocorre          |
|----------------------|------------------------|------------------------|
| Mensagem de texto    | $0.0001 (LLM)          | Sempre                 |
| Transcrição de áudio | $0.006/min             | Se houver áudio        |
| Análise de imagem    | $0.01/imagem           | Se houver imagem       |
| RAG query            | $0.0001                | Sempre                 |
| Function calling     | +20% tokens LLM        | Se chamar tools        |

### Exemplo Real
Cliente enviou: "Oi" + áudio de 30s + 1 foto

```
- Texto: $0.0001
- Transcrição: $0.003 (0.5 min × $0.006)
- Vision AI: $0.01
- RAG: $0.0001
- LLM resposta: $0.0002
─────────────────────────
Total: $0.0134 (~R$0.071)
```

Com plano de **R$697/mês** e **98.94% margem**, cada interação custa **R$0.071** e você cobra **R$697**.

---

## 🚀 Deploy

### 1. Importar Workflow no n8n

```bash
# Copiar arquivo para n8n
cp workflows/WF0-Gestor-Universal-COMPLETE.json /home/n8n/.n8n/workflows/

# Ou importar via UI:
# n8n UI → Workflows → Import from File
```

### 2. Configurar Credenciais

No n8n:
1. Credentials → Add Credential
2. Adicionar todas as credenciais listadas acima
3. Atualizar IDs nos nodes do workflow

### 3. Configurar Webhook no Chatwoot

1. Chatwoot → Settings → Integrations → Webhooks
2. URL: `https://seu-n8n.com/webhook/chatwoot-webhook`
3. Events: `message_created`, `conversation_updated`

### 4. Testar

```bash
# Enviar mensagem de teste via WhatsApp
# Verificar logs no n8n
# Confirmar resposta no Chatwoot
```

---

## 🧪 Testes

### Casos de Teste

1. **Texto Simples**
   - Input: "Olá, preciso de ajuda"
   - Expected: Resposta do LLM com contexto do RAG

2. **Áudio**
   - Input: Mensagem de áudio 30s
   - Expected: Transcrição + resposta baseada no áudio

3. **Imagem**
   - Input: Foto de um produto
   - Expected: Descrição da imagem + resposta contextualizada

4. **Documento PDF**
   - Input: PDF com contrato
   - Expected: Texto extraído + análise do conteúdo

5. **Multi-Modal**
   - Input: "Veja esta foto" + imagem + áudio explicando
   - Expected: Análise completa de todas as mídias

6. **Function Calling**
   - Input: "Agende reunião para amanhã 14h"
   - Expected: Evento criado no Calendar + confirmação

---

## 🔍 Monitoramento

### Métricas Importantes

```sql
-- 1. Total de mensagens processadas hoje
SELECT 
  client_id,
  agent_id,
  COUNT(*) as mensagens_hoje
FROM client_subscriptions
WHERE DATE(last_message_at) = CURRENT_DATE
GROUP BY client_id, agent_id;

-- 2. Uso de transcrição (minutos)
SELECT 
  client_id,
  transcription_minutes_used,
  transcription_minutes_limit,
  ROUND(transcription_minutes_used / transcription_minutes_limit * 100, 2) as percentual_usado
FROM client_subscriptions
WHERE transcription_minutes_limit > 0;

-- 3. Imagens processadas
SELECT 
  client_id,
  images_processed,
  DATE(last_message_at) as data
FROM client_subscriptions
ORDER BY images_processed DESC;

-- 4. Clientes próximos do limite
SELECT 
  client_id,
  total_messages,
  message_limit,
  message_limit - total_messages as mensagens_restantes
FROM client_subscriptions
WHERE total_messages >= message_limit * 0.8  -- 80% do limite
ORDER BY mensagens_restantes ASC;
```

---

## 🛠️ Manutenção

### Logs de Erro

Erros são capturados pelo node **Error Handler** e:
1. Logados no console do n8n
2. Enviados para Sentry (opcional)
3. Usuário recebe mensagem genérica: "Desculpe, ocorreu um erro temporário..."

### Retry Logic

- **RAG query**: 3 tentativas com backoff exponencial
- **LLM**: 2 tentativas
- **Chatwoot API**: 3 tentativas

### Backups

```bash
# Backup semanal do workflow
n8n export:workflow --id=WF0 --output=backups/wf0-$(date +%Y%m%d).json

# Backup do Redis (buffer)
redis-cli SAVE
```

---

## 📈 Próximos Passos

### Fase 2 - Melhorias
- [ ] Integrar Google Speech-to-Text (áudio real)
- [ ] Integrar GPT-4 Vision (imagens reais)
- [ ] Implementar Redis buffer (agrupamento real)
- [ ] Conectar Vector DB (RAG real)
- [ ] Adicionar mais tools (Notion, Trello, Slack)

### Fase 3 - Escalabilidade
- [ ] Queue system (Bull/BullMQ) para processar mensagens em fila
- [ ] Horizontal scaling do n8n (múltiplas instâncias)
- [ ] Cache de respostas frequentes (Redis)
- [ ] Rate limiting por cliente

### Fase 4 - Analytics
- [ ] Dashboard de métricas (Grafana)
- [ ] Alertas de uso excessivo (email/SMS)
- [ ] Relatórios mensais automáticos
- [ ] ML para detectar anomalias

---

## 📞 Suporte

**Dúvidas ou problemas?**
- Verificar logs no n8n: Executions → Ver detalhes
- Consultar DB: `SELECT * FROM client_subscriptions WHERE client_id = ?`
- Testar componente isolado: Executar node individual

**Contato**:
- Email: suporte@seudominio.com
- Slack: #n8n-workflows
- Docs: https://docs.n8n.io

---

## 📄 Licença

Proprietary - Todos os direitos reservados © 2025

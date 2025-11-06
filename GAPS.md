# 🔴 GAPS & CORREÇÕES - Plataforma SaaS Multi-Tenant

**Data:** 06/11/2025  
**Versão:** 1.0  
**Status:** 🚨 CRÍTICO - Correções necessárias antes de implementação

---

## 📋 ÍNDICE

1. [Arquitetura: Múltiplos Agentes por Cliente](#1-arquitetura-múltiplos-agentes-por-cliente)
2. [Chatwoot como Hub Central](#2-chatwoot-como-hub-central)
3. [Processamento de Mídia - Input](#3-processamento-de-mídia---input)
4. [Processamento de Mídia - Output](#4-processamento-de-mídia---output)
5. [WhatsApp: Múltiplos Providers](#5-whatsapp-múltiplos-providers)
6. [Multi-Tenancy Explícito](#6-multi-tenancy-explícito)
7. [Plano de Implementação](#7-plano-de-implementação)

---

## 🔴 1. ARQUITETURA: Múltiplos Agentes por Cliente

### ❌ **PROBLEMA ATUAL:**

Schema atual assume **1 cliente = 1 agente**:
```sql
-- LIMITAÇÃO: Só 1 system_prompt por cliente
CREATE TABLE clients (
  client_id text PRIMARY KEY,
  system_prompt text,  -- ❌ Um só prompt!
  tools_enabled jsonb, -- ❌ Tools globais para o cliente
  ...
);
```

**Cenário impossível hoje:**
```
Cliente "Acme Corp" quer:
- Agente 1: SDR (WhatsApp vendas)
- Agente 2: Suporte (Chatwoot)
- Agente 3: Cobrança (WhatsApp cobrança)

❌ Impossível com schema atual!
```

---

### ✅ **SOLUÇÃO: Tabela `agents`**

```sql
-- NOVA TABELA: agents
CREATE TABLE public.agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id text NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
  
  -- Identificação do Agente
  agent_id text NOT NULL, -- Ex: "sdr", "suporte", "cobranca"
  agent_name text NOT NULL, -- Ex: "Lucas - SDR", "Ana - Suporte"
  agent_description text, -- Opcional
  
  -- Comportamento do Agente (específico)
  system_prompt text NOT NULL,
  
  -- LLM Config (pode ser diferente por agente)
  llm_provider text DEFAULT 'google',
  llm_model text DEFAULT 'gemini-2.0-flash-exp',
  llm_config jsonb DEFAULT '{
    "temperature": 0.7,
    "max_tokens": 2048
  }'::jsonb,
  
  -- Tools específicas deste agente
  tools_enabled jsonb DEFAULT '["rag"]'::jsonb,
  
  -- RAG Config (namespace isolado por agente)
  rag_namespace text, -- Ex: "acme-corp-sdr-rag", "acme-corp-suporte-rag"
  rag_config jsonb,
  
  -- Canais que este agente atende
  channels text[], -- Ex: {"whatsapp_vendas", "instagram"}
  
  -- Buffer config
  buffer_delay integer DEFAULT 2,
  
  -- Status
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Constraints
  CONSTRAINT unique_client_agent UNIQUE(client_id, agent_id)
);

CREATE INDEX idx_agents_client_id ON public.agents(client_id);
CREATE INDEX idx_agents_active ON public.agents(is_active);
CREATE INDEX idx_agents_channels ON public.agents USING GIN(channels);

-- Comments
COMMENT ON TABLE public.agents IS 
  'Agentes de IA por cliente. Um cliente pode ter múltiplos agentes (SDR, Suporte, Cobrança, etc)';

COMMENT ON COLUMN public.agents.agent_id IS 
  'Identificador único do agente dentro do cliente (slug). Ex: sdr, suporte, cobranca';

COMMENT ON COLUMN public.agents.channels IS 
  'Array de channel_ids que este agente atende. Permite roteamento inteligente.';
```

---

### 🔄 **MIGRAÇÃO: Tabela `clients`**

```sql
-- Tabela clients vira "conta do cliente"
-- Remove campos específicos de agente

ALTER TABLE public.clients
  -- Remover (mover para agents)
  DROP COLUMN IF EXISTS system_prompt,
  DROP COLUMN IF EXISTS llm_provider,
  DROP COLUMN IF EXISTS llm_model,
  DROP COLUMN IF EXISTS llm_config,
  DROP COLUMN IF EXISTS tools_enabled,
  DROP COLUMN IF EXISTS rag_namespace,
  DROP COLUMN IF EXISTS rag_config,
  DROP COLUMN IF EXISTS buffer_delay,
  
  -- Manter apenas configs globais da conta
  -- (rate_limits, billing, admin_email, etc)
;

-- Adicionar campo para controlar quantidade de agentes
ALTER TABLE public.clients
  ADD COLUMN max_agents integer DEFAULT 1,
  ADD COLUMN active_agents_count integer DEFAULT 0;

COMMENT ON COLUMN public.clients.max_agents IS 
  'Número máximo de agentes permitidos (baseado no plano)';

COMMENT ON COLUMN public.clients.active_agents_count IS 
  'Contador de agentes ativos. Atualizado via trigger.';
```

---

### 📊 **EXEMPLO: Cliente com 3 Agentes**

```sql
-- 1. Cliente
INSERT INTO clients (client_id, client_name, max_agents) 
VALUES ('acme-corp', 'Acme Corporation', 5);

-- 2. Agente 1: SDR
INSERT INTO agents (
  client_id, agent_id, agent_name, 
  system_prompt, tools_enabled, channels
) VALUES (
  'acme-corp',
  'sdr',
  'Lucas - SDR',
  'Você é Lucas, SDR agressivo focado em qualificação de leads...',
  '["rag", "calendar_google", "crm_pipedrive"]'::jsonb,
  ARRAY['whatsapp_vendas', 'instagram']
);

-- 3. Agente 2: Suporte
INSERT INTO agents (
  client_id, agent_id, agent_name,
  system_prompt, tools_enabled, channels
) VALUES (
  'acme-corp',
  'suporte',
  'Ana - Suporte Técnico',
  'Você é Ana, analista de suporte técnico empática e paciente...',
  '["rag", "ticket_system"]'::jsonb,
  ARRAY['chatwoot', 'email']
);

-- 4. Agente 3: Cobrança
INSERT INTO agents (
  client_id, agent_id, agent_name,
  system_prompt, tools_enabled, channels
) VALUES (
  'acme-corp',
  'cobranca',
  'Roberto - Cobrança',
  'Você é Roberto, analista de cobrança profissional e firme...',
  '["rag", "payment_stripe"]'::jsonb,
  ARRAY['whatsapp_cobranca', 'email']
);
```

---

### 🔀 **ROTEAMENTO: Webhook com `agent_id`**

```javascript
// ANTES (1 agente por cliente):
POST /webhook/gestor-ia?client_id=acme-corp

// DEPOIS (múltiplos agentes):
POST /webhook/gestor-ia?client_id=acme-corp&agent_id=sdr
POST /webhook/gestor-ia?client_id=acme-corp&agent_id=suporte
POST /webhook/gestor-ia?client_id=acme-corp&agent_id=cobranca

// OU roteamento automático por canal:
POST /webhook/gestor-ia?client_id=acme-corp&channel_id=whatsapp_vendas
→ Sistema detecta: whatsapp_vendas → agente "sdr"
```

---

### 📝 **WORKFLOW: Load Agent Config**

```javascript
// Node: Load Agent Config (WF0 Part 1)

const client_id = $json.client_id;
const agent_id = $json.agent_id || 'default';
const channel_id = $json.channel_id;

// Opção 1: agent_id explícito
if (agent_id && agent_id !== 'default') {
  const agent = await supabase
    .from('agents')
    .select('*')
    .eq('client_id', client_id)
    .eq('agent_id', agent_id)
    .eq('is_active', true)
    .single();
  
  return agent.data;
}

// Opção 2: Detectar por canal
if (channel_id) {
  const agent = await supabase
    .from('agents')
    .select('*')
    .eq('client_id', client_id)
    .contains('channels', [channel_id])
    .eq('is_active', true)
    .limit(1)
    .single();
  
  return agent.data;
}

// Opção 3: Fallback para agente padrão
const defaultAgent = await supabase
  .from('agents')
  .select('*')
  .eq('client_id', client_id)
  .eq('agent_id', 'default')
  .eq('is_active', true)
  .single();

return defaultAgent.data;
```

---

### 📊 **IMPACTO: Outras Tabelas**

```sql
-- rag_documents: Adicionar agent_id
ALTER TABLE public.rag_documents
  ADD COLUMN agent_id text,
  ADD CONSTRAINT fk_agent 
    FOREIGN KEY (client_id, agent_id) 
    REFERENCES public.agents(client_id, agent_id) 
    ON DELETE CASCADE;

CREATE INDEX idx_rag_agent ON public.rag_documents(client_id, agent_id);

-- agent_executions: Adicionar agent_id
ALTER TABLE public.agent_executions
  ADD COLUMN agent_id text;

CREATE INDEX idx_executions_agent ON public.agent_executions(client_id, agent_id);

-- channels: Relacionar com agent_id
ALTER TABLE public.channels
  ADD COLUMN assigned_agent_id text,
  ADD CONSTRAINT fk_agent 
    FOREIGN KEY (client_id, assigned_agent_id) 
    REFERENCES public.agents(client_id, agent_id) 
    ON DELETE SET NULL;

COMMENT ON COLUMN public.channels.assigned_agent_id IS 
  'Agente responsável por este canal. Permite roteamento automático.';
```

---

## 🔴 2. CHATWOOT COMO HUB CENTRAL

### ❌ **PROBLEMA ATUAL:**

Workflows documentam múltiplos webhooks diretos:
```
WhatsApp Evolution → /webhook/gestor-ia/whatsapp
Instagram → /webhook/gestor-ia/instagram
Email → Polling IMAP
Chatwoot → /webhook/gestor-ia/chatwoot
```

**Complexidade:** 5+ webhooks, 5+ adapters, difícil manter.

---

### ✅ **SOLUÇÃO: Chatwoot como Hub Único**

```
TODOS os canais → Chatwoot (inbox) → 1 webhook → n8n WF-0

WhatsApp Evolution ──┐
WhatsApp Meta Cloud ──┤
Instagram           ──┼──► CHATWOOT ──► /webhook/chatwoot ──► WF-0
Telegram            ──┤
Email (SMTP)        ──┤
Webchat             ──┘
```

**Benefícios:**
- ✅ 1 webhook ao invés de 5+
- ✅ Dashboard unificado para clientes
- ✅ Handoff humano facilitado
- ✅ Histórico centralizado
- ✅ 70% menos código

---

### 📝 **SETUP CHATWOOT:**

```yaml
# Configuração por Cliente

1. Criar Account no Chatwoot:
   - Nome: "Acme Corporation"
   - Domain: acme-corp

2. Criar Inboxes (1 por canal):
   
   Inbox 1: WhatsApp Vendas
   - Type: WhatsApp (via Evolution API ou Meta Cloud)
   - Agent: "sdr" (roteamento automático)
   
   Inbox 2: Instagram
   - Type: Instagram
   - Agent: "sdr"
   
   Inbox 3: Chatwoot Webchat
   - Type: Website
   - Agent: "suporte"
   
   Inbox 4: Email Suporte
   - Type: Email (IMAP)
   - Agent: "suporte"

3. Configurar Webhook do Chatwoot:
   - URL: https://n8n.evolutedigital.com.br/webhook/chatwoot
   - Events: message_created, conversation_created
   - Adicionar custom attribute: 
     * client_id: "acme-corp"
     * agent_id: "sdr" (ou detectar por inbox_id)
```

---

### 📋 **WEBHOOK FORMAT (Chatwoot → n8n):**

```json
POST /webhook/chatwoot

{
  "event": "message_created",
  "account": {
    "id": 1,
    "name": "Acme Corporation"
  },
  "inbox": {
    "id": 5,
    "name": "WhatsApp Vendas",
    "channel_type": "Channel::Whatsapp"
  },
  "conversation": {
    "id": 123,
    "inbox_id": 5,
    "contact_inbox": {
      "source_id": "5521999999999@s.whatsapp.net"
    },
    "custom_attributes": {
      "client_id": "acme-corp",
      "agent_id": "sdr"
    }
  },
  "sender": {
    "id": 456,
    "name": "João Silva",
    "phone_number": "+5521999999999",
    "email": null
  },
  "content": "Olá, quero saber sobre preços",
  "message_type": "incoming",
  "content_type": "text",
  "attachments": []
}
```

---

### 🔀 **WORKFLOW: Extract & Validate (Chatwoot-first)**

```javascript
// Node: Extract & Validate (WF0 Part 1)

const body = $input.item.json.body || {};

// ÚNICO formato aceito: Chatwoot
if (!body.event || body.event !== 'message_created') {
  throw new Error('Invalid webhook format. Only Chatwoot webhooks are accepted.');
}

// Extrair dados
const client_id = body.conversation?.custom_attributes?.client_id;
const agent_id = body.conversation?.custom_attributes?.agent_id || 'default';

if (!client_id) {
  throw new Error('client_id is required in conversation.custom_attributes');
}

const messageData = {
  client_id,
  agent_id,
  
  // Identificação
  conversation_id: body.conversation.id.toString(),
  contact_id: body.sender.phone_number || body.sender.email,
  
  // Mensagem
  user_message: body.content || '',
  user_message_type: body.content_type || 'text',
  user_attachments: body.attachments || [],
  
  // Metadata
  sender_name: body.sender.name,
  inbox_id: body.inbox.id,
  inbox_name: body.inbox.name,
  channel_type: body.inbox.channel_type, // "Channel::Whatsapp", "Channel::Web", etc
  
  timestamp: new Date().toISOString()
};

return messageData;
```

---

### 📤 **RESPONSE: Enviar via Chatwoot**

```javascript
// Node: Send Response (WF0 Part 3)

const chatwootHost = 'https://chatwoot.evolutedigital.com.br';
const accountId = $json.chatwoot_account_id; // Do config do cliente
const conversationId = $json.conversation_id;
const responseText = $json.final_response;

// Enviar mensagem via Chatwoot API
await fetch(
  `${chatwootHost}/api/v1/accounts/${accountId}/conversations/${conversationId}/messages`,
  {
    method: 'POST',
    headers: {
      'api_access_token': chatwootApiToken,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      content: responseText,
      message_type: 'outgoing',
      private: false
    })
  }
);

// Chatwoot encaminha automaticamente para o canal correto!
// (WhatsApp, Instagram, Email, Webchat)
```

---

## 🔴 3. PROCESSAMENTO DE MÍDIA - INPUT

### ❌ **STATUS ATUAL:**

| Tipo | Detecta | Processa | Status |
|------|---------|----------|--------|
| Texto | ✅ | ✅ | Funciona |
| Áudio | ⚠️ | ❌ | Não transcreve |
| Imagem | ⚠️ | ❌ | Não analisa |
| Vídeo | ⚠️ | ❌ | Não processa |
| Documento | ⚠️ | ❌ | Não extrai texto |

---

### ✅ **SOLUÇÃO: Adicionar Processamento**

#### **A) Áudio → Texto (Speech-to-Text)**

```javascript
// Node: Process Audio Input (WF0 Part 1)

if ($json.user_message_type === 'audio' || 
    $json.user_attachments.some(a => a.file_type === 'audio')) {
  
  const audioAttachment = $json.user_attachments.find(a => a.file_type === 'audio');
  const audioUrl = audioAttachment.data_url;
  
  // Download áudio
  const audioResponse = await fetch(audioUrl);
  const audioBuffer = await audioResponse.arrayBuffer();
  
  // Transcrever com Google Speech-to-Text
  const transcription = await transcribeAudio(audioBuffer, {
    languageCode: 'pt-BR',
    model: 'latest_long',
    audioEncoding: 'OGG_OPUS'
  });
  
  // Substituir mensagem pelo texto transcrito
  $json.user_message = transcription.text;
  $json.original_media_type = 'audio';
  $json.transcription_confidence = transcription.confidence;
  
  console.log('[AUDIO] Transcribed:', transcription.text);
}
```

**API:** Google Cloud Speech-to-Text  
**Custo:** $0.006/minuto (60 segundos)  
**Formatos:** OGG, MP3, AAC, WAV, FLAC

---

#### **B) Imagem → Análise (Vision)**

```javascript
// Node: Process Image Input (WF0 Part 1)

if ($json.user_message_type === 'image' || 
    $json.user_attachments.some(a => a.file_type === 'image')) {
  
  const imageAttachment = $json.user_attachments.find(a => a.file_type === 'image');
  const imageUrl = imageAttachment.data_url;
  
  // Download imagem
  const imageResponse = await fetch(imageUrl);
  const imageBuffer = await imageResponse.arrayBuffer();
  const imageBase64 = Buffer.from(imageBuffer).toString('base64');
  
  // Preparar para Gemini Vision
  $json.image_data = {
    mimeType: imageAttachment.content_type || 'image/jpeg',
    data: imageBase64
  };
  $json.supports_vision = true;
  
  // Se user_message vazio, perguntar sobre a imagem
  if (!$json.user_message) {
    $json.user_message = 'O que você vê nesta imagem?';
  }
  
  console.log('[IMAGE] Vision enabled for:', imageUrl);
}
```

**API:** Gemini 2.0 Flash (vision nativo)  
**Custo:** Mesmo preço LLM ($0.075/1M tokens)  
**Formatos:** JPG, PNG, WEBP, GIF, BMP

---

#### **C) Documento → Texto (OCR/Parse)**

```javascript
// Node: Process Document Input (WF0 Part 1)

if ($json.user_message_type === 'file' || 
    $json.user_attachments.some(a => a.file_type === 'file')) {
  
  const docAttachment = $json.user_attachments.find(a => a.file_type === 'file');
  const docUrl = docAttachment.data_url;
  const filename = docAttachment.file_name;
  const extension = filename.split('.').pop().toLowerCase();
  
  let extractedText = '';
  
  if (extension === 'pdf') {
    // Extrair texto de PDF
    const pdfBuffer = await downloadFile(docUrl);
    extractedText = await extractTextFromPDF(pdfBuffer);
  } 
  else if (extension === 'docx') {
    // Extrair texto de DOCX
    const docxBuffer = await downloadFile(docUrl);
    extractedText = await extractTextFromDOCX(docxBuffer);
  }
  else if (['txt', 'csv'].includes(extension)) {
    // Texto puro
    const textResponse = await fetch(docUrl);
    extractedText = await textResponse.text();
  }
  
  // Adicionar ao contexto
  $json.user_message = `[Documento: ${filename}]\n\n${extractedText.substring(0, 8000)}`;
  $json.original_media_type = 'document';
  
  console.log('[DOCUMENT] Extracted', extractedText.length, 'chars from', filename);
}
```

**Bibliotecas:**
- PDF: `pdf-parse` (Node.js) ou Google Document AI
- DOCX: `mammoth.js`
- TXT/CSV: Native

---

#### **D) Vídeo → Análise (Gemini Video)**

```javascript
// Node: Process Video Input (WF0 Part 1)

if ($json.user_message_type === 'video' || 
    $json.user_attachments.some(a => a.file_type === 'video')) {
  
  const videoAttachment = $json.user_attachments.find(a => a.file_type === 'video');
  const videoUrl = videoAttachment.data_url;
  
  // Gemini 2.0 Flash suporta vídeo!
  $json.video_url = videoUrl;
  $json.supports_video = true;
  
  if (!$json.user_message) {
    $json.user_message = 'Descreva o que acontece neste vídeo';
  }
  
  console.log('[VIDEO] Video analysis enabled');
}
```

**API:** Gemini 2.0 Flash (suporta vídeo até 10min)  
**Custo:** $0.075/1M tokens input  
**Formatos:** MP4, AVI, MOV, MKV

---

### 🔄 **BUILD VERTEX AI REQUEST (com mídia)**

```javascript
// Node: Build Vertex AI Request (WF0 Part 2)

const messages = $json.messages; // Do context builder
const userMessage = messages[messages.length - 1];

// Se tem imagem, adicionar ao payload
if ($json.supports_vision && $json.image_data) {
  userMessage.parts = [
    { text: $json.user_message },
    { 
      inlineData: {
        mimeType: $json.image_data.mimeType,
        data: $json.image_data.data
      }
    }
  ];
}

// Se tem vídeo, adicionar ao payload
if ($json.supports_video && $json.video_url) {
  // Upload vídeo para Cloud Storage primeiro
  const videoGcsUri = await uploadToGCS($json.video_url);
  
  userMessage.parts = [
    { text: $json.user_message },
    { 
      fileData: {
        mimeType: 'video/mp4',
        fileUri: videoGcsUri
      }
    }
  ];
}

return {
  contents: messages,
  systemInstruction: { parts: [{ text: $json.system_prompt }] },
  tools: $json.tools,
  generationConfig: $json.llm_config
};
```

---

## 🔴 4. PROCESSAMENTO DE MÍDIA - OUTPUT

### ❌ **STATUS ATUAL:**

Agente só envia **texto**. Tools de mídia documentadas mas não implementadas.

---

### ✅ **SOLUÇÃO: Implementar Tools de Mídia**

#### **A) image_generate (Imagen/DALL-E)**

```javascript
// Tool Definition
{
  "name": "image_generate",
  "description": "Gera uma imagem a partir de descrição textual. Use quando o usuário pedir para criar, desenhar ou mostrar algo visual.",
  "parameters": {
    "type": "object",
    "properties": {
      "prompt": {
        "type": "string",
        "description": "Descrição detalhada da imagem a gerar. Seja específico sobre estilo, cores, elementos."
      },
      "aspect_ratio": {
        "type": "string",
        "enum": ["1:1", "16:9", "9:16", "4:3"],
        "default": "1:1"
      }
    },
    "required": ["prompt"]
  }
}

// Implementação (WF0 Part 2)
async function executeImageGenerate(args, config) {
  const provider = config.image_gen_provider; // 'google' ou 'openai'
  
  if (provider === 'google') {
    // Vertex AI Imagen 3.0
    const response = await fetch(
      `https://us-central1-aiplatform.googleapis.com/v1/projects/${projectId}/locations/us-central1/publishers/google/models/imagen-3.0-generate-001:predict`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          instances: [{ prompt: args.prompt }],
          parameters: {
            sampleCount: 1,
            aspectRatio: args.aspect_ratio || '1:1'
          }
        })
      }
    );
    
    const data = await response.json();
    const imageBase64 = data.predictions[0].bytesBase64Encoded;
    
    // Upload para Supabase Storage
    const imageUrl = await uploadImageToStorage(imageBase64, config.client_id);
    
    return {
      tool: 'image_generate',
      result: {
        success: true,
        image_url: imageUrl,
        prompt: args.prompt
      },
      // Anexar para envio
      attachments: [{
        type: 'image',
        url: imageUrl,
        caption: args.prompt
      }]
    };
  }
}
```

**Custo:** 
- Imagen 3.0: $0.02/imagem
- DALL-E 3: $0.04/imagem (1024x1024)

---

#### **B) tts_generate (Text-to-Speech)**

```javascript
// Tool Definition
{
  "name": "tts_generate",
  "description": "Converte texto em áudio (mensagem de voz). Use quando o usuário preferir ouvir ou para mensagens longas.",
  "parameters": {
    "type": "object",
    "properties": {
      "text": {
        "type": "string",
        "description": "Texto para converter em áudio. Máximo 5000 caracteres."
      },
      "voice": {
        "type": "string",
        "enum": ["pt-BR-Standard-A", "pt-BR-Standard-B", "pt-BR-Neural2-A"],
        "default": "pt-BR-Neural2-A",
        "description": "Voz a usar (A=feminina, B=masculina)"
      }
    },
    "required": ["text"]
  }
}

// Implementação
async function executeTTS(args, config) {
  const response = await fetch(
    'https://texttospeech.googleapis.com/v1/text:synthesize',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        input: { text: args.text },
        voice: {
          languageCode: 'pt-BR',
          name: args.voice || 'pt-BR-Neural2-A'
        },
        audioConfig: {
          audioEncoding: 'OGG_OPUS',
          speakingRate: 1.0,
          pitch: 0.0
        }
      })
    }
  );
  
  const data = await response.json();
  const audioBase64 = data.audioContent;
  
  // Upload áudio
  const audioUrl = await uploadAudioToStorage(audioBase64, config.client_id);
  
  return {
    tool: 'tts_generate',
    result: {
      success: true,
      audio_url: audioUrl,
      text_length: args.text.length
    },
    attachments: [{
      type: 'audio',
      url: audioUrl
    }]
  };
}
```

**Custo:** Google TTS $4/1M caracteres

---

#### **C) Envio de Mídia via Chatwoot**

```javascript
// Node: Send Response (WF0 Part 3)

const response = $('Merge Final Response').item.json;
const hasAttachments = response.attachments && response.attachments.length > 0;

if (hasAttachments) {
  // Enviar cada anexo
  for (const attachment of response.attachments) {
    await fetch(
      `${chatwootHost}/api/v1/accounts/${accountId}/conversations/${conversationId}/messages`,
      {
        method: 'POST',
        headers: {
          'api_access_token': chatwootApiToken
        },
        body: createMultipartForm({
          content: attachment.caption || '',
          message_type: 'outgoing',
          private: false,
          attachments: [attachment.url]
        })
      }
    );
  }
}

// Enviar texto (se houver)
if (response.final_response) {
  await fetch(/*... enviar texto */);
}
```

---

## 🔴 5. WHATSAPP: MÚLTIPLOS PROVIDERS

### ❌ **PROBLEMA:** Só Evolution API documentado

---

### ✅ **SOLUÇÃO: Suporte a 3 Providers**

```sql
-- Adicionar à tabela clients
ALTER TABLE public.clients
  ADD COLUMN whatsapp_provider text DEFAULT 'evolution',
  ADD COLUMN whatsapp_config jsonb DEFAULT '{
    "provider": "evolution",
    "evolution": {
      "instance_name": null,
      "api_url": null,
      "token_vault_id": null
    },
    "meta_cloud": {
      "phone_number_id": null,
      "business_account_id": null,
      "access_token_vault_id": null
    },
    "twilio": {
      "account_sid": null,
      "auth_token_vault_id": null,
      "whatsapp_number": null
    }
  }'::jsonb;
```

**Providers:**
1. **Evolution API** (não-oficial, grátis)
2. **Meta Cloud API** (oficial, $0.0036/conversa)
3. **Twilio** (oficial BSP, $0.005/msg)

---

### 📝 **Documentação Meta Cloud API**

```markdown
## WhatsApp Business Cloud API (Meta - Oficial)

### Setup:
1. Criar Facebook Business Manager
2. Criar WhatsApp Business Account
3. Criar Meta App (tipo Business)
4. Adicionar WhatsApp Product
5. Configurar webhook
6. Verificar número

### Webhook (Incoming):
POST /webhook/chatwoot

Meta → Chatwoot → n8n (via Chatwoot inbox type WhatsApp)

### Send Message:
POST https://graph.facebook.com/v18.0/{phone_number_id}/messages

Headers:
  Authorization: Bearer {access_token}

Body:
{
  "messaging_product": "whatsapp",
  "to": "5521999999999",
  "type": "text",
  "text": {"body": "Resposta do agente"}
}

### Send Image:
{
  "messaging_product": "whatsapp",
  "to": "5521999999999",
  "type": "image",
  "image": {
    "link": "https://storage.../image.png",
    "caption": "Legenda"
  }
}

### Custos:
- 1.000 conversas grátis/mês
- Conversa Serviço: $0.0036
- Conversa Marketing: $0.0067
- Cobrado por sessão 24h
```

---

## 🔴 6. MULTI-TENANCY EXPLÍCITO

### ✅ **Adicionar Seção Dedicada no SUMARIO_EXECUTIVO.md**

```markdown
## 2.5 Arquitetura Multi-Tenant & Múltiplos Agentes

### Princípio Fundamental: N Clientes → M Agentes cada → 1 Infraestrutura

```
┌─────────────────────────────────────────────────────────────────┐
│                    INFRAESTRUTURA ÚNICA                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │   n8n    │  │ Supabase │  │  Redis   │  │ Chatwoot │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │  CLIENTE A  │    │  CLIENTE B  │    │  CLIENTE C  │
    │  acme-corp  │    │ dentista-sp │    │ loja-moda   │
    │             │    │             │    │             │
    │  3 Agentes: │    │  1 Agente:  │    │  2 Agentes: │
    │  - SDR      │    │  - Recepção │    │  - Vendas   │
    │  - Suporte  │    │             │    │  - Suporte  │
    │  - Cobrança │    │             │    │             │
    └─────────────┘    └─────────────┘    └─────────────┘
```

### Exemplos Reais:

**Cliente: Acme Corp (Software House)**
- Agente 1 "SDR": WhatsApp + Instagram → Qualifica leads → Tools: RAG, Calendar, CRM
- Agente 2 "Suporte": Chatwoot + Email → Tira dúvidas → Tools: RAG, Ticket System
- Agente 3 "Cobrança": WhatsApp → Cobra inadimplentes → Tools: RAG, Payments

**Cliente: Clínica Sorriso (Odontologia)**
- Agente 1 "Recepção": WhatsApp → Agenda consultas → Tools: RAG, Feegow

**Cliente: Loja Moda (E-commerce)**
- Agente 1 "Vendas": WhatsApp + Instagram → Vende produtos → Tools: RAG, Image Gen, Payments
- Agente 2 "SAC": Chatwoot → Pós-venda → Tools: RAG

### Zero Código para Novo Cliente/Agente:
1. INSERT em `clients` (conta)
2. INSERT em `agents` (quantos agentes quiser)
3. Upload RAG (base conhecimento)
4. Pronto! ✅
```

---

## 🔴 7. PLANO DE IMPLEMENTAÇÃO

### **Fase 1: Documentação (DIA 1-2) - 16h**

#### Dia 1 (8h):
1. ✅ Criar tabela `agents` no SUMARIO_EXECUTIVO.md (2h)
2. ✅ Migrar schema `clients` (remover campos de agente) (1h)
3. ✅ Documentar seção "Multi-Tenancy & Múltiplos Agentes" (2h)
4. ✅ Adicionar seção "Processamento de Mídia Input" completa (2h)
5. ✅ Adicionar seção "Processamento de Mídia Output" completa (1h)

#### Dia 2 (8h):
6. ✅ Documentar WhatsApp Meta Cloud API (2h)
7. ✅ Documentar Chatwoot Hub Central (setup completo) (3h)
8. ✅ Atualizar DIAGRAMS.md (Chatwoot hub + Multi-agent) (2h)
9. ✅ Atualizar workflows/*.md (1h)

---

### **Fase 2: Schema & SQL (DIA 3) - 8h**

10. ✅ Criar migration SQL completa:
    - CREATE TABLE agents
    - ALTER TABLE clients (remover campos)
    - ALTER TABLE rag_documents (add agent_id)
    - ALTER TABLE agent_executions (add agent_id)
    - ALTER TABLE channels (add assigned_agent_id)
    - Triggers para contador de agentes

11. ✅ Scripts de teste (INSERT exemplos)
12. ✅ Atualizar SETUP.md com novos passos

---

### **Fase 3: Workflows (DIA 4-7) - 32h**

13. ✅ WF0 Part 1 - Chatwoot-first:
    - Aceitar só webhook Chatwoot
    - Extrair client_id + agent_id
    - Load Agent Config (não client config)
    - Processar mídia input (áudio, imagem, doc)

14. ✅ WF0 Part 2 - Tools de Mídia:
    - Implementar image_generate
    - Implementar tts_generate
    - Atualizar Build Vertex AI para vision/video

15. ✅ WF0 Part 3 - Envio via Chatwoot:
    - Detectar attachments
    - Enviar mídia via Chatwoot API
    - Suportar múltiplos providers WhatsApp

16. ✅ Testes completos

---

### **Fase 4: Setup Chatwoot (DIA 8) - 8h**

17. ✅ Configurar Chatwoot em produção
18. ✅ Criar inboxes de exemplo
19. ✅ Testar todos os canais
20. ✅ Documentar troubleshooting

---

## 📊 RESUMO TOTAL

| Fase | Dias | Horas | Status |
|------|------|-------|--------|
| Documentação | 2 | 16h | 🟡 A fazer |
| Schema/SQL | 1 | 8h | 🟡 A fazer |
| Workflows | 4 | 32h | 🟡 A fazer |
| Setup Chatwoot | 1 | 8h | 🟡 A fazer |
| **TOTAL** | **8 dias** | **64h** | 🔴 Crítico |

---

**Autor:** GitHub Copilot  
**Data:** 06/11/2025  
**Versão:** 1.0

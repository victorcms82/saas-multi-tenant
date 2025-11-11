# 🔄 PLANEJAMENTO: LLM SWITCHER + SUPORTE A ÁUDIO

**Status:** 📝 Planning  
**Prioridade:** Alta (após validar migrations)  
**Impacto:** Permite usar Claude, Gemini, Llama, etc + WhatsApp Audio  

---

## 🎯 OBJETIVO

Tornar o workflow **agnóstico de LLM** e adicionar suporte a **mensagens de áudio** (entrada e saída).

---

## 🧠 PARTE 1: LLM SWITCHER

### **PROBLEMA ATUAL**

- Node "LLM (GPT-4o-mini + Tools)" está HARDCODED para OpenAI
- Para trocar para Claude/Gemini, precisa recriar workflow inteiro
- Credenciais específicas para cada provider
- Formato de resposta diferente por provider

### **SOLUÇÃO: Arquitetura Abstrata**

Criar camada de abstração que permite trocar LLM via **configuração no banco de dados**.

---

### **OPÇÃO A: Node HTTP Genérico + Adapter Pattern** ⭐ RECOMENDADO

**Vantagens:**
- ✅ Totalmente flexível (qualquer API REST)
- ✅ Fácil adicionar novos providers
- ✅ Customização total por cliente
- ✅ Suporta self-hosted models (Ollama, vLLM)

**Desvantagens:**
- ⚠️ Precisa escrever adapter para cada provider
- ⚠️ Mais trabalho inicial

**Arquitetura:**

```
agents table (adicionar colunas):
  - llm_provider (openai|anthropic|google|ollama|custom)
  - llm_api_url (URL customizável)
  - llm_api_key_ref (referência à credential)
  - llm_request_format (json template)
  - llm_response_path (jsonpath para extrair resposta)
```

**Exemplo de configuração:**

```json
// OpenAI
{
  "llm_provider": "openai",
  "llm_model": "gpt-4o-mini",
  "llm_api_url": "https://api.openai.com/v1/chat/completions",
  "llm_request_format": {
    "model": "{{ model }}",
    "messages": "{{ messages }}",
    "temperature": 0.7,
    "max_tokens": 1000
  },
  "llm_response_path": "$.choices[0].message.content"
}

// Anthropic Claude
{
  "llm_provider": "anthropic",
  "llm_model": "claude-3-5-sonnet-20241022",
  "llm_api_url": "https://api.anthropic.com/v1/messages",
  "llm_request_format": {
    "model": "{{ model }}",
    "messages": "{{ messages }}",
    "max_tokens": 1024,
    "system": "{{ system_prompt }}"
  },
  "llm_response_path": "$.content[0].text"
}

// Google Gemini
{
  "llm_provider": "google",
  "llm_model": "gemini-1.5-pro",
  "llm_api_url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent",
  "llm_request_format": {
    "contents": [
      {
        "parts": [{"text": "{{ prompt }}"}]
      }
    ],
    "generationConfig": {
      "temperature": 0.7,
      "maxOutputTokens": 1024
    }
  },
  "llm_response_path": "$.candidates[0].content.parts[0].text"
}

// Ollama (Self-hosted)
{
  "llm_provider": "ollama",
  "llm_model": "llama3.2",
  "llm_api_url": "http://localhost:11434/api/chat",
  "llm_request_format": {
    "model": "{{ model }}",
    "messages": "{{ messages }}",
    "stream": false
  },
  "llm_response_path": "$.message.content"
}
```

**Implementação no n8n:**

```javascript
// Node: "Preparar Request LLM (Dinâmico)"
const agentConfig = $json; // Vem do banco: agents table

// Buscar configuração do provider
const provider = agentConfig.llm_provider || 'openai';
const apiUrl = agentConfig.llm_api_url;
const requestTemplate = agentConfig.llm_request_format;
const responsePath = agentConfig.llm_response_path;

// Preparar mensagens no formato do provider
let messages = [];
if (provider === 'openai' || provider === 'anthropic') {
  messages = [
    { role: 'system', content: $json.system_prompt },
    { role: 'user', content: $json.message_body }
  ];
} else if (provider === 'google') {
  // Gemini usa formato diferente
  messages = [{
    parts: [{ text: $json.system_prompt + '\n\n' + $json.message_body }]
  }];
}

// Substituir placeholders no template
let requestBody = JSON.parse(JSON.stringify(requestTemplate));
requestBody = JSON.stringify(requestBody)
  .replace('"{{ model }}"', `"${agentConfig.llm_model}"`)
  .replace('"{{ messages }}"', JSON.stringify(messages))
  .replace('"{{ system_prompt }}"', `"${$json.system_prompt}"`)
  .replace('"{{ prompt }}"', `"${$json.system_prompt}\n\n${$json.message_body}"`);
requestBody = JSON.parse(requestBody);

return {
  json: {
    ...$json,
    llm_api_url: apiUrl,
    llm_request_body: requestBody,
    llm_response_path: responsePath
  }
};
```

```javascript
// Node: "Chamar LLM (HTTP Request Genérico)"
// Configurar HTTP Request node:
// - URL: {{ $json.llm_api_url }}
// - Body: {{ $json.llm_request_body }}
// - Headers: Usar credential baseado em llm_provider
```

```javascript
// Node: "Extrair Resposta LLM (Dinâmico)"
const response = $json;
const responsePath = $('Preparar Request LLM').first().json.llm_response_path;

// Usar JSONPath para extrair resposta
const jp = require('jsonpath');
const llmResponse = jp.query(response, responsePath)[0];

return {
  json: {
    ...($('Preparar Request LLM').first().json),
    llm_raw_response: response,
    final_response: llmResponse || 'Desculpe, não consegui processar sua mensagem.'
  }
};
```

---

### **OPÇÃO B: Nodes Específicos (n8n native)** ⚠️ Limitado

**Vantagens:**
- ✅ Pré-configurado (menos código)
- ✅ UI amigável

**Desvantagens:**
- ❌ Precisa de credential para CADA provider
- ❌ Limitado aos providers suportados pelo n8n
- ❌ Menos flexibilidade
- ❌ Não suporta self-hosted models

**Implementação:**
- Substituir "LLM (GPT-4o-mini + Tools)" por IF node
- Branch por `llm_provider`:
  - `openai` → OpenAI node
  - `anthropic` → HTTP Request (Anthropic API)
  - `google` → HTTP Request (Gemini API)
  - `ollama` → HTTP Request (localhost)

**Problema:** Muita duplicação. Cada branch precisa replicar lógica.

---

### **DECISÃO RECOMENDADA:**

✅ **OPÇÃO A: HTTP Genérico + Adapter Pattern**

**Razão:**
- Escalável (adicionar novo provider = inserir config no banco)
- Funciona com qualquer API (incluindo APIs proprietárias)
- Suporta modelos locais (Ollama, vLLM, LM Studio)
- Menos manutenção (1 node para TODOS os providers)

---

### **MIGRATION NECESSÁRIA: 013_add_llm_config_to_agents.sql**

```sql
ALTER TABLE agents
ADD COLUMN llm_provider VARCHAR(50) DEFAULT 'openai',
ADD COLUMN llm_api_url TEXT,
ADD COLUMN llm_api_key_ref VARCHAR(255), -- Referência à credential ou env var
ADD COLUMN llm_request_format JSONB DEFAULT '{}'::JSONB,
ADD COLUMN llm_response_path VARCHAR(255) DEFAULT '$.choices[0].message.content',
ADD COLUMN llm_temperature DECIMAL(3, 2) DEFAULT 0.7,
ADD COLUMN llm_max_tokens INT DEFAULT 1000,
ADD COLUMN llm_timeout_seconds INT DEFAULT 30;

-- Índice para busca por provider
CREATE INDEX idx_agents_llm_provider ON agents(llm_provider);

-- Constraint para validar provider conhecido
ALTER TABLE agents
ADD CONSTRAINT valid_llm_provider CHECK (
  llm_provider IN ('openai', 'anthropic', 'google', 'ollama', 'azure', 'cohere', 'custom')
);

-- Atualizar agentes existentes com configuração OpenAI
UPDATE agents
SET 
  llm_provider = 'openai',
  llm_api_url = 'https://api.openai.com/v1/chat/completions',
  llm_request_format = '{
    "model": "{{ model }}",
    "messages": "{{ messages }}",
    "temperature": 0.7,
    "max_tokens": 1000
  }'::JSONB,
  llm_response_path = '$.choices[0].message.content'
WHERE llm_provider IS NULL;
```

---

### **PROVIDERS SUPORTADOS:**

| Provider | API URL | Model Examples | Pricing (1M tokens) |
|----------|---------|----------------|---------------------|
| OpenAI | `api.openai.com/v1/chat/completions` | gpt-4o, gpt-4o-mini | $2.50 - $15 |
| Anthropic | `api.anthropic.com/v1/messages` | claude-3-5-sonnet, claude-3-opus | $3 - $15 |
| Google | `generativelanguage.googleapis.com/v1beta/models/*/generateContent` | gemini-1.5-pro, gemini-1.5-flash | $1.25 - $7.50 |
| Ollama | `localhost:11434/api/chat` | llama3.2, mistral, phi | FREE (self-hosted) |
| Azure OpenAI | `*.openai.azure.com/openai/deployments/*/chat/completions` | Custom deployments | Variable |
| Cohere | `api.cohere.ai/v1/chat` | command-r, command-r-plus | $0.50 - $3 |

---

## 🎤 PARTE 2: SUPORTE A ÁUDIO

### **CASOS DE USO**

1. **Entrada de áudio (Speech-to-Text):**
   - Usuário envia nota de voz no WhatsApp
   - Bot transcreve → Processa como texto normal
   - Responde com texto ou áudio

2. **Saída de áudio (Text-to-Speech):**
   - Bot gera resposta em texto
   - Converte para áudio
   - Envia áudio de volta no WhatsApp

---

### **ARQUITETURA: Entrada de Áudio (Speech-to-Text)**

```
Chatwoot Webhook (attachment.content_type = 'audio/ogg')
  ↓
Node: Tem Áudio? (IF)
  ├─→ SIM:
  │     ↓
  │   Node: Download Áudio do Chatwoot (HTTP)
  │     ↓
  │   Node: Transcrever Áudio (Whisper API)
  │     ↓
  │   Node: Substituir message_body por transcrição
  │     ↓
  └─→ Workflow normal (LLM, etc)
```

**Implementação:**

```javascript
// Node: Tem Áudio?
const attachments = $json.attachments || [];
const hasAudio = attachments.some(att => 
  att.file_type === 'audio' || 
  att.data_url?.includes('.ogg') || 
  att.data_url?.includes('.mp3')
);

return {
  json: {
    ...$json,
    has_audio: hasAudio,
    audio_url: hasAudio ? attachments.find(a => a.file_type === 'audio')?.data_url : null
  }
};
```

```javascript
// Node: Transcrever Áudio (OpenAI Whisper)
// HTTP Request:
// POST https://api.openai.com/v1/audio/transcriptions
// Body (multipart/form-data):
//   - file: (binary do áudio)
//   - model: "whisper-1"
//   - language: "pt"
//   - response_format: "json"

const response = $json;
const transcription = response.text;

return {
  json: {
    ...($('Identificar Cliente e Agente').first().json),
    message_body: transcription, // ✅ SUBSTITUIR message_body original
    original_message_body: $json.message_body,
    was_audio: true,
    audio_transcription: transcription
  }
};
```

**APIs disponíveis para STT:**

| Provider | API | Idiomas | Preço (1h áudio) | Qualidade |
|----------|-----|---------|------------------|-----------|
| OpenAI Whisper | `api.openai.com/v1/audio/transcriptions` | 99 idiomas | $0.36 | ⭐⭐⭐⭐⭐ |
| Google Speech-to-Text | `speech.googleapis.com/v1/speech:recognize` | 125 idiomas | $0.24 - $2.88 | ⭐⭐⭐⭐ |
| Azure Speech | `*.cognitiveservices.azure.com/sts/v1.0/issuetoken` | 100+ idiomas | $1.00 | ⭐⭐⭐⭐ |
| AssemblyAI | `api.assemblyai.com/v2/transcript` | Inglês + | $0.25 | ⭐⭐⭐⭐ |

**Recomendação:** OpenAI Whisper (melhor custo-benefício + qualidade)

---

### **ARQUITETURA: Saída de Áudio (Text-to-Speech)**

```
Construir Resposta Final (texto)
  ↓
Node: Cliente quer áudio? (IF)
  - Verificar: agents.audio_response_enabled = true
  - OU: Detectar se mensagem original era áudio
  ├─→ SIM:
  │     ↓
  │   Node: Gerar Áudio (TTS API)
  │     ↓
  │   Node: Upload Áudio para Supabase Storage
  │     ↓
  │   Node: Enviar Áudio via Chatwoot (attachment)
  │     ↓
  └─→ NÃO: Enviar texto normalmente
```

**Implementação:**

```javascript
// Node: Cliente quer áudio?
const agentConfig = $('Buscar Dados do Agente').first().json;
const wasOriginallyAudio = $json.was_audio || false;

const sendAudioResponse = 
  agentConfig.audio_response_enabled === true || 
  wasOriginallyAudio === true;

return {
  json: {
    ...$json,
    send_audio_response: sendAudioResponse
  }
};
```

```javascript
// Node: Gerar Áudio (OpenAI TTS)
// HTTP Request:
// POST https://api.openai.com/v1/audio/speech
// Body (JSON):
//   {
//     "model": "tts-1",
//     "voice": "nova",  // Opções: alloy, echo, fable, onyx, nova, shimmer
//     "input": "{{ $json.final_response }}",
//     "response_format": "mp3",
//     "speed": 1.0
//   }
// Options → Response → Response Format: "file"

// Response será binary (arquivo MP3)
```

```javascript
// Node: Upload Áudio para Supabase Storage
// HTTP Request (PUT):
// URL: https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/audio-responses/{{ $json.client_id }}/{{ timestamp }}.mp3
// Body: Binary data do audio
// Headers:
//   - Authorization: Bearer SERVICE_ROLE_KEY
//   - Content-Type: audio/mpeg

const uploadUrl = `https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/audio-responses/${$json.client_id}/${Date.now()}.mp3`;

return {
  json: {
    ...$json,
    audio_url: uploadUrl
  }
};
```

```javascript
// Node: Enviar Áudio via Chatwoot
// Mesmo processo de "Upload Anexo para Chatwoot"
// Usar audio_url como arquivo
```

**APIs disponíveis para TTS:**

| Provider | API | Vozes PT-BR | Preço (1M chars) | Qualidade |
|----------|-----|-------------|------------------|-----------|
| OpenAI TTS | `api.openai.com/v1/audio/speech` | 6 vozes (neutras) | $15.00 | ⭐⭐⭐⭐⭐ |
| Google Cloud TTS | `texttospeech.googleapis.com/v1/text:synthesize` | 20+ vozes PT-BR | $4.00 - $16.00 | ⭐⭐⭐⭐ |
| Azure TTS | `*.tts.speech.microsoft.com/cognitiveservices/v1` | 15+ vozes PT-BR | $4.00 - $16.00 | ⭐⭐⭐⭐⭐ |
| ElevenLabs | `api.elevenlabs.io/v1/text-to-speech` | Vozes customizáveis | $22.00 - $99.00 | ⭐⭐⭐⭐⭐ |

**Recomendação:** OpenAI TTS (melhor custo + integração simples)

---

### **MIGRATION NECESSÁRIA: 014_add_audio_config_to_agents.sql**

```sql
ALTER TABLE agents
ADD COLUMN audio_response_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN audio_voice VARCHAR(50) DEFAULT 'nova', -- OpenAI TTS voice
ADD COLUMN audio_language VARCHAR(10) DEFAULT 'pt',
ADD COLUMN audio_speed DECIMAL(3, 2) DEFAULT 1.0,
ADD COLUMN stt_provider VARCHAR(50) DEFAULT 'openai_whisper',
ADD COLUMN tts_provider VARCHAR(50) DEFAULT 'openai_tts';

COMMENT ON COLUMN agents.audio_response_enabled IS 'Se TRUE, bot responde em áudio automaticamente';
COMMENT ON COLUMN agents.audio_voice IS 'Voz do TTS: alloy, echo, fable, onyx, nova, shimmer (OpenAI)';
COMMENT ON COLUMN agents.stt_provider IS 'Speech-to-Text provider: openai_whisper, google, azure';
COMMENT ON COLUMN agents.tts_provider IS 'Text-to-Speech provider: openai_tts, google, azure, elevenlabs';
```

---

## 📋 ROADMAP DE IMPLEMENTAÇÃO

### **Fase 1: LLM Switcher** (2-3 dias)

1. ✅ Criar migration 013 (add llm_config columns)
2. ✅ Atualizar node "Preparar Request LLM" (adicionar lógica de adapter)
3. ✅ Substituir "LLM (GPT-4o-mini + Tools)" por "Chamar LLM (HTTP Genérico)"
4. ✅ Adicionar node "Extrair Resposta LLM (JSONPath)"
5. ✅ Testar com OpenAI (baseline)
6. ✅ Testar com Anthropic Claude
7. ✅ Testar com Google Gemini
8. ✅ Documentar: Como adicionar novo provider

### **Fase 2: Áudio - Entrada (STT)** (1-2 dias)

1. ✅ Adicionar node "Tem Áudio?" (IF após "Identificar Cliente e Agente")
2. ✅ Adicionar node "Download Áudio" (HTTP → Chatwoot attachment URL)
3. ✅ Adicionar node "Transcrever Áudio" (OpenAI Whisper API)
4. ✅ Atualizar node "Identificar Cliente e Agente" (detectar audio attachments)
5. ✅ Testar com nota de voz real no WhatsApp

### **Fase 3: Áudio - Saída (TTS)** (1-2 dias)

1. ✅ Criar migration 014 (add audio_config columns)
2. ✅ Adicionar node "Cliente quer áudio?" (IF após "Construir Resposta Final")
3. ✅ Adicionar node "Gerar Áudio" (OpenAI TTS API)
4. ✅ Adicionar node "Upload Áudio Storage" (Supabase)
5. ✅ Atualizar node "Enviar via Chatwoot" (suporte a áudio)
6. ✅ Testar recebimento de áudio no WhatsApp

---

## 🎯 PRIORIDADE DE IMPLEMENTAÇÃO

**IMEDIATO (Após validar migrations 011-012):**
1. LLM Switcher (Fase 1) - Permite Claude/Gemini HOJE
2. Áudio STT (Fase 2) - Usuários já enviam áudios

**MÉDIO PRAZO:**
3. Áudio TTS (Fase 3) - Diferencial competitivo

---

## 💡 CASOS DE USO REAIS

### **LLM Switcher:**
- Cliente quer usar Claude 3.5 Sonnet (melhor para textos longos)
- Cliente quer usar Gemini 1.5 Pro (grátis até certo limite)
- Cliente quer usar Llama 3.2 local (privacidade total)

### **Áudio:**
- Idosos preferem falar (não digitam bem)
- Motoristas não podem digitar (mãos ocupadas)
- Acessibilidade (deficientes visuais)
- Vendedores externos (enviam áudios rápidos)

---

**✅ Planejamento completo! Pronto para implementar!** 🚀

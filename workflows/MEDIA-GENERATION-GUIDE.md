# 🎨 Geração de Mídia pelo Agente - Guia Completo

## 🎯 Visão Geral

O agente agora pode **gerar e enviar mídia automaticamente** usando tags especiais na resposta do LLM.

---

## 📋 Tipos de Mídia Suportados

### 1. 🎨 Imagens (DALL-E 3)

**Como usar:**
```
LLM responde: "Claro! [GERAR_IMAGEM: logo moderno para clínica odontológica com cores azul e branco]"
```

**O que acontece:**
1. Workflow detecta tag `[GERAR_IMAGEM:...]`
2. Extrai prompt: "logo moderno para clínica odontológica com cores azul e branco"
3. Chama DALL-E 3 API
4. Recebe URL da imagem gerada
5. Faz upload para Supabase Storage: `/client-media/{client_id}/generated-images/`
6. Remove tag da resposta
7. Envia mensagem via Chatwoot com imagem anexada

**Custos:**
- Standard (1024x1024): $0.04/imagem
- HD (1024x1024): $0.08/imagem
- Standard (1792x1024): $0.08/imagem

**Configuração:**
```javascript
// Node: Gerar Imagem (DALL-E 3)
const imagePrompt = match[1]; // Extraído da tag

// Chamar OpenAI DALL-E 3
const response = await openai.images.generate({
  model: "dall-e-3",
  prompt: imagePrompt,
  n: 1,
  size: "1024x1024",
  quality: "standard" // ou "hd"
});

const imageUrl = response.data[0].url;
```

---

### 2. 🎤 Áudios (OpenAI TTS)

**Como usar:**
```
LLM responde: "[GERAR_AUDIO: Olá! Sua consulta foi confirmada para amanhã às 14h. Até lá!]"
```

**O que acontece:**
1. Workflow detecta tag `[GERAR_AUDIO:...]`
2. Extrai texto: "Olá! Sua consulta foi confirmada..."
3. Chama OpenAI TTS API
4. Recebe arquivo MP3 gerado
5. Upload para Supabase Storage: `/client-media/{client_id}/generated-audios/`
6. Remove tag da resposta
7. Envia mensagem de áudio via Chatwoot

**Custos:**
- $0.015 por 1.000 caracteres
- Exemplo: 100 chars = $0.0015

**Vozes disponíveis:**
- `alloy` - Neutro, versátil
- `echo` - Masculino, claro
- `fable` - Britânico, narrativo
- `onyx` - Masculino, autoritário
- `nova` - Feminino, jovem (⭐ recomendado)
- `shimmer` - Feminino, suave

**Configuração:**
```javascript
// Node: Gerar Áudio (TTS)
const audioText = match[1]; // Extraído da tag

const mp3 = await openai.audio.speech.create({
  model: "tts-1", // ou "tts-1-hd" (melhor qualidade)
  voice: "nova",
  input: audioText,
  speed: 1.0 // 0.25 a 4.0
});

const buffer = Buffer.from(await mp3.arrayBuffer());
// Upload buffer para Supabase Storage
```

---

### 3. 📄 Documentos PDF (Puppeteer)

**Como usar:**
```
LLM responde: "[GERAR_DOCUMENTO: relatorio] Aqui está o resumo..."
```

**Tipos suportados:**
- `relatorio` - Relatório executivo
- `proposta` - Proposta comercial
- `contrato` - Contrato de serviço
- `orcamento` - Orçamento detalhado
- `atestado` - Atestado médico/odontológico

**O que acontece:**
1. Workflow detecta tag `[GERAR_DOCUMENTO:tipo]`
2. Extrai tipo: "relatorio"
3. Carrega template HTML do tipo
4. Preenche com dados do contexto
5. Gera PDF com Puppeteer
6. Upload para Supabase Storage: `/client-media/{client_id}/generated-documents/`
7. Remove tag da resposta
8. Envia PDF via Chatwoot

**Custos:**
- $0 (processamento local)
- Apenas custo de storage (Supabase: $0.021/GB/mês)

**Configuração:**
```javascript
// Node: Gerar Documento (PDF)
const docType = match[1]; // "relatorio", "proposta", etc

const browser = await puppeteer.launch();
const page = await browser.newPage();

// Carregar template
const htmlContent = await loadTemplate(docType, contextData);
await page.setContent(htmlContent);

// Gerar PDF
const pdf = await page.pdf({
  format: 'A4',
  printBackground: true,
  margin: { top: '20px', bottom: '20px' }
});

await browser.close();
// Upload PDF para Supabase Storage
```

---

## 🗂️ Storage no Supabase

### Estrutura de Pastas

```
client-media/
├── {client_id}/
│   ├── generated-images/
│   │   ├── 2025-11-06-logo-clinica.png
│   │   ├── 2025-11-07-banner-promo.jpg
│   │   └── 2025-11-08-infografico.png
│   ├── generated-audios/
│   │   ├── 2025-11-06-confirmacao.mp3
│   │   ├── 2025-11-07-lembrete.mp3
│   │   └── 2025-11-08-aviso.mp3
│   └── generated-documents/
│       ├── 2025-11-06-relatorio.pdf
│       ├── 2025-11-07-proposta.pdf
│       └── 2025-11-08-orcamento.pdf
```

### Configurar Bucket no Supabase

```sql
-- 1. Criar bucket (via Supabase Dashboard ou SQL)
INSERT INTO storage.buckets (id, name, public)
VALUES ('client-media', 'client-media', true);

-- 2. Configurar políticas de acesso
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'client-media');

CREATE POLICY "Authenticated upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'client-media' AND auth.role() = 'authenticated');
```

### Upload via n8n

```javascript
// Node: Upload para Supabase Storage
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const fileName = `${clientId}/generated-images/${Date.now()}-logo.png`;

const { data, error } = await supabase.storage
  .from('client-media')
  .upload(fileName, imageBuffer, {
    contentType: 'image/png',
    cacheControl: '3600'
  });

const publicURL = supabase.storage
  .from('client-media')
  .getPublicUrl(fileName).data.publicUrl;
```

---

## 📊 Tracking de Uso

### Campos no DB (Migration 004)

```sql
ALTER TABLE client_subscriptions
ADD COLUMN images_generated INTEGER DEFAULT 0,
ADD COLUMN audios_generated INTEGER DEFAULT 0,
ADD COLUMN documents_generated INTEGER DEFAULT 0,
ADD COLUMN media_generation_cost_usd DECIMAL(10,4) DEFAULT 0;
```

### Update Automático no Workflow

```sql
-- Node: Atualizar Usage Tracking
UPDATE client_subscriptions
SET 
  images_generated = images_generated + {{generated_images.length}},
  audios_generated = audios_generated + {{generated_audios.length}},
  documents_generated = documents_generated + {{generated_documents.length}},
  media_generation_cost_usd = media_generation_cost_usd + {{total_media_cost}}
WHERE client_id = '{{client_id}}' AND agent_id = '{{agent_id}}';
```

### Consultar Uso

```sql
-- Ver uso de mídia gerada por cliente
SELECT 
  client_id,
  images_generated,
  audios_generated,
  documents_generated,
  media_generation_cost_usd,
  ROUND(media_generation_cost_usd * 5.33, 2) as custo_brl
FROM client_subscriptions
WHERE client_id = 'clinica_sorriso_001';

-- Profitability incluindo custos de mídia
SELECT * FROM v_template_profitability_complete;
```

---

## 💰 Cálculo de Custos

### Exemplo 1: Logo + Confirmação

**Cliente pergunta:** "Crie um logo para minha clínica e me envie um áudio confirmando"

**LLM responde:**
```
Claro! Vou criar um logo moderno para você.
[GERAR_IMAGEM: logo clínica odontológica moderna, cores azul e branco, minimalista]
[GERAR_AUDIO: Olá! O logo da sua clínica foi criado com sucesso. Acabei de enviar para você. Espero que goste!]
```

**Custos:**
- LLM (200 tokens): $0.0002
- DALL-E 3 (1 imagem): $0.04
- OpenAI TTS (95 chars): $0.0014
- RAG: $0.0001
- **Total: $0.0417 (~R$0.22)**

### Exemplo 2: Relatório Mensal

**Cliente:** "Me envie um relatório do mês em PDF"

**LLM:**
```
[GERAR_DOCUMENTO: relatorio]
Segue o relatório completo de novembro...
```

**Custos:**
- LLM: $0.0003
- PDF generation: $0
- **Total: $0.0003 (~R$0.002)**

### Impacto na Margem

Plano SDR Starter (R$697/mês):
- Margem sem mídia: 98.94%
- Com 10 imagens/mês: 98.64%
- Com 50 imagens/mês: 97.09%
- **Ainda altamente lucrativo!**

---

## 🎯 Casos de Uso

### 1. Clínicas Odontológicas
```
Cliente: "Crie um banner para Instagram sobre clareamento"
LLM: [GERAR_IMAGEM: banner Instagram clareamento dental, antes e depois, cores azul]
```

### 2. Agendamentos
```
Cliente agenda consulta
LLM: [GERAR_AUDIO: Sua consulta foi agendada para dia 15 às 14h. Até lá!]
```

### 3. Propostas Comerciais
```
Cliente: "Me envie uma proposta do pacote premium"
LLM: [GERAR_DOCUMENTO: proposta] Segue a proposta detalhada...
```

### 4. Treinamentos
```
Cliente: "Explique o procedimento de canal"
LLM: Vou te explicar... [GERAR_IMAGEM: diagrama procedimento canal dentário, passo a passo]
```

---

## 🚀 Ativação

### 1. Configurar APIs

```bash
# .env
OPENAI_API_KEY=sk-...
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbG...
```

### 2. Criar Bucket Supabase

```sql
-- Via Supabase Dashboard:
Storage → New Bucket → "client-media" → Public
```

### 3. Executar Migration 004

```bash
# Supabase SQL Editor
\i database/migrations/004_add_media_generation_tracking.sql
```

### 4. Configurar Prompt do LLM

Adicionar no system prompt:

```
Você pode gerar mídia usando estas tags:

[GERAR_IMAGEM: descrição detalhada da imagem]
Exemplo: [GERAR_IMAGEM: logo moderno para clínica, cores azul e branco]

[GERAR_AUDIO: texto para áudio]
Exemplo: [GERAR_AUDIO: Olá! Sua consulta foi confirmada]

[GERAR_DOCUMENTO: tipo]
Tipos: relatorio, proposta, contrato, orcamento
Exemplo: [GERAR_DOCUMENTO: relatorio]

Use quando apropriado para melhorar a experiência do cliente.
```

---

## ✅ Checklist

- [x] Migration 004 executada
- [x] Bucket "client-media" criado no Supabase
- [x] OpenAI API key configurada
- [x] Supabase credentials no n8n
- [x] System prompt atualizado
- [ ] Testar geração de imagem
- [ ] Testar geração de áudio
- [ ] Testar geração de PDF
- [ ] Validar upload no storage
- [ ] Confirmar tracking no DB

---

**Status**: ✅ Implementado | ⏳ Aguardando testes em produção
**Commit**: e66cd4a
**Nodes**: 36 total (+6 para geração de mídia)

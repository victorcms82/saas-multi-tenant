# 📘 GUIA DE REPLICAÇÃO DO WORKFLOW BASE (WF0)

**Versão:** 1.0 (Validada)  
**Status:** ✅ Produção - 100% Funcional  
**Validado em:** Clínica Sorriso (clinica_sorriso_001)  
**Autor:** Victor + GitHub Copilot  
**Data:** 11/11/2025  

---

## 🎯 O QUE É ESTE TEMPLATE?

Este é o **workflow base validado** para criar agentes conversacionais multi-tenant com:

✅ **WhatsApp via Chatwoot** (integração completa)  
✅ **OpenAI GPT-4o-mini** (LLM com tools)  
✅ **Envio dinâmico de mídia** (fotos, PDFs, vídeos via triggers)  
✅ **Multi-tenancy** (isolamento total por client_id + agent_id)  
✅ **RAG preparado** (namespace isolado - pronto para Pinecone/Qdrant)  
✅ **Usage tracking** (controle de uso por assinatura)  
✅ **Error handling** (tratamento de erros com fallback)  

---

## 📊 ARQUITETURA DO WORKFLOW

### Fluxo de Dados (27 Nodes)

```
1. Chatwoot Webhook (recebe mensagem)
   ↓
2. Identificar Cliente e Agente (extrai client_id, agent_id, message_body)
   ↓
3. Filtrar Apenas Incoming (bloqueia outgoing/activity)
   ↓
   ├─→ 4. Buscar Dados do Agente (HTTP → Supabase)
   │      ↓
   │    6. Merge: Agente + Mídia (Input 1)
   │      ↓
   └─→ 5. Buscar Mídia Triggers (RPC → check_media_triggers)
          ↓
        6. Merge: Agente + Mídia (Input 2)
          ↓
7. Construir Contexto Completo (combina agente + mídia + webhook)
   ↓
8. Query RAG (Namespace Isolado) - PLACEHOLDER
   ↓
9. Preparar Prompt LLM (system_prompt + media_context + message)
   ↓
10. LLM (GPT-4o-mini + Tools) - OpenAI API
   ↓
11. Preservar Contexto Após LLM
   ↓
12. Chamou Tool? (IF)
   ├─→ SIM: 13. Executar Tools (calendar, sheets, etc)
   │           ↓
   └─→ NÃO: 14. Construir Resposta Final
                ↓
15. Tem Mídia do Acervo? (IF)
   ├─→ SIM: 16. Registrar Log de Envio (HTTP → media_send_log)
   │           ↓
   │         17. Preservar Dados Após Log
   │           ↓
   └─→ 18. Atualizar Usage Tracking (HTTP → client_subscriptions)
          ↓
19. Preservar Dados Após Usage Tracking
   ↓
20. Enviar Resposta via Chatwoot (HTTP POST → /messages)
   ↓
21. Log Chatwoot Response
   ↓
22. Tem Anexos? (IF)
   ├─→ SIM: 23. Download Arquivo do Supabase (HTTP GET)
   │           ↓
   │         24. Upload Anexo para Chatwoot (multipart/form-data)
   │
   └─→ NÃO: (fim)

ERROR BRANCH:
   → 25. Error Handler (captura erros e envia mensagem padrão)
```

---

## 🔧 COMO REPLICAR (PASSO A PASSO)

### **PRÉ-REQUISITOS**

1. ✅ **Supabase:**
   - Tabelas: `clients`, `agents`, `client_subscriptions`, `client_media`, `client_media_rules`, `media_send_log`
   - RPC: `check_media_triggers(p_client_id, p_agent_id, p_message)`
   - Storage: Bucket público para arquivos

2. ✅ **Chatwoot:**
   - Conta configurada
   - Inbox WhatsApp criado
   - API Access Token gerado
   - Webhook configurado para n8n

3. ✅ **OpenAI:**
   - API Key válida
   - Acesso ao modelo `gpt-4o-mini` (ou `gpt-4o`)

4. ✅ **n8n:**
   - Instância rodando (self-hosted ou cloud)
   - Credenciais configuradas (próximo passo)

---

### **PASSO 1: CONFIGURAR CREDENCIAIS NO N8N**

#### 1.1 **Supabase API** (HTTP Custom Auth)

**Name:** `Supabase API`  
**Credential ID:** `NEn6NpNWjE7hCyWQ` *(você terá um ID diferente)*

**Authentication Method:** Custom Auth  
**Headers:**
```json
{
  "apikey": "SEU_SUPABASE_ANON_KEY",
  "Authorization": "Bearer SEU_SUPABASE_ANON_KEY"
}
```

**Onde encontrar:**
- Supabase Dashboard → Settings → API
- Copiar: `anon` `public` key

---

#### 1.2 **Chatwoot Header Auth**

**Name:** `Chatwoot Header Auth`  
**Credential ID:** `6zb8BvpL6QTY95dP` *(você terá um ID diferente)*

**Authentication Method:** Header Auth  
**Name:** `api_access_token`  
**Value:** `SEU_CHATWOOT_API_TOKEN`

**Onde encontrar:**
- Chatwoot → Profile Settings → Access Token
- Gerar novo token se necessário

---

#### 1.3 **OpenAI API**

**Name:** `OpenAi account`  
**Credential ID:** `AZOIk8m4dEU8S2FP` *(você terá um ID diferente)*

**API Key:** `sk-proj-...SEU_OPENAI_KEY...`

**Onde encontrar:**
- https://platform.openai.com/api-keys
- Gerar nova chave se necessário

---

### **PASSO 2: IMPORTAR WORKFLOW NO N8N**

1. Copiar conteúdo de `WF0-TEMPLATE-BASE-VALIDATED.json`
2. n8n → Workflows → **Import from File** (ou Ctrl+O)
3. Colar JSON completo
4. Salvar workflow

**⚠️ IMPORTANTE:** Após importar, os IDs de credenciais estarão quebrados! Você precisará reconectá-las.

---

### **PASSO 3: RECONECTAR CREDENCIAIS**

**Nodes que precisam de credenciais:**

| Node | Credencial | Tipo |
|------|-----------|------|
| Buscar Dados do Agente (HTTP) | Supabase API | HTTP Custom Auth |
| Buscar Mídia Triggers (RPC) | Supabase API | HTTP Custom Auth |
| Registrar Log de Envio (HTTP) | Supabase API | HTTP Custom Auth |
| Atualizar Usage Tracking (HTTP) | Supabase API | HTTP Custom Auth |
| Enviar Resposta via Chatwoot | Chatwoot Header Auth | Header Auth |
| Upload Anexo para Chatwoot | *(hardcoded header)* | - |
| LLM (GPT-4o-mini + Tools) | OpenAi account | OpenAI API |

**Como reconectar:**
1. Clicar no node
2. Painel lateral → Credentials
3. Selecionar credencial existente (ou criar nova)
4. Testar conexão

---

### **PASSO 4: PERSONALIZAR URLs**

**⚠️ CRÍTICO:** Substituir URLs hardcoded pelas suas!

#### 4.1 **Supabase URL** (4 nodes)

**Buscar Dados do Agente (HTTP):**
```
https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/agents
                ↓
https://SEU_PROJECT_ID.supabase.co/rest/v1/agents
```

**Buscar Mídia Triggers (RPC):**
```
https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/check_media_triggers
                ↓
https://SEU_PROJECT_ID.supabase.co/rest/v1/rpc/check_media_triggers
```

**Registrar Log de Envio (HTTP):**
```
https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/media_send_log
                ↓
https://SEU_PROJECT_ID.supabase.co/rest/v1/media_send_log
```

**Atualizar Usage Tracking (HTTP):**
```
https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/client_subscriptions
                ↓
https://SEU_PROJECT_ID.supabase.co/rest/v1/client_subscriptions
```

---

#### 4.2 **Chatwoot URL** (2 nodes)

**Enviar Resposta via Chatwoot:**
```
https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}/messages
                ↓
https://SEU_CHATWOOT_DOMAIN/api/v1/accounts/SEU_ACCOUNT_ID/conversations/{{ $json.conversation_id }}/messages
```

**Upload Anexo para Chatwoot:**
```
(mesma URL acima)
```

**Como encontrar `account_id`:**
- Chatwoot → Settings → Account → ID na URL

---

#### 4.3 **Webhook URL** (node inicial)

**Chatwoot Webhook:**
- Path: `chatwoot-webhook`
- Webhook URL será: `https://SEU_N8N_DOMAIN/webhook/chatwoot-webhook`

**Configurar no Chatwoot:**
1. Chatwoot → Settings → Integrations → Webhooks
2. Add Webhook
3. URL: `https://SEU_N8N_DOMAIN/webhook/chatwoot-webhook`
4. Events: ✅ `message_created`
5. Salvar

---

### **PASSO 5: AJUSTAR LÓGICA DE NEGÓCIO**

#### 5.1 **Node: Identificar Cliente e Agente**

**O QUE FAZ:**
- Extrai `client_id` e `agent_id` de `conversation.custom_attributes`
- Fallback: `clinica_sorriso_001` / `default`

**O QUE MUDAR:**
```javascript
const clientId = customAttributes.client_id || 'SEU_CLIENT_ID_PADRAO';
const agentId = customAttributes.agent_id || 'SEU_AGENT_ID_PADRAO';
```

**IMPORTANTE:** Custom attributes devem estar configurados no Chatwoot!

**Como configurar:**
- Chatwoot → Inbox → Settings → Configuration
- Custom Attributes:
  - `client_id` (text)
  - `agent_id` (text)

---

#### 5.2 **Node: Preparar Prompt LLM**

**O QUE FAZ:**
- Injeta `system_prompt`, `media_context`, `rag_context`
- Adiciona instrução crítica sobre envio de mídia

**O QUE MUDAR:**
- Nada! Já está genérico.
- Personalização vem do banco de dados (tabela `agents`)

---

#### 5.3 **Node: LLM (GPT-4o-mini + Tools)**

**O QUE FAZ:**
- Chama OpenAI com prompt completo
- Modelo: `{{ $json.llm_model }}` (vem do banco)
- Temperature: 0.7
- Max Tokens: 1000

**O QUE MUDAR (opcional):**
- Temperature: `0.7` → Mais criativo ou `0.3` → Mais conservador
- Max Tokens: `1000` → Respostas mais longas (custo ↑)
- Model: `gpt-4o-mini` → `gpt-4o` (melhor qualidade, custo 10x maior)

---

#### 5.4 **Node: Executar Tools**

**STATUS:** 🚧 PLACEHOLDER - NÃO IMPLEMENTADO

**O QUE FAZ:**
- Se LLM chamar function (calendar, sheets, CRM)
- Executa a action correspondente

**O QUE IMPLEMENTAR:**
- MCP_Calendar: Agendar eventos no Google Calendar
- MCP_Sheets: Atualizar planilhas
- MCP_CRM: Criar leads, atualizar deals

**TODO:**
```javascript
if (functionName === 'create_calendar_event') {
  // Chamar Google Calendar API
  // Retornar: "Agendado para DD/MM às HH:MM"
}
```

---

### **PASSO 6: CONFIGURAR pinData (TESTE)**

**O QUE É:**
- Dados de teste "presos" no node inicial
- Permite testar workflow sem receber webhook real

**pinData incluído no template:**
```json
{
  "content": "qual o preço?",
  "conversation": {
    "id": 99999,
    "custom_attributes": {
      "client_id": "clinica_sorriso_001",
      "agent_id": "default"
    }
  },
  "sender": {
    "phone_number": "+5511999999999",
    "name": "Cliente Teste"
  }
}
```

**IMPORTANTE:**
- `conversation.id: 99999` → ID fictício (Chatwoot retornará 404)
- Workflow continuará normalmente (tem `continueOnFail: true`)

**Como testar:**
1. Workflow → Execute Workflow (botão play)
2. Node "Chatwoot Webhook" já tem pinData
3. Verificar saída de cada node

---

### **PASSO 7: TESTAR END-TO-END**

#### 7.1 **Teste com pinData (sem WhatsApp)**

1. Execute Workflow (Ctrl+Enter)
2. Verificar nodes:
   - ✅ **Identificar Cliente e Agente:** `client_id`, `agent_id` corretos?
   - ✅ **Buscar Dados do Agente:** Retornou dados?
   - ✅ **Buscar Mídia Triggers:** Retornou mídia (se houver trigger)?
   - ✅ **Merge:** Combinou tudo corretamente?
   - ✅ **Construir Contexto Completo:** `client_media_attachments` populado?
   - ✅ **LLM:** Resposta coerente?
   - ✅ **Enviar Resposta:** HTTP 404 (esperado com conversation_id fake)
   - ✅ **Tem Anexos?:** Passou pelo IF (se houver mídia)?
   - ✅ **Download Arquivo:** Arquivo baixado do Supabase?
   - ✅ **Upload Anexo:** HTTP 404 (esperado)

**Logs esperados:**
```
✅ message_body preservado: qual o preço?
✅ client_media_attachments.length: 1 (se houver trigger)
✅ LLM response: "A tabela de preços está no anexo..."
⚠️  conversation_id não existe no Chatwoot (404) - OK!
```

---

#### 7.2 **Teste com WhatsApp Real**

**Pré-requisitos:**
1. Chatwoot inbox real conectado ao WhatsApp
2. Webhook configurado apontando para n8n
3. Conversation real aberta

**Como testar:**
1. Enviar mensagem no WhatsApp: `"quero ver a clínica"`
2. Verificar n8n:
   - Workflow executou automaticamente?
   - Node "Chatwoot Webhook" recebeu dados reais?
   - `conversation_id` agora é real (não 99999)?
3. Verificar WhatsApp:
   - Bot respondeu?
   - Arquivo chegou como anexo?

**Triggers de teste:**
```
"quero ver a clínica"     → Deve enviar foto (consultorio-recepcao.jpg)
"quero ver a equipe"      → Deve enviar foto (equipe-completa.jpg)
"quanto custa?"           → Deve enviar PDF (tabela-precos.pdf)
"qual o horário?"         → Sem mídia (só texto)
```

---

## 🎨 PERSONALIZAÇÃO POR CLIENTE

### **O QUE MUDA?** (Banco de Dados)

**Tabela `clients`:**
- `client_id`: `'nova_clinica_001'`
- `name`: `'Nova Clínica Dental'`
- `settings`: Configurações específicas

**Tabela `agents`:**
- `agent_id`: `'atendente_recepcao'`
- `system_prompt`: Personalizar tom, regras, instruções
- `llm_model`: `'gpt-4o'` ou `'gpt-4o-mini'`
- `tools_enabled`: `['calendar', 'sheets']`

**Tabela `client_media`:**
- Upload de fotos/PDFs do cliente no Supabase Storage
- Registrar na tabela com `client_id` + `file_url`

**Tabela `client_media_rules`:**
- Criar triggers: `"localização|endereço|onde fica"` → `foto-fachada.jpg`
- Criar triggers: `"serviços|tratamentos"` → `tabela-servicos.pdf`

### **O QUE NÃO MUDA?** (Workflow)

✅ Estrutura completa dos 27 nodes  
✅ Lógica de RPC + Merge  
✅ Detecção de mídia  
✅ Envio de arquivos  
✅ Error handling  
✅ Usage tracking  

**REGRA:** Um workflow para TODOS os clientes! 🎯

---

## 🔍 DEBUGGING

### **Logs Importantes**

**Node "Construir Contexto Completo":**
```javascript
console.log('✅ message_body preservado:', webhookData.message_body);
console.log('mediaRules.length:', mediaRules.length);
console.log('client_media_attachments.length:', clientMediaAttachments.length);
```

**Node "Log Chatwoot Response":**
```javascript
console.log('Status Code:', chatwootResponse.statusCode);
console.log('Body:', JSON.stringify(chatwootResponse.body, null, 2));
```

**Node "Tem Anexos?":**
```javascript
console.log('client_media_attachments:', JSON.stringify(data.client_media_attachments, null, 2));
console.log('Expressão do IF:', (data.client_media_attachments || []).length > 0 ? 'TRUE ✅' : 'FALSE ❌');
```

### **Problemas Comuns**

#### ❌ **"message_body está vazio!"**

**Causa:** Merge sobrescreveu dados do webhook

**Solução:**
```javascript
// Node "Construir Contexto Completo"
const webhookNode = $('Filtrar Apenas Incoming').first().json;
const webhookData = {
  message_body: webhookNode.message_body || item.message_body,  // ✅ BUSCAR DO NODE CORRETO
  ...
};
```

---

#### ❌ **"RPC retornou vazio mas deveria ter mídia"**

**Causa:** Trigger não está no banco ou regex não bate

**Solução:**
1. Verificar `client_media_rules`:
```sql
SELECT * FROM client_media_rules 
WHERE client_id = 'clinica_sorriso_001' 
  AND is_active = true;
```

2. Testar regex manualmente:
```sql
SELECT 'quero ver a clínica' ~* 'consultório|ambiente|clínica'; -- Deve retornar true
```

3. Adicionar novo trigger:
```sql
INSERT INTO client_media_rules (
  rule_id, client_id, agent_id, media_id, 
  trigger_type, trigger_value, priority, is_active
) VALUES (
  gen_random_uuid(), 'clinica_sorriso_001', 'default', 'MEDIA_ID_AQUI',
  'keyword', 'localização|endereço|onde fica', 1, true
);
```

---

#### ❌ **"Download do Supabase falhou (403 Forbidden)"**

**Causa:** Arquivo não está com RLS policy pública

**Solução:**
1. Supabase → Storage → Bucket
2. Verificar: `Public bucket` = ✅ ON
3. Ou criar policy:
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'client-media');
```

---

#### ❌ **"Upload para Chatwoot falhou (401 Unauthorized)"**

**Causa:** Header `api_access_token` incorreto ou expirado

**Solução:**
1. Chatwoot → Profile Settings → Access Token
2. Gerar novo token
3. Atualizar credencial no n8n
4. **OU** atualizar header hardcoded:
```javascript
// Node "Upload Anexo para Chatwoot"
{
  "name": "api_access_token",
  "value": "SEU_NOVO_TOKEN_AQUI"
}
```

---

#### ❌ **"Workflow não executa quando mensagem chega no WhatsApp"**

**Causa:** Webhook não configurado corretamente

**Solução:**
1. Verificar URL do webhook:
   - n8n → Workflow → Node "Chatwoot Webhook" → Webhook URL
   - Copiar URL

2. Verificar Chatwoot:
   - Settings → Integrations → Webhooks
   - URL está correto?
   - Event `message_created` está ✅ marcado?

3. Testar webhook manualmente:
```powershell
Invoke-RestMethod -Uri 'https://SEU_N8N_DOMAIN/webhook/chatwoot-webhook' `
  -Method POST `
  -ContentType 'application/json' `
  -Body (@{
    content = "teste"
    conversation = @{ id = 123 }
    sender = @{ id = 456 }
  } | ConvertTo-Json)
```

---

## 📚 REFERÊNCIAS TÉCNICAS

### **RPC Function: check_media_triggers**

**Localização:** `database/migrations/009_create_rpc_check_media_triggers.sql`

**Assinatura:**
```sql
CREATE OR REPLACE FUNCTION check_media_triggers(
  p_client_id VARCHAR,
  p_agent_id VARCHAR,
  p_message TEXT
)
RETURNS TABLE (
  rule_id VARCHAR,
  media_id VARCHAR,
  trigger_type VARCHAR,
  trigger_value TEXT,
  file_url TEXT,
  file_type VARCHAR,
  file_name VARCHAR,
  mime_type VARCHAR,
  title VARCHAR,
  description TEXT
)
```

**Lógica:**
```sql
WHERE cmr.client_id = p_client_id
  AND cmr.agent_id = p_agent_id
  AND cmr.is_active = true
  AND cmr.trigger_type = 'keyword'
  AND p_message ~* cmr.trigger_value  -- Case-insensitive regex
ORDER BY cmr.priority DESC, cmr.created_at DESC
LIMIT 1
```

**Retorno:**
- **Se match:** 1 linha com dados da mídia
- **Se não match:** 0 linhas (array vazio)

---

### **Merge Node: Agente + Mídia**

**Settings:**
- **Mode:** Combine
- **Combination Mode:** Merge By Position
- **Input 1:** Buscar Dados do Agente (HTTP)
- **Input 2:** Buscar Mídia Triggers (RPC)

**Comportamento:**
- Combina dados de ambos os inputs no MESMO item
- Preserva TODOS os campos de ambos
- `item.system_prompt` vem do Input 1
- `item.rule_id` vem do Input 2 (se RPC retornou algo)

---

### **Setting Crítico: Always Output Data**

**Node:** Buscar Mídia Triggers (RPC)  
**Setting:** `alwaysOutputData: true`

**Por quê?**
- RPC pode retornar **0 linhas** (sem mídia)
- Sem `alwaysOutputData`, node não passa dados adiante
- Merge fica esperando Input 2 eternamente
- Workflow trava

**Como configurar:**
1. Node → Settings (engrenagem)
2. ✅ Always Output Data

---

### **File Upload: multipart/form-data**

**Node:** Upload Anexo para Chatwoot

**Body Parameters:**
```javascript
{
  "name": "content",
  "value": "={{ $json.client_media_attachments[0].caption || 'Segue o arquivo solicitado' }}"
},
{
  "name": "message_type",
  "value": "outgoing"
},
{
  "name": "private",
  "value": "false"
},
{
  "parameterType": "formBinaryData",  // ← CRÍTICO!
  "name": "attachments[]",            // ← Array notation
  "inputDataFieldName": "data"        // ← Nome do campo binário do node anterior
}
```

**Options:**
- `contentType: "multipart/form-data"`  // ← OBRIGATÓRIO
- `responseFormat: "file"` no node anterior (Download)

---

## 🚀 PRÓXIMOS PASSOS (ROADMAP)

### **Implementar RAG (Vector Search)**

**Status:** 🚧 PLACEHOLDER

**Node atual:** Query RAG (Namespace Isolado)
```javascript
// TODO: Implementar query real no vector DB
const ragResults = [];
```

**Implementação:**
1. Escolher vector DB: Pinecone, Qdrant, Weaviate
2. Criar namespace por cliente: `client_id + '_' + agent_id`
3. Fazer embedding da mensagem: OpenAI `/embeddings`
4. Query no vector DB: Top 3 resultados
5. Adicionar ao contexto: `rag_context`

**Exemplo (Pinecone):**
```javascript
const { PineconeClient } = require('@pinecone-database/pinecone');

const pinecone = new PineconeClient();
await pinecone.init({ apiKey: 'SUA_API_KEY' });

const index = pinecone.Index('agents-knowledge');
const queryEmbedding = await openai.createEmbedding({
  model: 'text-embedding-ada-002',
  input: messageBody
});

const queryResponse = await index.query({
  namespace: `${clientId}_${agentId}`,
  vector: queryEmbedding.data[0].embedding,
  topK: 3,
  includeMetadata: true
});

const ragResults = queryResponse.matches.map(m => ({
  text: m.metadata.text,
  score: m.score
}));
```

---

### **Implementar Tools (MCP)**

**Status:** 🚧 PLACEHOLDER

**Node atual:** Executar Tools
```javascript
// TODO: Implementar chamadas reais às APIs
if (functionName === 'create_calendar_event') {
  results.push({
    tool: 'calendar',
    result: `Evento "${args.title}" criado para ${args.date}`
  });
}
```

**Implementação:**

**1. MCP_Calendar (Google Calendar):**
```javascript
const { google } = require('googleapis');

const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

if (functionName === 'create_calendar_event') {
  const event = await calendar.events.insert({
    calendarId: 'primary',
    resource: {
      summary: args.title,
      start: { dateTime: args.start_time },
      end: { dateTime: args.end_time },
      description: args.description
    }
  });
  
  results.push({
    tool: 'calendar',
    result: `Agendado: ${args.title} para ${formatDate(args.start_time)}`
  });
}
```

**2. MCP_Sheets (Google Sheets):**
```javascript
const sheets = google.sheets({ version: 'v4', auth: oauth2Client });

if (functionName === 'update_sheet') {
  await sheets.spreadsheets.values.append({
    spreadsheetId: args.sheet_id,
    range: args.range,
    valueInputOption: 'USER_ENTERED',
    resource: {
      values: [args.row_data]
    }
  });
  
  results.push({
    tool: 'sheets',
    result: `Dados adicionados na planilha ${args.sheet_id}`
  });
}
```

**3. MCP_CRM (Custom):**
```javascript
if (functionName === 'create_lead') {
  const response = await fetch('https://SEU_CRM_API/leads', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer TOKEN' },
    body: JSON.stringify({
      name: args.name,
      phone: args.phone,
      source: 'whatsapp'
    })
  });
  
  results.push({
    tool: 'crm',
    result: `Lead ${args.name} criado no CRM`
  });
}
```

---

### **Multi-Location Support** (PRÓXIMA VERSÃO)

**Objetivo:** Um agente para rede de lojas/clínicas

**Mudanças necessárias:**

**1. Database:**
- Criar tabela `locations` (ver: migration 011)
- Criar tabela `staff` (ver: migration 012)
- Criar RPC `get_location_by_inbox(p_inbox_id)`
- Criar RPC `get_staff_by_location(p_location_id)`

**2. Workflow:**
- Adicionar node: **Detectar Localização (RPC)** APÓS "Filtrar Apenas Incoming"
- Adicionar node: **Buscar Staff da Localização (RPC)**
- Atualizar "Construir Contexto Completo": Incluir `location.name`, `staff[]`
- Atualizar system prompt: Injetar informações da localização

**3. MCP_Calendar:**
- Expandir para suportar array de `calendar_id[]`
- Retornar profissionais disponíveis por horário

**Ver:** `WF0-TEMPLATE-REPLICATION-GUIDE.md` (Seção Multi-Location - futuro)

---

## 📞 SUPORTE

**Dúvidas?** Consultar:
- `SETUP-RPC-MERGE-NODES.md` - Detalhes sobre RPC + Merge
- `DEBUG-ENVIO-MIDIA-RESOLVIDO.md` - Troubleshooting de mídia
- `WF0-CHANGELOG.md` - Histórico de mudanças

**Problemas não cobertos?** 
- Abrir issue no repositório
- Documentar solução encontrada

---

## ✅ CHECKLIST DE VALIDAÇÃO

Antes de colocar em produção:

- [ ] Todas as credenciais configuradas (Supabase, Chatwoot, OpenAI)
- [ ] URLs substituídas (Supabase URL, Chatwoot URL)
- [ ] Webhook configurado no Chatwoot
- [ ] Banco de dados populado:
  - [ ] Tabela `clients` tem registro do cliente
  - [ ] Tabela `agents` tem registro do agente
  - [ ] Tabela `client_subscriptions` tem assinatura
  - [ ] Tabela `client_media` tem arquivos do cliente
  - [ ] Tabela `client_media_rules` tem triggers configurados
- [ ] Teste com pinData: ✅ Workflow executa sem erros
- [ ] Teste end-to-end: ✅ Mensagem no WhatsApp chega e bot responde
- [ ] Teste de mídia: ✅ Trigger envia arquivo correto
- [ ] Teste de erro: ✅ Mensagem inválida não quebra workflow
- [ ] Logs verificados: ✅ Sem erros críticos

---

**🎉 PRONTO! Workflow replicado com sucesso!**

Este template foi validado em produção e está pronto para escalar para **QUALQUER cliente**! 🚀


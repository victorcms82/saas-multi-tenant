# WF0 - CREDENCIAIS NECESSÁRIAS

## 📋 Lista Completa de Credenciais

O WF0 requer **3 credenciais** configuradas no n8n:

---

## 1️⃣ Supabase API (Custom Auth) ✅ NOVA!

**ID no n8n:** `Supabase API`  
**Tipo:** `httpCustomAuth`  
**Usado em:** 4 nós HTTP

### ⚠️ MUDANÇA IMPORTANTE:
**Substituímos conexão Postgres por REST API** devido a isolamento de rede (Docker/Easypanel).

### Nós que usam:
- `Buscar Dados do Agente (HTTP)` - GET /agents
- `Verificar Regras de Mídia (HTTP)` - POST /rpc/search_client_media_rules
- `Registrar Log de Envio (HTTP)` - POST /media_send_log
- `Atualizar Usage Tracking (HTTP)` - PATCH /client_subscriptions

### Dados necessários:

```
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U
```

### Como configurar no n8n:

1. **Credentials → Add Credential → Custom Auth**
2. **Name:** `Supabase API`
3. **JSON (copie exatamente):**
   ```json
   {
     "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
   }
   ```
4. **Save**

### Base URL (já configurada nos HTTP nodes):
```
https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/
```

### Como os nodes usam:
Cada HTTP node envia 2 headers automaticamente:
```
apikey: {{$credentials.apikey}}
Authorization: Bearer {{$credentials.apikey}}
```

---

## 2️⃣ OpenAI API

**ID no n8n:** `openai-creds`  
**Tipo:** `openAiApi`  
**Usado em:** 1 nó

### Nós que usam:
- `llm-gpt4o` - LLM com function calling (GPT-4o-mini)

### Dados necessários:

```
API Key: sk-proj-...
Organization ID: (opcional)
```

### Como configurar no n8n:

1. **Credentials → Add Credential → OpenAI API**
2. **Name:** `OpenAI API`
3. **Preencher:**
   ```
   API Key: sk-proj-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```
4. **Save**

### Como obter a API Key:

1. Acesse: https://platform.openai.com/api-keys
2. **Create new secret key**
3. Nome: `n8n-wf0-production`
4. Copie a key (só aparece uma vez!)
5. Cole no n8n

### ⚠️ Importante:
- Mantenha a key segura (nunca commite no Git)
- Configure billing no OpenAI: https://platform.openai.com/account/billing
- Monitore uso: https://platform.openai.com/usage
- **Modelo usado:** GPT-4o-mini (mais barato, ~$0.15/1M tokens input)

---

## 3️⃣ Chatwoot API

**ID no n8n:** `chatwoot-creds`  
**Tipo:** `chatwootApi`  
**Usado em:** 1 nó

### Nós que usam:
- `send-chatwoot` - Enviar resposta via Chatwoot

### Dados necessários:

```
Base URL: https://app.chatwoot.com
API Key: XXXXXXXXXXXXXXXXXXXXXXXX
Account ID: 123456 (usado como variável de ambiente)
```

### Como configurar no n8n:

1. **Credentials → Add Credential → Chatwoot API**
2. **Name:** `Chatwoot API`
3. **Preencher:**
   ```
   Base URL: https://app.chatwoot.com
   Access Token: XXXXXXXXXXXXXXXXXXXXXXXX
   ```
4. **Save**

### Como obter o Access Token:

1. Acesse: https://app.chatwoot.com
2. **Settings → Profile Settings → Access Token**
3. Copie o token
4. Cole no n8n

### Variável de Ambiente Adicional:

No n8n, configure também:
```
CHATWOOT_ACCOUNT_ID=123456
```

**Como encontrar o Account ID:**
- URL do Chatwoot: `https://app.chatwoot.com/app/accounts/123456/...`
- O número após `/accounts/` é o Account ID

---

## 🔧 Variáveis de Ambiente (n8n)

Além das credenciais, configure estas variáveis de ambiente:

```bash
# Chatwoot
CHATWOOT_ACCOUNT_ID=123456

# Redis (para buffer de 5s)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD= # (vazio se local, ou senha do Redis Cloud)

# Supabase (opcional, para SDK)
SUPABASE_URL=https://vnlfgnfaortdvmraoapq.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Como configurar no n8n:

**Docker Compose:**
```yaml
version: '3'
services:
  n8n:
    image: n8nio/n8n
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin123
      - CHATWOOT_ACCOUNT_ID=123456
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    ports:
      - "5678:5678"
```

**n8n Cloud:**
1. Settings → Environments → Add Variable
2. Nome: `CHATWOOT_ACCOUNT_ID`
3. Valor: `123456`
4. Save

---

## 🧪 Validação de Credenciais

### Testar Supabase:

```sql
-- No n8n, crie um workflow de teste:
-- Node: Postgres → Execute Query
SELECT 
  COUNT(*) as total_agents,
  (SELECT COUNT(*) FROM clients) as total_clients,
  (SELECT COUNT(*) FROM client_media) as total_media
FROM agents;

-- Resultado esperado:
-- total_agents: 1 (clinica_sorriso_001)
-- total_clients: 1
-- total_media: 3 (após Migration 005)
```

### Testar OpenAI:

```javascript
// No n8n, crie um workflow de teste:
// Node: OpenAI → Chat
// Prompt: "Say hello in Portuguese"

// Resultado esperado:
// "Olá! Como posso ajudar você hoje?"
```

### Testar Chatwoot:

```bash
# No n8n, crie um workflow de teste:
# Node: HTTP Request
# Method: GET
# URL: https://app.chatwoot.com/api/v1/accounts/{{$env.CHATWOOT_ACCOUNT_ID}}/conversations
# Authentication: Chatwoot API

# Resultado esperado:
# Lista de conversas (pode estar vazia)
```

---

## 📊 Resumo Visual

```
WF0 - Gestor Universal
│
├─ 🔌 Credencial 1: Supabase Database (postgres)
│  ├─ Host: aws-0-us-east-1.pooler.supabase.com
│  ├─ Port: 6543
│  ├─ User: postgres.vnlfgnfaortdvmraoapq
│  ├─ Password: SenhaMaster123!
│  └─ Usada em: 5 nós (get-agent, check-media-rules, log-media, update-usage)
│
├─ 🔌 Credencial 2: OpenAI API (openAiApi)
│  ├─ API Key: sk-proj-...
│  └─ Usada em: 1 nó (llm-gpt4o)
│
└─ 🔌 Credencial 3: Chatwoot API (chatwootApi)
   ├─ Base URL: https://app.chatwoot.com
   ├─ Access Token: XXXXXXXX
   ├─ Account ID: 123456 (variável de ambiente)
   └─ Usada em: 1 nó (send-chatwoot)
```

---

## 🚨 Troubleshooting

### Erro: "Database connection failed"

**Causa:** Credencial Supabase incorreta

**Solução:**
1. Verifique se as Migrations 001-005 foram executadas
2. Teste conexão direta:
   ```bash
   psql "postgresql://postgres.vnlfgnfaortdvmraoapq:SenhaMaster123!@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
   ```
3. Verifique firewall/SSL do Supabase

### Erro: "OpenAI API key invalid"

**Causa:** API key expirada ou incorreta

**Solução:**
1. Gere nova key: https://platform.openai.com/api-keys
2. Atualize no n8n
3. Verifique billing ativo no OpenAI

### Erro: "Chatwoot 401 Unauthorized"

**Causa:** Access Token inválido ou Account ID errado

**Solução:**
1. Regenere token no Chatwoot: Settings → Profile → Access Token
2. Verifique Account ID na URL do Chatwoot
3. Atualize variável de ambiente `CHATWOOT_ACCOUNT_ID`

---

## 🔐 Segurança

### Boas Práticas:

1. **Nunca commite credenciais no Git**
   - Use `.env` local
   - Configure no n8n diretamente

2. **Rotacione keys regularmente**
   - OpenAI: A cada 90 dias
   - Chatwoot: A cada 180 dias
   - Supabase: Apenas se comprometida

3. **Use credenciais diferentes por ambiente**
   - Development: `openai-dev`, `supabase-dev`
   - Production: `openai-prod`, `supabase-prod`

4. **Monitore uso**
   - OpenAI: https://platform.openai.com/usage
   - Supabase: Dashboard → Database → Activity

---

## 📝 Checklist de Setup

Antes de ativar o WF0, verifique:

- [ ] ✅ Credencial `supabase-db` configurada e testada
- [ ] ✅ Credencial `openai-creds` configurada e testada
- [ ] ✅ Credencial `chatwoot-creds` configurada e testada
- [ ] ✅ Variável `CHATWOOT_ACCOUNT_ID` configurada
- [ ] ✅ Migrations 001-005 executadas no Supabase
- [ ] ✅ Bucket `client-media` criado no Supabase Storage
- [ ] ✅ Dados de teste inseridos (clinica_sorriso_001)
- [ ] ✅ Workflow WF0 importado no n8n
- [ ] ✅ Webhook URL configurado no Chatwoot
- [ ] ✅ Teste end-to-end realizado

---

## 📞 Próximos Passos

Após configurar todas as credenciais:

1. **Importar WF0 no n8n:**
   - Workflows → Import from File
   - Selecionar: `workflows/WF0-Gestor-Universal-COMPLETE.json`

2. **Configurar Webhook no Chatwoot:**
   - Settings → Integrations → Webhooks
   - URL: `https://seu-n8n.com/webhook/chatwoot-webhook`
   - Events: `message_created`, `conversation_created`

3. **Ativar Workflow:**
   - Toggle: **Active**
   - Status: 🟢 Active

4. **Testar:**
   - Enviar mensagem via WhatsApp/Chatwoot
   - Verificar resposta do agente
   - Validar envio de mídia do cliente

---

**Versão:** 1.0  
**Última atualização:** 2025-11-07  
**Status:** 📋 Pronto para configuração

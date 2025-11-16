# 🔐 RESUMO: Credenciais do WF0

## ✅ 3 Credenciais Necessárias

### 1️⃣ Supabase API (Custom Auth)
**Tipo:** Custom Auth  
**Nome:** `Supabase API`

**JSON:**
```json
{
  "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
}
```

**Usada em:**
- Buscar Dados do Agente (HTTP)
- Verificar Regras de Mídia (HTTP)
- Registrar Log de Envio (HTTP)
- Atualizar Usage Tracking (HTTP)

---

### 2️⃣ OpenAI API
**Tipo:** OpenAI API  
**Nome:** `OpenAI API`

**Configuração:**
- API Key: `YOUR_OPENAI_API_KEY` (sua key da OpenAI)

**Como obter:**
1. https://platform.openai.com/api-keys
2. Create new secret key
3. Nome: `n8n-wf0-production`
4. Copie e cole no n8n

**Usada em:**
- LLM com function calling (GPT-4o-mini)

---

### 3️⃣ Chatwoot API
**Tipo:** Chatwoot API  
**Nome:** `Chatwoot API`

**Configuração:**
- Base URL: `https://app.chatwoot.com`
- Access Token: `XXXXXXXXXXXXXXX` (seu token do Chatwoot)

**Como obter:**
1. https://app.chatwoot.com
2. Settings → Profile Settings → Access Token
3. Copie e cole no n8n

**Variável de Ambiente Adicional:**
```
CHATWOOT_ACCOUNT_ID=123456
```
(Encontre na URL: `https://app.chatwoot.com/app/accounts/123456/...`)

**Usada em:**
- Enviar resposta via Chatwoot

---

## 📋 Checklist de Configuração

### Supabase API ✅
- [ ] Custom Auth criada no n8n
- [ ] Nome: `Supabase API`
- [ ] JSON com anon key configurado
- [ ] Testada com Node "Verificar Regras de Mídia"
- [ ] Migrations 005 e 006 executadas

### OpenAI API ⏳
- [ ] API Key gerada no OpenAI
- [ ] Billing configurado (mínimo $5 USD)
- [ ] Credential criada no n8n
- [ ] Nome: `OpenAI API`
- [ ] Testada com prompt simples

### Chatwoot API ⏳
- [ ] Access Token gerado no Chatwoot
- [ ] Credential criada no n8n
- [ ] Nome: `Chatwoot API`
- [ ] Variável CHATWOOT_ACCOUNT_ID configurada
- [ ] Testada com GET /conversations

---

## 🎯 Ordem de Configuração Recomendada

### 1. Configure Supabase API primeiro (5 min)
✅ **JÁ FEITO** conforme SETUP-FINAL-HTTP-NODES.md

### 2. Configure OpenAI API (10 min)
1. Abra https://platform.openai.com/api-keys
2. Create new secret key
3. Copie a key
4. n8n → Credentials → Add Credential → OpenAI API
5. Cole a key
6. Save

**Teste:**
- Create workflow de teste
- Add node: OpenAI Chat
- Prompt: "Say hello in Portuguese"
- Execute
- Resultado esperado: "Olá! Como posso ajudar?"

### 3. Configure Chatwoot API (10 min)
1. Abra https://app.chatwoot.com
2. Settings → Profile Settings → Access Token
3. Copie o token
4. n8n → Credentials → Add Credential → Chatwoot API
5. Base URL: `https://app.chatwoot.com`
6. Access Token: [cole aqui]
7. Save

**Variável de Ambiente:**
- Docker Compose: Adicione `CHATWOOT_ACCOUNT_ID=123456` no environment
- n8n Cloud: Settings → Environments → Add Variable

**Teste:**
- Create workflow de teste
- Add node: HTTP Request
- Method: GET
- URL: `https://app.chatwoot.com/api/v1/accounts/{{$env.CHATWOOT_ACCOUNT_ID}}/conversations`
- Authentication: Chatwoot API
- Execute
- Resultado esperado: Lista de conversas (pode estar vazia)

---

## 🚨 Troubleshooting

### Supabase API
**Erro: 401 Unauthorized**
- Verificar se anon key está correta
- Verificar se credential está selecionada no node
- Testar com: `SELECT * FROM search_client_media_rules('clinica_sorriso_001', 'default', 'preço', 'test');`

### OpenAI API
**Erro: Invalid API key**
- Regenerar key no OpenAI
- Verificar billing ativo
- Verificar se key começa com `sk-proj-` (novo formato)

### Chatwoot API
**Erro: 401 Unauthorized**
- Regenerar Access Token no Chatwoot
- Verificar Base URL (sem barra no final)
- Verificar Account ID na URL do Chatwoot

---

## 📊 Status Atual

| Credencial | Status | Próxima Ação |
|------------|--------|--------------|
| Supabase API | ✅ Configurada | Importar HTTP nodes |
| OpenAI API | ⏳ Pendente | Gerar key + configurar |
| Chatwoot API | ⏳ Pendente | Gerar token + configurar |

**Total de Tempo Estimado:** 25 minutos

---

## ✅ Depois de Configurar Tudo

1. **Importar WF0 completo:**
   - `workflows/WF0-Gestor-Universal-COMPLETE.json`

2. **Importar HTTP nodes:**
   - `workflows/WF0-HTTP-NODES.json`

3. **Conectar HTTP nodes** no lugar dos Postgres

4. **Configurar webhook no Chatwoot:**
   - URL: `https://seu-n8n.com/webhook/chatwoot-webhook`
   - Events: `message_created`

5. **Ativar WF0** e testar! 🚀

---

**Dúvidas?** Siga o guia completo: `SETUP-FINAL-HTTP-NODES.md`

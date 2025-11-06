# 🚀 WF0 - Guia Rápido de Instalação

## ⚡ Setup em 10 Minutos

### 1️⃣ Importar Workflow (2 min)

```bash
# Opção A: Via arquivo
# n8n UI → Workflows → Import from File → Selecionar WF0-Gestor-Universal-COMPLETE.json

# Opção B: Via CLI (se tiver acesso)
cp workflows/WF0-Gestor-Universal-COMPLETE.json ~/.n8n/workflows/
```

### 2️⃣ Configurar Credenciais (5 min)

#### Supabase (Obrigatório)
```
n8n → Credentials → Add → Postgres
- Nome: Supabase Database
- Host: db.xxx.supabase.co
- Port: 5432
- Database: postgres
- User: postgres
- Password: [Supabase Dashboard → Settings → Database]
- SSL: Enable
```

#### OpenAI (Obrigatório)
```
n8n → Credentials → Add → OpenAI
- Nome: OpenAI API
- API Key: sk-... [https://platform.openai.com/api-keys]
```

#### Chatwoot (Obrigatório)
```
n8n → Credentials → Add → Chatwoot
- Nome: Chatwoot API
- Base URL: https://app.chatwoot.com
- Account ID: [Settings → Account Settings → ID]
- API Token: [Profile → Access Token]
```

#### Redis (Opcional - para buffer)
```
n8n → Credentials → Add → Redis
- Host: localhost (ou redis.upstash.com)
- Port: 6379
- Password: [se necessário]
```

### 3️⃣ Configurar Webhook no Chatwoot (2 min)

1. Chatwoot → Settings → Integrations → Webhooks
2. Click **Add Webhook**
3. Preencher:
   - **URL**: `https://seu-n8n.com/webhook/chatwoot-webhook`
   - **Events**: Selecionar `message_created`
4. Save

### 4️⃣ Ativar Workflow (1 min)

```
n8n UI → Workflows → WF0 - Gestor Universal
→ Toggle "Active" (verde)
```

---

## ✅ Testar Instalação

### Teste 1: Mensagem de Texto Simples

1. Abrir conversa no Chatwoot com custom attributes:
   ```json
   {
     "client_id": "clinica_sorriso_001",
     "agent_id": "default"
   }
   ```

2. Enviar mensagem: **"Olá, teste"**

3. Verificar:
   - ✅ n8n recebeu webhook (Executions)
   - ✅ Resposta enviada via Chatwoot
   - ✅ Usage atualizado no DB

### Teste 2: Mensagem com Áudio

1. Enviar mensagem de áudio (30s)
2. Verificar:
   - ✅ Node "Transcrever Áudio" executou
   - ✅ `transcription_minutes_used` incrementou no DB

### Teste 3: Mensagem com Imagem

1. Enviar foto
2. Verificar:
   - ✅ Node "Analisar Imagens" executou
   - ✅ `images_processed` incrementou no DB

---

## 🔧 Configurações Adicionais (Opcional)

### Google Speech-to-Text (Transcrição Real)

1. **Criar Service Account**:
   - Google Cloud Console → IAM → Service Accounts
   - Create Service Account
   - Grant role: **Cloud Speech-to-Text User**
   - Create JSON key

2. **Configurar no n8n**:
   ```
   n8n → Credentials → Add → Google Cloud Service Account
   - Upload JSON key
   ```

3. **Atualizar Node "Transcrever Áudio"**:
   - Trocar function por **Google Cloud Speech-to-Text** node
   - Configurar:
     - Audio URL: `{{$json.url}}`
     - Language: `pt-BR`
     - Model: `default`

### Vector DB (RAG Real)

#### Opção A: Pinecone
```
1. Criar conta: https://pinecone.io
2. Create Index:
   - Name: saas-agents
   - Dimensions: 1536 (OpenAI embeddings)
   - Metric: cosine
3. n8n → Credentials → Add → Pinecone
   - API Key: [Pinecone Console]
   - Environment: us-east-1 (ou sua região)
```

#### Opção B: Qdrant (Self-hosted)
```bash
# Docker
docker run -p 6333:6333 qdrant/qdrant

# n8n → Credentials → Add → Qdrant
# - Host: http://localhost:6333
```

### GPT-4 Vision (Análise de Imagem Real)

**Atualizar Node "Analisar Imagens"**:

Trocar function por **OpenAI Vision** node:
```json
{
  "model": "gpt-4-vision-preview",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Descreva esta imagem em detalhes"
        },
        {
          "type": "image_url",
          "image_url": "{{$json.url}}"
        }
      ]
    }
  ],
  "max_tokens": 500
}
```

---

## 📊 Validar Instalação

### Query de Verificação

```sql
-- 1. Verificar se cliente existe
SELECT * FROM agents 
WHERE client_id = 'clinica_sorriso_001' 
AND agent_id = 'default';

-- 2. Verificar subscription
SELECT * FROM client_subscriptions
WHERE client_id = 'clinica_sorriso_001'
AND agent_id = 'default';

-- 3. Verificar usage após teste
SELECT 
  total_messages,
  transcription_minutes_used,
  images_processed,
  last_message_at
FROM client_subscriptions
WHERE client_id = 'clinica_sorriso_001';
```

**Resultado Esperado** (após testes):
```
total_messages: 3
transcription_minutes_used: 0.5 (se enviou áudio 30s)
images_processed: 1 (se enviou foto)
last_message_at: [timestamp recente]
```

---

## 🐛 Troubleshooting

### ❌ Webhook não recebe mensagens

**Problema**: n8n não recebe eventos do Chatwoot

**Solução**:
1. Verificar URL do webhook está correta
2. n8n está acessível publicamente (usar ngrok se local)
3. Chatwoot webhook está **Active**
4. Verificar logs do Chatwoot: Settings → Webhooks → Ver últimos eventos

### ❌ Erro: "client_id not found"

**Problema**: Conversa não tem custom attributes

**Solução**:
1. Chatwoot → Conversa → Custom Attributes
2. Adicionar:
   ```json
   {
     "client_id": "clinica_sorriso_001",
     "agent_id": "default"
   }
   ```

### ❌ Erro: "Cannot connect to database"

**Problema**: Credenciais Supabase incorretas

**Solução**:
1. Verificar credenciais: n8n → Credentials → Supabase Database
2. Testar conexão: Supabase Dashboard → Settings → Database → Connection string
3. Checar firewall/IP whitelist no Supabase

### ❌ Erro: "OpenAI API rate limit"

**Problema**: Excedeu limite da API

**Solução**:
1. Verificar uso: https://platform.openai.com/usage
2. Aumentar limite ou adicionar billing
3. Temporariamente: reduzir `max_tokens` no node LLM

---

## 📈 Próximos Passos

Após instalação básica funcionar:

1. **Integrar APIs reais**:
   - [ ] Google Speech-to-Text (transcrição)
   - [ ] GPT-4 Vision (imagens)
   - [ ] Vector DB (RAG)
   - [ ] Redis (buffer)

2. **Configurar mais canais**:
   - [ ] Email (Chatwoot inbox)
   - [ ] Instagram DM
   - [ ] Telegram

3. **Adicionar mais tools**:
   - [ ] Google Calendar
   - [ ] Google Sheets
   - [ ] Notion
   - [ ] Trello

4. **Monitoramento**:
   - [ ] Configurar Sentry (error tracking)
   - [ ] Dashboard Grafana (métricas)
   - [ ] Alertas de uso (email)

---

## 📞 Suporte

**Problemas na instalação?**

1. **Verificar logs**: n8n → Executions → Última execução → Ver detalhes
2. **Testar componente isolado**: Executar node individual (botão "Execute Node")
3. **Consultar DB**: Rodar queries de verificação acima

**Documentação completa**: `WF0-DOCUMENTATION.md`

---

✅ **Instalação concluída!** Workflow pronto para processar mensagens multi-modais em todos os canais.

# 🚀 SETUP FINAL: Custom Auth + HTTP Nodes

## ✅ STATUS ATUAL

| Item | Status |
|------|--------|
| Migration 005 (tabelas) | ✅ **EXECUTADA** |
| Migration 006 (RPC function) | ✅ **EXECUTADA** |
| Função RPC testada | ✅ **FUNCIONANDO** |
| Anon Key validada | ✅ **CONFIRMADA** |
| Custom Auth no n8n | ⏳ **PENDENTE** |
| HTTP Nodes importados | ⏳ **PENDENTE** |

---

## 📋 Passo 1: Criar Custom Auth no n8n

### 1.1 Abrir Credentials

1. **Abra n8n** (seu servidor Easypanel)
2. **Menu lateral** → **Credentials**
3. **Botão:** **Add Credential**

### 1.2 Selecionar Custom Auth

- **Busque:** `Custom Auth`
- **Clique** no resultado: **"Custom Auth"**

### 1.3 Configurar JSON

**Name:** `Supabase API`

**JSON (copie exatamente):**
```json
{
  "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
}
```

### 1.4 Salvar

- **Botão:** **Save** (canto superior direito)
- ✅ Credential criada com sucesso!

---

## 📋 Passo 2: Importar HTTP Nodes

### 2.1 Abrir WF0

1. **Workflows** (menu lateral)
2. **Abra:** "WF0 - Gestor Universal" (ou o nome do seu workflow)

### 2.2 Importar Arquivo

1. **Menu (...)** no canto superior direito
2. **Import from File**
3. **Selecione:** `workflows/WF0-HTTP-NODES.json`
4. **4 nodes aparecem** no canvas (pode estar agrupado, arraste para separar)

### 2.3 Nodes Importados

Você verá 4 novos nodes:
- 🟦 **Buscar Dados do Agente (HTTP)**
- 🟦 **Verificar Regras de Mídia (HTTP)**
- 🟦 **Registrar Log de Envio (HTTP)**
- 🟦 **Atualizar Usage Tracking (HTTP)**

---

## 📋 Passo 3: Configurar Credential em Cada Node

**Para CADA um dos 4 nodes:**

1. **Clique no node**
2. **Painel lateral abre**
3. **Seção "Authentication"**
4. **Dropdown:** Selecione **"Supabase API"** (a credential criada no Passo 1)
5. **Botão "Save"** (no painel do node)
6. **Verificar:** ✅ verde aparece no node

**Repita para os 4 nodes!**

---

## 📋 Passo 4: Testar Nodes Individualmente

### Teste Node 2: Verificar Regras de Mídia

1. **Clique** no node "Verificar Regras de Mídia (HTTP)"
2. **Aba "Test"** (painel lateral)
3. **Execute Workflow** (botão)
4. **Input de teste:**
   ```json
   {
     "client_id": "clinica_sorriso_001",
     "agent_id": "default",
     "message_body": "qual o preço?",
     "conversation_id": "test-123"
   }
   ```
5. **Resultado esperado:**
   - ✅ **1 item retornado**
   - ✅ `file_name`: "tabela-precos.pdf"
   - ✅ `trigger_type`: "keyword"

Se funcionar, os outros nodes também funcionarão! 🎉

---

## 📋 Passo 5: Conectar Nodes no WF0

### Mapeamento de Substituição

| Node Postgres Antigo | Node HTTP Novo | Entrada | Saída |
|---------------------|----------------|---------|-------|
| Buscar Dados do Agente | Buscar Dados do Agente (HTTP) | Filtrar Apenas Incoming | Tem Mídia? (IF) |
| Verificar Regras de Mídia | Verificar Regras de Mídia (HTTP) | Construir Resposta Final | Tem Mídia para Enviar? (IF) |
| Registrar Log de Envio | Registrar Log de Envio (HTTP) | Preparar Mídias do Cliente | Atualizar Usage Tracking |
| Atualizar Usage Tracking | Atualizar Usage Tracking (HTTP) | Registrar Log de Envio | Enviar Resposta via Chatwoot |

### Como Conectar

**Para cada node:**

1. **Localize** o node Postgres antigo no canvas
2. **Identifique** as conexões:
   - Seta **entrando** (de qual node vem)
   - Seta **saindo** (para qual node vai)
3. **Delete** o node Postgres antigo
4. **Arraste** o node HTTP novo para a mesma posição
5. **Reconecte:**
   - Arraste seta do node anterior para o node HTTP
   - Arraste seta do node HTTP para o próximo node

---

## 🎯 Checklist Final

- [ ] **Custom Auth criada** no n8n (`Supabase API`)
- [ ] **4 HTTP nodes importados** do arquivo WF0-HTTP-NODES.json
- [ ] **Node 1:** Credential configurada ✅
- [ ] **Node 2:** Credential configurada ✅
- [ ] **Node 3:** Credential configurada ✅
- [ ] **Node 4:** Credential configurada ✅
- [ ] **Node 2 testado:** Retornou tabela-precos.pdf ✅
- [ ] **Node 1 conectado** no WF0 (substituiu Postgres)
- [ ] **Node 2 conectado** no WF0 (substituiu Postgres)
- [ ] **Node 3 conectado** no WF0 (substituiu Postgres)
- [ ] **Node 4 conectado** no WF0 (substituiu Postgres)
- [ ] **WF0 salvo** com as mudanças
- [ ] **Teste end-to-end** realizado (enviar mensagem com "preço")

---

## 🚨 Troubleshooting

### Erro: "401 Unauthorized"
**Causa:** Anon key incorreta ou credential não configurada

**Fix:**
1. Verificar se JSON da credential está correto
2. Verificar se credential está selecionada no node
3. Regenerar anon key no Supabase (Settings → API)

### Erro: "404 Not Found"
**Causa:** URL base incorreta ou migration não executada

**Fix:**
1. Verificar URL: `https://vnlfgnfaortdvmraoapq.supabase.co`
2. Verificar se Migration 005 foi executada (tabelas existem)
3. Verificar se Migration 006 foi executada (função RPC existe)

### Erro: "Function search_client_media_rules does not exist"
**Causa:** Migration 006 não foi executada

**Fix:**
1. Executar `database/migrations/006_add_rpc_function.sql` no Supabase
2. Verificar com: `SELECT * FROM search_client_media_rules('clinica_sorriso_001', 'default', 'preço', 'test');`

### Erro: "No rows returned" (HTTP 200 mas vazio)
**Causa:** Dados de exemplo não inseridos ou keywords não batem

**Fix:**
1. Verificar se dados foram inseridos: `SELECT * FROM client_media;`
2. Verificar keywords: `SELECT keywords FROM media_send_rules;`
3. Testar com keyword exata: "preço", "equipe", "consultório"

---

## 📊 Arquivos Importantes

| Arquivo | Descrição |
|---------|-----------|
| `workflows/WF0-HTTP-NODES.json` | 4 HTTP nodes prontos para importar |
| `database/migrations/005_add_client_media_tables_CLEAN.sql` | Tabelas (executado ✅) |
| `database/migrations/006_add_rpc_function.sql` | RPC function (executado ✅) |
| `workflows/CUSTOM-AUTH-SETUP.md` | Guia de configuração Custom Auth |
| `workflows/CLIENT-MEDIA-SETUP.md` | Guia completo do sistema de mídia |

---

## ✅ Próxima Ação

**Você deve agora:**

1. **Abrir n8n**
2. **Criar Custom Auth** (Passo 1)
3. **Importar HTTP Nodes** (Passo 2)
4. **Configurar credentials** (Passo 3)
5. **Testar Node 2** (Passo 4)
6. **Conectar no WF0** (Passo 5)

**Tempo estimado:** 15-20 minutos

---

**Status:** ✅ Migrations executadas, anon key validada, pronto para importar!

**Qualquer dúvida, cole aqui o erro exato!** 🚀

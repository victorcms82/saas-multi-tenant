# 🏢 Chatwoot Multi-Tenancy - Guia Completo

## 📋 Visão Geral

Este guia explica como dar acesso ao Chatwoot para clientes do SaaS, permitindo que eles acompanhem suas conversas de forma isolada.

---

## 🎯 Arquitetura Escolhida: **Inboxes Separadas**

Cada cliente possui:
- ✅ **1 Inbox exclusiva** no Chatwoot
- ✅ **1 Agent Account** com permissões limitadas
- ✅ **Acesso apenas às suas próprias conversas**
- ✅ **Isolamento total de dados**

```
Chatwoot (Account 1)
├─ Inbox: Clínica Sorriso 001 (ID: 123)
│  ├─ Bot Agent: Maria (automação)
│  └─ Client Agent: João (humano - cliente)
│
├─ Inbox: Escritório Advocacia 002 (ID: 124)
│  ├─ Bot Agent: Pedro (automação)
│  └─ Client Agent: Dra. Ana (humano - cliente)
│
└─ Inbox: E-commerce Fashion 003 (ID: 125)
   ├─ Bot Agent: Carlos (automação)
   └─ Client Agent: Marcos (humano - cliente)
```

---

## 🚀 Setup Inicial (Executar 1 vez por cliente)

### Passo 1: Rodar Script de Setup

```powershell
cd C:\Documentos\Projetos\saas-multi-tenant\scripts

.\setup-chatwoot-client.ps1 `
    -ClientId "clinica_sorriso_001" `
    -ClientName "Clínica Sorriso" `
    -ClientEmail "joao@clinicasorriso.com.br"
```

**O que o script faz:**
1. ✅ Cria Inbox no Chatwoot: "Clínica Sorriso - clinica_sorriso_001"
2. ✅ Cria Agent Account: "Clínica Sorriso (Cliente)" com role `agent`
3. ✅ Adiciona Agent à Inbox criada
4. ✅ Salva mapeamento no Supabase (clients table)
5. ✅ Retorna Inbox ID e Agent ID

**Output esperado:**
```
🚀 Configurando Chatwoot para cliente: Clínica Sorriso (clinica_sorriso_001)

📥 Criando Inbox...
✅ Inbox criada com sucesso! ID: 123

👤 Criando conta de Agent para o cliente...
✅ Agent criado com sucesso! ID: 456
📧 Email de confirmação enviado para: joao@clinicasorriso.com.br

🔗 Adicionando Agent à Inbox...
✅ Agent adicionado à Inbox!

💾 Salvando mapeamento no Supabase...
✅ Mapeamento salvo no banco!

================================================================================
Cliente: Clínica Sorriso
Client ID: clinica_sorriso_001
Inbox ID: 123
Agent ID: 456
Email: joao@clinicasorriso.com.br

URL de acesso do cliente:
https://chatwoot.evolutedigital.com.br/app/accounts/1/inbox/123

Próximos passos:
1. Cliente deve acessar email joao@clinicasorriso.com.br e confirmar conta
2. Após confirmação, fazer login em https://chatwoot.evolutedigital.com.br
3. Cliente verá apenas conversas da Inbox 'Clínica Sorriso - clinica_sorriso_001'
================================================================================
```

---

### Passo 2: Cliente Confirma Email

1. Cliente recebe email do Chatwoot: **"You have been invited to join..."**
2. Clica no link de confirmação
3. Define senha de acesso
4. Faz login em `https://chatwoot.evolutedigital.com.br`

---

### Passo 3: Rodar Migration 007 no Supabase

```powershell
# Via psql
psql "postgresql://postgres.vnlfgnfaortdvmraoapq:SenhaMaster123!@aws-0-us-east-1.pooler.supabase.com:6543/postgres" -f database/migrations/007_add_chatwoot_multi_tenancy.sql

# Ou via Supabase Dashboard
# SQL Editor → Copiar conteúdo de 007_add_chatwoot_multi_tenancy.sql → Run
```

---

## 🔄 Fluxo de Uso (WF0)

### Atualizar WF0 para usar Inbox dinâmica

Atualmente, o WF0 usa Inbox hardcoded:
```
url: "https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}/messages"
```

**Modificação necessária:**

No node **"Identificar Cliente e Agente"**, adicionar busca da Inbox:

```javascript
// Buscar dados do cliente (incluindo chatwoot_inbox_id)
const clientData = $('Buscar Dados do Agente (HTTP)').first().json;

return {
  json: {
    ...item,
    chatwoot_inbox_id: clientData.chatwoot_inbox_id || null,
    chatwoot_account_id: 1  // Fixo por enquanto
  }
};
```

No node **"Enviar Resposta via Chatwoot"**, atualizar URL:

```javascript
// ANTES (hardcoded):
url: "https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}/messages"

// DEPOIS (dinâmico):
url: "https://chatwoot.evolutedigital.com.br/api/v1/accounts/{{ $json.chatwoot_account_id }}/conversations/{{ $json.conversation_id }}/messages"
```

---

## 🔐 Permissões e Controle de Acesso

### Níveis de Acesso no Chatwoot

| Role | Permissões | Uso |
|------|-----------|-----|
| **Administrator** | Tudo: gerenciar usuários, inboxes, integrações, billing | Você (SaaS owner) |
| **Agent** | Ver e responder conversas da(s) Inbox(es) atribuída(s) | Cliente final |
| **Supervisor** | Ver todas conversas, relatórios, mas não gerenciar usuários | Gerente do cliente |

### O que o Cliente Agent pode fazer:

✅ **PODE:**
- Ver conversas da sua Inbox
- Responder manualmente conversas (caso bot não resolva)
- Ver histórico completo
- Adicionar notas internas
- Atribuir conversas a si mesmo
- Resolver/reabrir conversas

❌ **NÃO PODE:**
- Ver conversas de outras Inboxes
- Criar/editar/deletar Inboxes
- Gerenciar usuários
- Acessar configurações da conta
- Ver billing ou integrações
- Instalar/desinstalar apps

---

## 📊 Testando Multi-Tenancy

### Teste 1: Cliente vê apenas suas conversas

1. Faça login como Administrator
2. Envie mensagem de teste para 2 clientes diferentes:
   ```powershell
   # Cliente 1
   .\test-wf0-webhook.ps1 -MessageBody "teste cliente 1"
   
   # Cliente 2
   .\test-wf0-webhook.ps1 -MessageBody "teste cliente 2"
   ```

3. Faça login como Client Agent (cliente 1)
4. Verifique que vê apenas conversas da Inbox 1

### Teste 2: Isolamento de dados

```sql
-- No Supabase, verificar mapeamento
SELECT 
  client_id,
  client_name,
  chatwoot_inbox_id,
  chatwoot_agent_id,
  chatwoot_agent_email,
  chatwoot_access_granted
FROM clients
WHERE chatwoot_access_granted = TRUE;
```

---

## 🎨 Customização (Opcional)

### 1. Branding por Inbox

Configure logo e cores diferentes para cada cliente:

```bash
# Via Chatwoot UI
Settings → Inboxes → Clínica Sorriso 001 → Settings
├─ Widget Color: #FF5733
├─ Widget Logo: https://clinicasorriso.com.br/logo.png
└─ Welcome Message: "Olá! Bem-vindo à Clínica Sorriso"
```

### 2. Email Templates Personalizados

Crie templates de email com branding do cliente:

```bash
Settings → Inboxes → Clínica Sorriso 001 → Email Templates
```

### 3. Business Hours

Configure horários de atendimento diferentes por Inbox:

```bash
Settings → Inboxes → Clínica Sorriso 001 → Business Hours
├─ Segunda-Sexta: 08:00 - 18:00
└─ Sábado: 08:00 - 12:00
```

---

## 🔄 Automação Completa

### Criar Inbox ao Criar Cliente (n8n Workflow)

Quando um novo cliente for criado no sistema, automaticamente:

```javascript
// WF-NEW-CLIENT (novo workflow n8n)

// 1. Criar registro no Supabase
INSERT INTO clients (client_id, client_name, client_email, ...)
VALUES ('novo_cliente_004', 'Novo Cliente', 'contato@novo.com.br', ...)

// 2. Acionar script PowerShell via HTTP Request
POST https://api.evolutedigital.com.br/setup-chatwoot
Body: {
  client_id: "novo_cliente_004",
  client_name: "Novo Cliente",
  client_email: "contato@novo.com.br"
}

// 3. Script roda setup-chatwoot-client.ps1
// 4. Retorna inbox_id e agent_id
// 5. Atualiza Supabase com IDs

// 6. Enviar email de boas-vindas ao cliente
"Olá! Sua conta foi criada. Acesse seu email para confirmar."
```

---

## 🚨 Troubleshooting

### Erro: "Agent já existe"

**Causa:** Email já cadastrado no Chatwoot

**Solução:**
```powershell
# Buscar Agent existente
$AgentsResponse = Invoke-RestMethod `
    -Uri "https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/agents" `
    -Method GET `
    -Headers @{"api_access_token" = "zL8FNtrajZjGv4LP9BrZiCif"}

$AgentsResponse | Where-Object { $_.email -eq "joao@clinicasorriso.com.br" }
```

### Erro: "Cliente não vê conversas"

**Possíveis causas:**
1. Agent não foi adicionado à Inbox
2. Conversas estão em outra Inbox
3. Chatwoot webhook está enviando para Inbox errada

**Solução:**
```bash
# Verificar Inboxes do Agent
GET /api/v1/accounts/1/agents/{agent_id}/inboxes

# Adicionar manualmente à Inbox
POST /api/v1/accounts/1/inbox_members
Body: {
  "inbox_id": 123,
  "user_ids": [456]
}
```

### Erro: "Conversas aparecem na Inbox errada"

**Causa:** WF0 está usando conversation_id de outra Inbox

**Solução:**
- Verificar que webhook do Chatwoot está configurado com Inbox correta
- Verificar que n8n está criando conversas na Inbox correta

---

## 📈 Métricas e Monitoramento

### Dashboard de Multi-Tenancy

Criar view no Supabase:

```sql
CREATE VIEW v_chatwoot_multi_tenancy AS
SELECT 
  c.client_id,
  c.client_name,
  c.chatwoot_inbox_id,
  c.chatwoot_agent_email,
  c.chatwoot_access_granted,
  c.chatwoot_setup_at,
  COUNT(DISTINCT cs.conversation_id) AS total_conversations,
  MAX(cs.updated_at) AS last_conversation_at
FROM clients c
LEFT JOIN client_subscriptions cs ON c.client_id = cs.client_id
WHERE c.chatwoot_access_granted = TRUE
GROUP BY c.client_id, c.client_name, c.chatwoot_inbox_id, 
         c.chatwoot_agent_email, c.chatwoot_access_granted, c.chatwoot_setup_at;

-- Consultar
SELECT * FROM v_chatwoot_multi_tenancy;
```

---

## 🔐 Segurança

### Boas Práticas:

1. **Nunca compartilhar api_access_token com clientes**
   - Token do Administrator tem acesso total
   - Clientes usam apenas login/senha

2. **Rotacionar tokens a cada 180 dias**
   ```bash
   # Chatwoot: Settings → Profile → Access Token → Regenerate
   ```

3. **Monitorar acessos suspeitos**
   ```sql
   -- Verificar logins recentes
   SELECT * FROM audit_logs 
   WHERE action = 'user.login' 
   ORDER BY created_at DESC 
   LIMIT 100;
   ```

4. **Limitar tentativas de login**
   - Chatwoot tem rate limiting nativo
   - Configure 2FA para Administrators

---

## 📝 Checklist de Setup por Cliente

- [ ] ✅ Rodar `setup-chatwoot-client.ps1`
- [ ] ✅ Verificar email de confirmação enviado
- [ ] ✅ Cliente confirma email e define senha
- [ ] ✅ Verificar mapeamento no Supabase (chatwoot_inbox_id preenchido)
- [ ] ✅ Testar envio de mensagem (WF0)
- [ ] ✅ Cliente faz login e vê conversas
- [ ] ✅ Testar isolamento (cliente não vê outras Inboxes)
- [ ] ✅ Configurar branding (logo, cores) - opcional
- [ ] ✅ Documentar para cliente: URL de acesso + credenciais

---

## 🎯 Próximos Passos

1. **Testar com cliente real (clinica_sorriso_001)**
   ```powershell
   .\setup-chatwoot-client.ps1 `
       -ClientId "clinica_sorriso_001" `
       -ClientName "Clínica Sorriso" `
       -ClientEmail "joao@clinicasorriso.com.br"
   ```

2. **Atualizar WF0 para usar Inbox dinâmica**
   - Modificar node "Enviar Resposta via Chatwoot"
   - Buscar `chatwoot_inbox_id` do banco

3. **Criar workflow de automação (WF-NEW-CLIENT)**
   - Trigger: novo registro em `clients`
   - Action: rodar `setup-chatwoot-client.ps1`
   - Notification: email de boas-vindas

4. **Documentar para clientes**
   - Criar PDF: "Como acessar o Chatwoot"
   - Vídeo tutorial de 2min

---

**Versão:** 1.0  
**Última atualização:** 2025-11-08  
**Status:** 📋 Pronto para uso

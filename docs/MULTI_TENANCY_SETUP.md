# Guia de Setup Multi-Tenancy - Chatwoot

Este guia explica como configurar o sistema de multi-tenancy com Chatwoot, permitindo que cada cliente tenha seu próprio Inbox isolado e Agente dedicado.

---

## 📋 Visão Geral

### Arquitetura Multi-Tenant

Cada cliente possui:
- **Inbox dedicado** no Chatwoot (isolamento de conversas)
- **Agente dedicado** com email do cliente (login isolado)
- **Mapeamento no banco de dados** (tabela `clients`)

**Benefícios:**
- 🔒 **Isolamento total**: Cliente vê apenas suas conversas
- 👤 **Acesso dedicado**: Cliente pode fazer login no Chatwoot
- 📊 **Métricas individuais**: Analytics por cliente
- 🎨 **Customização**: Configurações específicas por inbox

---

## 🗄️ Migration 007 - Multi-Tenancy Database

### Colunas Adicionadas à Tabela `clients`

```sql
-- Migration 007: database/migrations/007_add_chatwoot_multi_tenancy.sql

ALTER TABLE public.clients ADD COLUMN chatwoot_inbox_id INTEGER;
ALTER TABLE public.clients ADD COLUMN chatwoot_agent_id INTEGER;
ALTER TABLE public.clients ADD COLUMN chatwoot_agent_email TEXT;
ALTER TABLE public.clients ADD COLUMN chatwoot_access_granted BOOLEAN DEFAULT FALSE;
ALTER TABLE public.clients ADD COLUMN chatwoot_setup_at TIMESTAMPTZ;

CREATE INDEX idx_clients_chatwoot_inbox ON public.clients(chatwoot_inbox_id);
CREATE INDEX idx_clients_chatwoot_agent ON public.clients(chatwoot_agent_id);
```

### Executar Migration

**Opção 1: Via PowerShell Script**
```powershell
.\run-migration-007.ps1
```
- Tenta executar via Supabase REST API
- Se falhar, copia SQL para clipboard
- Instrui a executar manualmente no SQL Editor

**Opção 2: Manual via Supabase SQL Editor**
1. Acessar: https://supabase.com/dashboard/project/[SEU_PROJETO]/sql/new
2. Copiar conteúdo de `database/migrations/007_add_chatwoot_multi_tenancy.sql`
3. Colar e executar
4. Verificar mensagem: "Migration 007 concluída com sucesso!"

---

## 🚀 Setup de Cliente - Passo a Passo

### 1. Preparar Informações do Cliente

Você precisará de:
- **Client ID**: Identificador único (ex: `clinica_sorriso_001`)
- **Client Name**: Nome amigável (ex: `Clínica Sorriso`)
- **Client Email**: Email para acesso (ex: `contato@clinicasorriso.com.br`)

### 2. Executar Script de Setup

```powershell
.\scripts\setup-chatwoot-client.ps1 `
  -ClientId "clinica_sorriso_001" `
  -ClientName "Clínica Sorriso" `
  -ClientEmail "contato@clinicasorriso.com.br"
```

### 3. O que o Script Faz Automaticamente

**Passo 1: Criar Inbox no Chatwoot**
```http
POST /api/v1/accounts/1/inboxes
{
  "name": "Clínica Sorriso - clinica_sorriso_001",
  "channel": {
    "type": "api",
    "webhook_url": ""
  }
}
```
Resultado: `inbox_id` (ex: 2)

**Passo 2: Criar Agente no Chatwoot**
```http
POST /api/v1/accounts/1/agents
{
  "name": "Clínica Sorriso",
  "email": "contato@clinicasorriso.com.br",
  "role": "agent"
}
```
Resultado: `agent_id` (ex: 2)

**Passo 3: Adicionar Agente ao Inbox**
```http
POST /api/v1/accounts/1/inbox_members
{
  "inbox_id": 2,
  "user_ids": [2]
}
```

**Passo 4: Atualizar Banco de Dados**
```sql
UPDATE clients
SET 
  chatwoot_inbox_id = 2,
  chatwoot_agent_id = 2,
  chatwoot_agent_email = 'contato@clinicasorriso.com.br',
  chatwoot_access_granted = TRUE,
  chatwoot_setup_at = NOW()
WHERE client_id = 'clinica_sorriso_001';
```

### 4. Saída do Script

```
🎯 Configurando Multi-Tenancy Chatwoot para: clinica_sorriso_001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📥 Passo 1: Criando Inbox no Chatwoot...
✅ Inbox criado com sucesso!
   ID: 2
   Nome: Clínica Sorriso - clinica_sorriso_001

👤 Passo 2: Criando Agent no Chatwoot...
✅ Agent criado com sucesso!
   ID: 2
   Email: contato@clinicasorriso.com.br
   Senha temporária enviada para o email

🔗 Passo 3: Adicionando Agent ao Inbox...
✅ Agent adicionado ao Inbox com sucesso!

💾 Passo 4: Atualizando banco de dados Supabase...
✅ Database atualizado com sucesso!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Setup Multi-Tenancy concluído com sucesso!

📋 Resumo:
   Client ID: clinica_sorriso_001
   Inbox ID: 2
   Agent ID: 2
   Email: contato@clinicasorriso.com.br

🔑 Próximos Passos:
   1. Cliente deve confirmar email recebido
   2. Acessar: https://chatwoot.evolutedigital.com.br
   3. Fazer login com: contato@clinicasorriso.com.br
   4. Definir senha permanente
   5. Cliente verá apenas Inbox "Clínica Sorriso - clinica_sorriso_001"

🔗 Link direto do Inbox:
   https://chatwoot.evolutedigital.com.br/app/accounts/1/inbox/2
```

---

## 🔐 Cliente Fazendo Login no Chatwoot

### Passo 1: Confirmar Email

1. Cliente recebe email: **"You have been invited to join Chatwoot"**
2. Clicar no link de confirmação
3. Definir senha permanente

### Passo 2: Acessar Dashboard

1. Ir para: https://chatwoot.evolutedigital.com.br
2. Login com email do cliente
3. Ver apenas o Inbox dedicado

### Passo 3: Visualizar Conversas

- Cliente vê APENAS conversas do seu inbox
- Não vê conversas de outros clientes
- Pode responder manualmente (handoff)
- Pode ver estatísticas do seu inbox

---

## 🧪 Testar Multi-Tenancy

### Teste 1: Enviar Mensagem via API

```powershell
.\send-real-message-chatwoot.ps1 `
  -ConversationId 4 `
  -MessageBody "Teste de mensagem isolada"
```

### Teste 2: Verificar no Chatwoot

1. Login como cliente (`contato@clinicasorriso.com.br`)
2. Ver mensagem aparecer no Inbox 2
3. Confirmar que não vê outros inboxes

### Teste 3: Validar Database

```sql
SELECT 
  client_id,
  chatwoot_inbox_id,
  chatwoot_agent_id,
  chatwoot_agent_email,
  chatwoot_access_granted,
  chatwoot_setup_at
FROM clients
WHERE client_id = 'clinica_sorriso_001';
```

Resultado esperado:
```
client_id           | clinica_sorriso_001
chatwoot_inbox_id   | 2
chatwoot_agent_id   | 2
chatwoot_agent_email| contato@clinicasorriso.com.br
chatwoot_access_granted | true
chatwoot_setup_at   | 2025-11-09 08:00:00+00
```

---

## 🔧 Scripts de Manutenção

### Verificar Webhooks

```powershell
# Webhook global
.\check-chatwoot-webhooks.ps1

# Webhook específico do inbox
.\check-inbox-webhook.ps1 -InboxId 2
```

### Remover Webhooks Duplicados

```powershell
.\delete-chatwoot-webhooks.ps1
```

**⚠️ IMPORTANTE**: Webhooks podem estar em DOIS lugares:
1. **Configurações globais** (Settings → Integrations → Webhooks)
2. **Configurações do inbox** (Inbox → Settings → Webhooks)

Sempre verificar ambos para evitar loops de execução!

---

## 📊 Monitoramento

### Verificar Clientes Configurados

```sql
SELECT 
  client_id,
  client_name,
  chatwoot_inbox_id,
  chatwoot_agent_id,
  chatwoot_access_granted,
  chatwoot_setup_at
FROM clients
WHERE chatwoot_inbox_id IS NOT NULL
ORDER BY chatwoot_setup_at DESC;
```

### Verificar Inboxes no Chatwoot

```powershell
# Via PowerShell (curl)
$headers = @{
    "api_access_token" = "zL8FNtrajZjGv4LP9BrZiCif"
}
Invoke-RestMethod `
  -Uri "https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/inboxes" `
  -Headers $headers
```

---

## 🐛 Troubleshooting

### Problema: Email não chegou

**Causa**: Configuração de email do Chatwoot

**Solução**:
1. Verificar SMTP configurado no Chatwoot
2. Verificar logs: Chatwoot → Settings → Email
3. Reenviar convite manualmente:
   - Chatwoot → Settings → Agents
   - Clicar no agente → "Resend Invitation"

### Problema: Cliente vê todos os inboxes

**Causa**: Agente com role "administrator"

**Solução**:
1. Chatwoot → Settings → Agents
2. Encontrar agente do cliente
3. Alterar role para "agent" (não administrator)
4. Salvar

### Problema: Conversas não aparecem no inbox correto

**Causa**: Custom attributes `client_id` não configurados

**Solução**:
1. No Chatwoot, abrir conversa
2. Sidebar → Custom Attributes
3. Adicionar:
   ```json
   {
     "client_id": "clinica_sorriso_001",
     "agent_id": "default"
   }
   ```
4. Salvar

### Problema: Múltiplas execuções do workflow

**Causa**: Webhooks duplicados (global + inbox)

**Solução**:
```powershell
# 1. Verificar ambos
.\check-chatwoot-webhooks.ps1
.\check-inbox-webhook.ps1 -InboxId 2

# 2. Remover duplicados
.\delete-chatwoot-webhooks.ps1

# 3. Manter apenas 1 webhook
# RECOMENDADO: Webhook no inbox (não global)
```

---

## 📈 Escalonamento

### Adicionar Mais Clientes

Repetir processo para cada novo cliente:

```powershell
# Cliente 2
.\scripts\setup-chatwoot-client.ps1 `
  -ClientId "acme_corp_002" `
  -ClientName "Acme Corporation" `
  -ClientEmail "contact@acme.com"

# Cliente 3
.\scripts\setup-chatwoot-client.ps1 `
  -ClientId "dental_spa_003" `
  -ClientName "Dental Spa" `
  -ClientEmail "contato@dentalspa.com.br"
```

### Limites do Chatwoot

- **Agents**: Sem limite (plano self-hosted)
- **Inboxes**: Sem limite (plano self-hosted)
- **Conversas**: Limitado por hardware/database

---

## 🔐 Segurança

### Boas Práticas

1. **Senhas fortes**: Exigir do cliente na primeira configuração
2. **2FA**: Ativar autenticação de dois fatores (se disponível)
3. **Roles corretos**: Cliente sempre com role "agent" (nunca "administrator")
4. **Audit logs**: Monitorar acessos no Chatwoot
5. **Backup**: Backup regular do banco de dados

### Separação de Acessos

```
Administrator (você):
├─ Acesso a TODOS os inboxes
├─ Configurações globais
├─ Gerenciamento de agents
└─ Acesso ao banco de dados

Agent (cliente):
├─ Acesso APENAS ao seu inbox
├─ Sem acesso a configurações
├─ Sem acesso a outros clientes
└─ Sem acesso ao banco de dados
```

---

## 📚 Referências

- **Migration 007**: `database/migrations/007_add_chatwoot_multi_tenancy.sql`
- **Setup Script**: `scripts/setup-chatwoot-client.ps1`
- **Test Script**: `send-real-message-chatwoot.ps1`
- **Chatwoot API Docs**: https://www.chatwoot.com/docs/product/channels/api/create-channel
- **Workflow**: `workflows/WF0-Gestor-Universal-REORGANIZADO.json`

---

**Versão**: 1.0  
**Data**: 09/11/2025  
**Autor**: GitHub Copilot + Victor Castro  
**Status**: ✅ Testado e Validado

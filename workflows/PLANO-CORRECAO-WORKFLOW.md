# 🔧 PLANO DE CORREÇÃO DO WORKFLOW

## 🚨 PROBLEMAS IDENTIFICADOS

### 1. RPC NÃO ESTÁ SENDO CHAMADO
- Workflow não busca mídia do banco `client_media_rules`
- Code node espera `item.rule_id` mas nenhum node fornece isso
- **IMPACTO**: `client_media_attachments` sempre vazio

### 2. MERGE AUSENTE
- Falta combinar dados do Agente + dados do RPC
- "Construir Contexto Completo" não recebe mídia
- **IMPACTO**: `has_client_media` sempre false

### 3. NODES DE DEBUG BLOQUEANDO
- "DEBUG ANTES DO IF" e "Debug Antes Download" no caminho crítico
- **IMPACTO**: Dificulta manutenção e pode causar bugs

### 4. FLUXO DE ENVIO INCOMPLETO
- Não suporta múltiplos arquivos
- Não envia texto após anexos
- Não limpa tags `<MídiaDisponível>`
- **IMPACTO**: UX ruim (só envia 1 arquivo, sem contexto textual)

---

## ✅ CORREÇÕES NECESSÁRIAS

### CORREÇÃO 1: Adicionar RPC Call (APÓS "Filtrar Apenas Incoming")

**Inserir entre:** `Filtrar Apenas Incoming` → `Buscar Dados do Agente`

**Novo Node:**
```json
{
  "name": "Buscar Mídia Triggers (RPC)",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/check_media_triggers",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {"name": "apikey", "value": "eyJh...Qu6i"},
        {"name": "Authorization", "value": "Bearer eyJh...Qu6i"},
        {"name": "Content-Type", "value": "application/json"}
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={\"p_client_id\": \"{{ $json.client_id }}\", \"p_agent_id\": \"{{ $json.agent_id }}\", \"p_message\": \"{{ $json.message_body }}\"}"
  }
}
```

**Posição sugerida:** `[-200, -100]` (paralelo ao "Buscar Dados do Agente")

### CORREÇÃO 2: Adicionar Merge Node

**Inserir ANTES de:** `Construir Contexto Completo`

**Novo Node:**
```json
{
  "name": "Merge: Agente + Mídia",
  "type": "n8n-nodes-base.merge",
  "parameters": {
    "mode": "combine",
    "combinationMode": "mergeByPosition",
    "options": {}
  }
}
```

**Inputs:**
1. Output de "Buscar Dados do Agente (HTTP)"
2. Output de "Buscar Mídia Triggers (RPC)"

**Posição sugerida:** `[300, 96]`

### CORREÇÃO 3: Remover Nodes de Debug

**REMOVER:**
- "DEBUG ANTES DO IF" (id: 88c952c5-971e-4990-ac07-2f2cde689220)
- "Debug Antes Download" (id: ab792364-0258-4b7e-8cfa-a7aafee12a4f)

**CONECTAR DIRETO:**
- `Log Chatwoot Response` → `Tem Anexos?`
- `Tem Anexos?` → `Download Arquivo do Supabase`

### CORREÇÃO 4: Substituir Fluxo de Envio Atual

**REMOVER:**
- "Tem Anexos?" (substituir por novo IF)
- "Download Arquivo do Supabase" (substituir)
- "Upload Anexo para Chatwoot" (substituir)
- "Log Upload Resultado" (substituir)

**ADICIONAR:** 10 nodes de `NODES-ENVIO-MIDIA.json`

**INSERIR APÓS:** "Log Chatwoot Response"

---

## 📋 NOVO FLUXO (PÓS-CORREÇÃO)

```
Chatwoot Webhook
  ↓
Identificar Cliente e Agente
  ↓
Filtrar Apenas Incoming
  ├─→ Buscar Dados do Agente (HTTP)
  │     ↓
  └─→ Buscar Mídia Triggers (RPC)  ← NOVO!
        ↓
      Merge: Agente + Mídia          ← NOVO!
        ↓
      Construir Contexto Completo
        ↓
      Query RAG
        ↓
      Preparar Prompt LLM
        ↓
      LLM (GPT-4o-mini)
        ↓
      Preservar Contexto
        ↓
      Chamou Tool?
        ↓
      Construir Resposta Final
        ↓
      Tem Mídia do Acervo?
        ↓
      [Log + Usage Tracking]
        ↓
      Preservar Dados Após Usage
        ↓
      Enviar Resposta via Chatwoot
        ↓
      Log Chatwoot Response
        ↓
      1️⃣ Detectar Mídia na Resposta   ← NOVO!
        ↓
      2️⃣ Tem Mídia para Enviar?       ← NOVO!
        ├─ SIM:
        │  3️⃣ Preparar Arquivos
        │  4️⃣ Loop: Cada Arquivo
        │  5️⃣ Download do Supabase
        │  6️⃣ Upload para Chatwoot
        │  7️⃣ Log Envio
        │  9️⃣ Preparar Texto Final
        │  🔟 Enviar Texto
        └─ NÃO:
           8️⃣ Enviar Texto (Sem Mídia)
```

---

## 🎯 RESULTADOS ESPERADOS

**ANTES (bugado):**
- ❌ RPC não é chamado
- ❌ `client_media_attachments` sempre vazio
- ❌ Bot promete enviar mas nunca envia
- ❌ Só 1 arquivo por vez
- ❌ Sem texto explicativo após arquivo

**DEPOIS (corrigido):**
- ✅ RPC busca triggers no banco
- ✅ `client_media_attachments` populado
- ✅ Bot envia arquivo + texto
- ✅ Suporta múltiplos arquivos
- ✅ Texto limpo sem tags

---

## 📦 ARQUIVOS A CRIAR

1. **workflow-corrected-structure.json** - Novo fluxo completo
2. **rpc-node-config.json** - Configuração do node RPC
3. **merge-node-config.json** - Configuração do Merge
4. **test-rpc-direct.ps1** - Script de teste do RPC isolado

---

## ⏱️ ESTIMATIVA

- Adicionar RPC + Merge: **10 min**
- Remover debug nodes: **2 min**
- Adicionar novo fluxo de envio: **15 min**
- Testar no WhatsApp: **10 min**
- **TOTAL: ~40 minutos**

---

## 🚀 ORDEM DE EXECUÇÃO

1. ✅ Adicionar node "Buscar Mídia Triggers (RPC)"
2. ✅ Adicionar node "Merge: Agente + Mídia"
3. ✅ Conectar RPC → Merge ← Agente
4. ✅ Conectar Merge → Construir Contexto Completo
5. ✅ Remover "DEBUG ANTES DO IF"
6. ✅ Remover "Debug Antes Download"
7. ✅ Remover fluxo antigo (Tem Anexos? → Upload)
8. ✅ Adicionar 10 nodes de NODES-ENVIO-MIDIA.json
9. ✅ Conectar após "Log Chatwoot Response"
10. ✅ Testar: "quero ver a clínica"

---

**PRÓXIMO PASSO:** Criar scripts/configurações para cada correção?

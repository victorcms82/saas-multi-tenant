# 🔧 CORREÇÃO MÍNIMA - RPC + MERGE

## 🎯 OBJETIVO
Adicionar chamada RPC para buscar mídia do banco e combinar com dados do agente.

## 📦 2 NODES NOVOS

### NODE 1: Buscar Mídia Triggers (RPC)

**Inserir:** Entre "Filtrar Apenas Incoming" e "Construir Contexto Completo"  
**Paralelo a:** "Buscar Dados do Agente (HTTP)"  
**Posição sugerida:** `[-16, -100]`

```json
{
  "parameters": {
    "method": "POST",
    "url": "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/check_media_triggers",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpCustomAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "apikey",
          "value": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
        },
        {
          "name": "Authorization",
          "value": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
        },
        {
          "name": "Content-Type",
          "value": "application/json"
        },
        {
          "name": "Prefer",
          "value": "return=representation"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={\n  \"p_client_id\": \"{{ $json.client_id }}\",\n  \"p_agent_id\": \"{{ $json.agent_id }}\",\n  \"p_message\": \"{{ $json.message_body }}\"\n}",
    "options": {}
  },
  "name": "Buscar Mídia Triggers (RPC)",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [-16, -100],
  "id": "rpc-media-triggers",
  "credentials": {
    "httpCustomAuth": {
      "id": "NEn6NpNWjE7hCyWQ",
      "name": "Supabase API"
    }
  }
}
```

### NODE 2: Merge (Agente + Mídia)

**Inserir:** Antes de "Construir Contexto Completo"  
**Posição sugerida:** `[300, 96]`

```json
{
  "parameters": {
    "mode": "combine",
    "combinationMode": "mergeByPosition",
    "options": {}
  },
  "name": "Merge: Agente + Mídia",
  "type": "n8n-nodes-base.merge",
  "typeVersion": 2.1,
  "position": [300, 96],
  "id": "merge-agente-midia"
}
```

## 🔌 CONEXÕES

### REMOVER (1 conexão):
```
"Buscar Dados do Agente (HTTP)" → "Construir Contexto Completo"
```

### ADICIONAR (4 conexões):

1. **Filtrar Apenas Incoming → Buscar Mídia Triggers (RPC)**
```json
"Filtrar Apenas Incoming": {
  "main": [
    [
      {"node": "Buscar Dados do Agente (HTTP)", "type": "main", "index": 0},
      {"node": "Buscar Mídia Triggers (RPC)", "type": "main", "index": 0}
    ]
  ]
}
```

2. **Buscar Dados do Agente → Merge (input 1)**
```json
"Buscar Dados do Agente (HTTP)": {
  "main": [
    [
      {"node": "Merge: Agente + Mídia", "type": "main", "index": 0}
    ]
  ]
}
```

3. **Buscar Mídia Triggers → Merge (input 2)**
```json
"Buscar Mídia Triggers (RPC)": {
  "main": [
    [
      {"node": "Merge: Agente + Mídia", "type": "main", "index": 1}
    ]
  ]
}
```

4. **Merge → Construir Contexto Completo**
```json
"Merge: Agente + Mídia": {
  "main": [
    [
      {"node": "Construir Contexto Completo", "type": "main", "index": 0}
    ]
  ]
}
```

## 🧪 TESTE ANTES DE CONTINUAR

Após adicionar esses 2 nodes, testar com pinData:

```json
{
  "body": {
    "content": "quero ver a clínica",
    "conversation": {
      "custom_attributes": {
        "client_id": "clinica_sorriso_001",
        "agent_id": "default"
      },
      "id": 99999
    }
  }
}
```

### VALIDAÇÃO:

1. ✅ **RPC executado?** - Logs devem mostrar chamada para check_media_triggers
2. ✅ **Mídia encontrada?** - RPC deve retornar rule_id, media_id, file_url
3. ✅ **Merge funcionou?** - "Construir Contexto Completo" deve receber ambos os dados
4. ✅ **client_media_attachments populado?** - Array não deve estar vazio

### LOGS ESPERADOS:

```
=== CONSTRUIR CONTEXTO DEBUG ===
item.rule_id: [UUID]
item.media_id: [UUID]
item.file_url: https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/...
mediaRules.length: 1
client_media_attachments.length: 1
```

## ⏭️ PRÓXIMO PASSO

**SE VALIDAÇÃO OK:**
- Adicionar 10 nodes de envio de mídia
- Remover nodes de debug
- Testar no WhatsApp

**SE VALIDAÇÃO FALHAR:**
- Debug do RPC (testar diretamente com curl)
- Verificar se function check_media_triggers existe
- Verificar triggers no banco

---

**TEMPO ESTIMADO:** 10 minutos para adicionar + 5 minutos para validar

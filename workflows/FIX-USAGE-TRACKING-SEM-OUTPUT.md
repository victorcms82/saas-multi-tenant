# 🔧 FIX: Node "Atualizar Usage Tracking" sem output

## 🚨 PROBLEMA IDENTIFICADO

O node **"Atualizar Usage Tracking (HTTP)"** está travando (sem output) porque:

1. **Faz um PATCH** na tabela `client_subscriptions`
2. **PATCH requer registro existente** 
3. Provavelmente **NÃO EXISTE** registro para `client_id="estetica_bella_rede"` + `agent_id="default"`

**Query atual no node:**
```
PATCH /rest/v1/client_subscriptions?client_id=eq.{{$json.client_id}}&agent_id=eq.{{$json.agent_id}}
```

Se não existir registro, **PATCH retorna array vazio** `[]` e o workflow trava!

---

## ✅ SOLUÇÃO 1: Inserir registro no banco (RÁPIDO)

Vamos inserir manualmente o registro que falta:

```sql
-- Verificar se existe
SELECT * FROM client_subscriptions 
WHERE client_id = 'estetica_bella_rede' 
  AND agent_id = 'default';

-- Se retornar vazio, inserir:
INSERT INTO client_subscriptions (
  client_id,
  agent_id,
  template_id,
  template_snapshot,
  status,
  monthly_price,
  subscription_start_date
)
VALUES (
  'estetica_bella_rede',
  'default',
  'bella-default-template',
  '{}'::jsonb,
  'active',
  199.00,
  NOW()
)
ON CONFLICT (client_id, agent_id) DO NOTHING;
```

---

## ✅ SOLUÇÃO 2: Alterar node para UPSERT (MELHOR)

Alterar o node para fazer **UPSERT** (INSERT ou UPDATE):

### **Passo 1: Mudar método de PATCH para POST**

No node "Atualizar Usage Tracking (HTTP)":
- **Method:** `POST` (ao invés de `PATCH`)

### **Passo 2: Adicionar header de upsert**

Na seção **Headers**, adicionar:
```
Prefer: resolution=merge-duplicates,return=representation
```

### **Passo 3: Alterar body**

Trocar o body de:
```json
{
  "updated_at": "{{$now}}"
}
```

Para:
```json
{
  "client_id": "{{ $json.client_id }}",
  "agent_id": "{{ $json.agent_id }}",
  "template_id": "default-template",
  "template_snapshot": {},
  "status": "active",
  "monthly_price": 0,
  "subscription_start_date": "{{ $now }}",
  "updated_at": "{{ $now }}"
}
```

### **Passo 4: Remover query parameters**

Como agora é POST (não PATCH), **REMOVER** os query parameters:
- ❌ Apagar: `client_id=eq.{{$json.client_id}}`
- ❌ Apagar: `agent_id=eq.{{$json.agent_id}}`

---

## 🚀 SOLUÇÃO 3: Tornar node opcional (TEMPORÁRIO)

Se quiser apenas testar o workflow, você pode:

1. **Clicar no node** "Atualizar Usage Tracking (HTTP)"
2. **Settings** → **Continue On Fail:** `ON`
3. **Salvar**

Isso fará o workflow continuar mesmo se o node falhar.

---

## 📝 RECOMENDAÇÃO

**Fazer SOLUÇÃO 1 + SOLUÇÃO 2:**

1. **Imediato:** Inserir registro via SQL (SOLUÇÃO 1) para destravar
2. **Permanente:** Alterar node para UPSERT (SOLUÇÃO 2) para funcionar sempre

---

## 🧪 TESTE RÁPIDO

Execute este script PowerShell para verificar se existe o registro:

```powershell
$headers = @{
  "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
  "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
}

Write-Host "`n🔍 Verificando client_subscriptions..." -ForegroundColor Cyan

$response = Invoke-RestMethod `
  -Uri "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/client_subscriptions?client_id=eq.estetica_bella_rede&agent_id=eq.default" `
  -Method Get `
  -Headers $headers

if ($response.Count -eq 0) {
  Write-Host "❌ NÃO EXISTE registro! Workflow vai travar." -ForegroundColor Red
  Write-Host "   Execute a SOLUÇÃO 1 (INSERT via SQL)" -ForegroundColor Yellow
} else {
  Write-Host "✅ Registro existe!" -ForegroundColor Green
  $response | ConvertTo-Json -Depth 2
}
```

---

## 🎯 QUAL SOLUÇÃO USAR AGORA?

**Se você quer destravar AGORA (5 minutos):**
- ✅ **SOLUÇÃO 1:** Executar INSERT via Supabase SQL Editor

**Se você quer corrigir de vez (15 minutos):**
- ✅ **SOLUÇÃO 2:** Alterar node para UPSERT

**Quer só testar e ignorar erro:**
- ⚠️ **SOLUÇÃO 3:** Ativar "Continue On Fail"

---

**Me diz qual solução você quer aplicar!** 🚀

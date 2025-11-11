# 🔒 SEGURANÇA CRÍTICA: Blindagem de client_id

## 🚨 PROBLEMA IDENTIFICADO

Durante os testes, descobrimos que o workflow estava usando `client_id: clinica_sorriso_001` **mesmo quando o inbox_id=3 pertencia à `estetica_bella_rede`**.

Isso representa uma **vulnerabilidade crítica de segurança**:
- ❌ Dados de um tenant sendo usados para outro
- ❌ Possibilidade de spoofing de client_id via webhook
- ❌ Vazamento de informações entre clientes
- ❌ Violação de multi-tenancy

---

## ✅ SOLUÇÃO IMPLEMENTADA: 3 Camadas de Segurança

### **Camada 1: RPC Confiável**
O `get_location_staff_summary(inbox_id)` busca o `client_id` **diretamente do banco de dados**:

```sql
-- O RPC faz JOIN entre locations e a source of truth
SELECT l.client_id, l.location_id, l.name, ...
FROM locations l
WHERE l.chatwoot_inbox_id = p_inbox_id
  AND l.is_active = TRUE;
```

**Resultado**: 
- `inbox_id = 3` → `client_id = estetica_bella_rede` ✅ (do banco, não do webhook!)

---

### **Camada 2: Sobrescrita Forçada no Node**

O node **"💼 Construir Contexto Location + Staff"** agora **SOBRESCREVE** o `client_id`:

```javascript
return {
  json: {
    ...webhookData,  // Pega todos os dados do webhook
    // 🔒 CRÍTICO: Sobrescrever client_id com valor do banco!
    client_id: location.client_id,  // ← Vem do RPC, não do webhook
    location_context: locationContext,
    // ... resto dos dados
  }
};
```

**Antes** (INSEGURO):
```json
{
  "client_id": "clinica_sorriso_001",  ← do webhook ou node anterior
  "location_context": "Bella Barra data..."
}
```

**Depois** (SEGURO):
```json
{
  "client_id": "estetica_bella_rede",  ← do banco via RPC ✅
  "location_context": "Bella Barra data..."
}
```

---

### **Camada 3: Validação no Buscar Dados do Agente**

O node "Buscar Dados do Agente (HTTP)" **DEVE** usar:

```javascript
// URL do RPC ou query
.../rpc/get_agent_data

// Body
{
  "client_id": "{{ $json.client_id }}"  ← Agora é seguro!
}
```

Como o `client_id` foi sobrescrito no node anterior, **TODOS os nodes seguintes** usam o valor correto.

---

## 🧪 VALIDAÇÃO DA SEGURANÇA

### Teste 1: Verificar no Banco
```sql
-- Confirmar mapeamento inbox → client
SELECT chatwoot_inbox_id, client_id, name 
FROM locations 
WHERE chatwoot_inbox_id = 3;
```

**Resultado esperado**:
```
chatwoot_inbox_id | client_id           | name
------------------+---------------------+-------------
                3 | estetica_bella_rede | Bella Barra
```

---

### Teste 2: Verificar no Workflow (n8n)

**Passo 1**: Envie mensagem pelo inbox_id = 3  
**Passo 2**: Veja output do node "💼 Construir Contexto Location + Staff"

**Output esperado**:
```json
{
  "client_id": "estetica_bella_rede",  ✅
  "location_name": "Bella Barra",
  "location_context": "..."
}
```

**Passo 3**: Veja output do node "Construir Contexto Completo"

**Output esperado**:
```json
{
  "client_id": "estetica_bella_rede",  ✅ (mantido!)
  "system_prompt": "... Bella Estética ...",  ✅ (prompt correto!)
  "location_context": "... Ana Paula Silva ..."
}
```

---

### Teste 3: Verificar Resposta do LLM

Envie: `"Quais profissionais vocês têm?"`

**Resposta esperada**:
> "Temos Ana Paula Silva (Harmonização Facial), Beatriz Costa (Tratamentos Faciais), Carlos Mendes (Laser) e Eduardo Lima (Tratamentos Corporais) aqui na Bella Barra!"

**NÃO DEVE** responder:
> "Sou a Carla da Clínica Sorriso" ❌

---

## 📋 CHECKLIST DE SEGURANÇA

- [ ] Migration 013 executada (RPC get_location_staff_summary)
- [ ] chatwoot_inbox_id configurado nas 4 locations
- [ ] Arquivo `NODES-MULTI-LOCATION-DETECTION-SECURE.json` importado no n8n
- [ ] Nodes conectados na ordem correta
- [ ] Teste 1 realizado (query no banco) → client_id correto
- [ ] Teste 2 realizado (output do node) → client_id sobrescrito
- [ ] Teste 3 realizado (resposta do LLM) → prompt correto

---

## 🔧 COMO APLICAR A CORREÇÃO

### Opção 1: Re-importar Nodes (RECOMENDADO)

1. **Delete os 2 nodes antigos** no n8n:
   - 🏢 Detectar Localização e Staff (RPC)
   - 💼 Construir Contexto Location + Staff

2. **Importe a versão segura**:
   - Abra `workflows/NODES-MULTI-LOCATION-DETECTION-SECURE.json`
   - Copie TODO o conteúdo (Ctrl+A, Ctrl+C)
   - No n8n: Settings → Import from Clipboard
   - Cole e clique em Import

3. **Reconecte os nodes**:
   - Filtrar Apenas Incoming (TRUE) → 🏢 Detectar Localização
   - 🏢 Detectar Localização → 💼 Construir Contexto
   - 💼 Construir Contexto → Buscar Dados do Agente

4. **Salve o workflow**

---

### Opção 2: Editar Manualmente (se preferir)

**No node "💼 Construir Contexto Location + Staff"**, localize o `return` final e **adicione** esta linha:

```javascript
return {
  json: {
    ...webhookData,
    // 🔒 ADICIONAR ESTA LINHA:
    client_id: location.client_id,
    // (resto do código continua igual)
```

---

## 🛡️ POR QUE ISSO É CRÍTICO?

### Cenário de Ataque (antes da correção):

1. **Hacker** descobre que existe um webhook no n8n
2. Envia payload malicioso:
   ```json
   {
     "client_id": "empresa_concorrente_xyz",
     "inbox_id": 3
   }
   ```
3. Workflow usa `client_id` do payload ❌
4. **VAZAMENTO**: Hacker recebe dados de outro cliente!

### Após a Correção:

1. Hacker envia payload malicioso
2. Workflow **IGNORA** o `client_id` do payload
3. Busca o `client_id` correto no banco via RPC (inbox_id = 3 → estetica_bella_rede)
4. **BLOQUEADO**: Hacker só recebe dados do inbox_id dele ✅

---

## 📚 DOCUMENTAÇÃO RELACIONADA

- `database/migrations/013_create_rpc_location_detection.sql` → RPC que retorna client_id
- `workflows/NODES-MULTI-LOCATION-DETECTION-SECURE.json` → Versão corrigida dos nodes
- `workflows/GUIA-INSTALACAO-MULTI-LOCATION.md` → Instruções de instalação

---

## ⚠️ IMPORTANTE PARA PRODUÇÃO

Antes de ir para produção:

1. ✅ **Validar TODOS os tenants**:
   ```sql
   SELECT client_id, chatwoot_inbox_id, name, is_active
   FROM locations
   ORDER BY client_id, location_id;
   ```

2. ✅ **Testar com inbox_ids reais** de cada cliente

3. ✅ **Adicionar logs de auditoria**:
   ```javascript
   console.log('🔒 Security: client_id authenticated:', location.client_id);
   console.log('📍 inbox_id:', p_inbox_id);
   console.log('🏢 location:', location.location_name);
   ```

4. ✅ **Configurar alertas** se `client_id` do webhook ≠ `client_id` do RPC

5. ✅ **Row Level Security (RLS)** no Supabase para camada extra de proteção

---

**Versão**: 2.0.0-SECURE  
**Data**: 2025-11-11  
**Autor**: GitHub Copilot  
**Prioridade**: 🔴 CRÍTICA

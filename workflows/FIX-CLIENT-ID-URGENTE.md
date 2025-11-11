# 🔧 FIX URGENTE: Blindagem de client_id no Construir Contexto Completo

## 🚨 PROBLEMA DETECTADO

O node **"Construir Contexto Completo"** está pegando o `client_id` de forma **INSEGURA**:

```javascript
// ❌ INSEGURO: Pega do item (que vem do Merge e pode estar errado)
client_id: item.client_id || webhookNode.client_id,
```

**Risco:** O Merge pode ter embaralhado a ordem dos dados, fazendo o `client_id` vir do lugar errado!

---

## ✅ SOLUÇÃO: Buscar client_id DIRETO do node autenticado

Buscar o `client_id` **DIRETO do node** `💼 Construir Contexto Location + Staff1`, que foi autenticado pelo banco de dados via RPC.

---

## 📝 COMO APLICAR O FIX

### **Passo 1: Abrir o n8n**

1. Acesse: https://n8n.evolutedigital.com.br
2. Abra o workflow **WF0-Gestor-Universal**

---

### **Passo 2: Localizar o node "Construir Contexto Completo"**

1. Procure o node **Code** chamado "Construir Contexto Completo"
2. Ele está logo após o node "Merge: Agente + Mídia"

---

### **Passo 3: Editar o código**

1. **Clique** no node "Construir Contexto Completo"
2. **Clique** em "Edit Code"
3. **SUBSTITUA TUDO** pelo código do arquivo: `workflows/FIX-CONSTRUIR-CONTEXTO-COMPLETO.js`

**OU**

Localize estas linhas no início do código:

```javascript
const item = $input.item.json;
const locationContext = item.location_context || '';

// Buscar dados originais do webhook do node 'Filtrar Apenas Incoming'
// O Merge preserva os dados, mas precisamos garantir que message_body não seja sobrescrito
const webhookNode = $('Filtrar Apenas Incoming').first().json;

const webhookData = {
  // 🔒 CRÍTICO: Pegar client_id do item PRIMEIRO (vem do RPC com client_id correto)
  client_id: item.client_id || webhookNode.client_id,
```

**E SUBSTITUA por:**

```javascript
const item = $input.item.json;

// 🔒 SEGURANÇA CRÍTICA: Buscar client_id do node que fez a blindagem!
const locationNode = $('💼 Construir Contexto Location + Staff1').first().json;
const webhookNode = $('Filtrar Apenas Incoming').first().json;

// Extrair location_context do node correto
const locationContext = locationNode.location_context || item.location_context || '';

// 🔒 CRÍTICO: client_id SEMPRE vem do node de location (autenticado pelo banco!)
const clientId = locationNode.client_id || item.client_id || webhookNode.client_id;

console.log('=== SEGURANÇA: Origem do client_id ===');
console.log('locationNode.client_id:', locationNode.client_id);
console.log('item.client_id:', item.client_id);
console.log('webhookNode.client_id:', webhookNode.client_id);
console.log('🔒 client_id FINAL (autenticado):', clientId);

const webhookData = {
  // 🔒 CRÍTICO: Usar client_id autenticado do banco!
  client_id: clientId,
```

---

### **Passo 4: Salvar**

1. **Clique em "Save"** no editor de código
2. **Clique em "Save"** no workflow (canto superior direito)

---

## 🧪 COMO TESTAR

### **Teste 1: Verificar logs no n8n**

1. **Execute o workflow** com o pinData (ou envie mensagem real)
2. **Abra o node** "Construir Contexto Completo"
3. **Veja o output** e procure os logs:

**Logs esperados:**
```
=== SEGURANÇA: Origem do client_id ===
locationNode.client_id: estetica_bella_rede
item.client_id: clinica_sorriso_001
webhookNode.client_id: clinica_sorriso_001
🔒 client_id FINAL (autenticado): estetica_bella_rede
```

✅ **Correto:** `client_id FINAL` deve ser `estetica_bella_rede` (do locationNode)

❌ **Errado:** Se `client_id FINAL` for `clinica_sorriso_001`, o fix não funcionou

---

### **Teste 2: Verificar resposta do LLM**

**Envie mensagem:** `"Quais profissionais vocês têm?"`

**Resposta esperada:**
> "Temos Ana Paula Silva (Harmonização Facial), Beatriz Costa (Tratamentos Faciais)... aqui na **Bella Barra**!"

**NÃO DEVE responder:**
> "Sou a Carla da **Clínica Sorriso**" ❌

---

### **Teste 3: Verificar no banco**

```sql
-- Confirmar que inbox_id = 3 é da Bella
SELECT chatwoot_inbox_id, client_id, name 
FROM locations 
WHERE chatwoot_inbox_id = 3;

-- Resultado esperado:
-- chatwoot_inbox_id | client_id           | name
-- ------------------+---------------------+-------------
--                 3 | estetica_bella_rede | Bella Barra
```

---

## 📊 IMPACTO DA CORREÇÃO

### **Antes (INSEGURO):**
```
Merge embaralha dados
   ↓
item.client_id = "clinica_sorriso_001" ❌ (do webhook)
   ↓
LLM usa system_prompt errado
   ↓
Resposta menciona "Clínica Sorriso" ❌
```

### **Depois (SEGURO):**
```
Busca DIRETO do node location
   ↓
locationNode.client_id = "estetica_bella_rede" ✅ (do banco)
   ↓
LLM usa system_prompt correto
   ↓
Resposta menciona "Bella Estética" ✅
```

---

## ⚠️ POR QUE ISSO É CRÍTICO?

1. **Vazamento de dados entre tenants:**
   - Cliente A (Bella) recebe dados do Cliente B (Clínica Sorriso)
   
2. **Violação de privacidade:**
   - Profissionais, serviços, preços de um cliente expostos para outro

3. **Compliance:**
   - LGPD: Dados pessoais (profissionais) vazados
   - Contrato: Violação de multi-tenancy garantido

4. **Reputação:**
   - Cliente descobre que recebeu dados de concorrente
   - Perda de confiança na plataforma

---

## 📋 CHECKLIST

- [ ] Código do node "Construir Contexto Completo" atualizado
- [ ] Workflow salvo
- [ ] Teste 1 realizado (logs mostram client_id correto)
- [ ] Teste 2 realizado (LLM responde com dados da Bella)
- [ ] Teste 3 realizado (query no banco confirma inbox→client correto)
- [ ] Documentação atualizada (este arquivo)

---

## 🎯 PRÓXIMOS PASSOS

Depois de aplicar este fix:

1. **Testar com todos os inboxes:**
   - inbox_id = 1 → clinica_sorriso_001
   - inbox_id = 2 → (outro cliente)
   - inbox_id = 3 → estetica_bella_rede
   - inbox_id = 4 → (outro cliente)

2. **Adicionar alerta de segurança:**
   - Se `locationNode.client_id ≠ webhookNode.client_id`, logar WARNING

3. **Implementar Row Level Security (RLS) no Supabase:**
   - Camada adicional de proteção no banco de dados

---

**Versão:** 1.0  
**Data:** 11/11/2025  
**Prioridade:** 🔴 **CRÍTICA**  
**Status:** ⏳ **Pendente aplicação**

---

**Perguntas? Problemas ao aplicar?**  
Documente aqui embaixo! 👇

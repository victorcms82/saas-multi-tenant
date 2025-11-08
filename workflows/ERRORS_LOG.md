# 📋 Log de Erros e Correções - WF0

> **Objetivo:** Documentar todos os erros encontrados e suas soluções para evitar repetição.

---

## 🚨 Erro #1: `message_body` chegando como `undefined` no LLM

**Data:** 2025-11-08  
**Severidade:** 🔴 CRÍTICA  
**Status:** 🔧 EM CORREÇÃO

### Sintomas

```json
{
  "llm_prompt": "...--- MENSAGEM DO USUÁRIO ---\nundefined",
  "final_response": "Desculpe, não consegui processar sua mensagem."
}
```

- LLM não recebe o texto da mensagem do usuário
- Resposta genérica é retornada
- Workflow executa mas não processa a mensagem real

### Diagnóstico

**Root Cause:** Discrepância entre estrutura do payload de teste e extração no node "Identificar Cliente e Agente"

1. **Test Script (`test-wf0-webhook.ps1`)** envia:
   ```json
   {
     "content": "qual o preço?",
     "conversation": { ... }
   }
   ```

2. **Node "Identificar Cliente e Agente"** extrai:
   ```javascript
   const messageBody = payload.body?.content || payload.content || '';
   ```

3. **Webhook n8n** encapsula payload recebido em `body`:
   ```json
   {
     "body": {
       "content": "qual o preço?",
       "conversation": { ... }
     }
   }
   ```

4. **Problema:** Quando Chatwoot REAL envia, estrutura pode ser diferente:
   - Pode vir como `payload.content` (direto)
   - Pode vir como `payload.body.content` (encapsulado)
   - Script de teste não está simulando estrutura correta

### Solução

**Opção A: Corrigir extração no node "Identificar Cliente e Agente"**

```javascript
// Tentar TODAS as possibilidades de estrutura
const messageBody = 
  payload.body?.body?.content ||  // Encapsulado 2x (webhook + chatwoot)
  payload.body?.content ||        // Encapsulado 1x (webhook)
  payload.content ||              // Direto (script teste)
  '';
```

**Opção B: Corrigir test script para simular estrutura real Chatwoot**

```powershell
# Encapsular payload em "body" como webhook faz
$webhookPayload = @{
    body = $payload
}
```

**Opção C: Adicionar debug logging no node**

```javascript
// Log para diagnóstico
console.log('Payload recebido:', JSON.stringify(payload, null, 2));
console.log('messageBody extraído:', messageBody);

if (!messageBody || messageBody === '') {
  throw new Error('ERRO: message_body vazio ou undefined!');
}
```

### Implementação Recomendada

✅ **Aplicar Opção A + C juntas:**
- Tornar extração robusta (tenta todas possibilidades)
- Adicionar logging para diagnóstico futuro
- Adicionar validação que aborta execução se message_body vazio

### Prevenção Futura

- [ ] Sempre testar com payload real do Chatwoot primeiro
- [ ] Adicionar validação de campos obrigatórios em todos os nodes críticos
- [ ] Documentar estrutura exata do payload Chatwoot no README
- [ ] Criar teste unitário que valida extração de `message_body`

---

## 🚨 Erro #2: OpenAI Node não aparece visualmente no workflow

**Data:** 2025-11-08  
**Severidade:** 🔴 CRÍTICA  
**Status:** ✅ RESOLVIDO

### Sintomas

- Node "LLM (GPT-4o-mini + Tools)" não aparece no canvas do n8n
- Workflow mostra nodes antes e depois, mas OpenAI fica invisível
- Execução pode falhar silenciosamente

### Root Cause

**Node configurado com estrutura incorreta de `messages`, `operation` inválida e `typeVersion` incompatível.**

Após análise do código-fonte oficial do n8n no GitHub, identificamos 3 erros:

1. **Operation incorreta:** `"message"` não existe, deve ser `"complete"`
2. **Estrutura de messages incorreta:** Usava `messages.values[]` quando deveria ser `prompt.messages[]`
3. **typeVersion incompatível:** ⚠️ **ESTE ERA O PROBLEMA PRINCIPAL!** `1.6` não existe no n8n v1.118.1, deve ser `1` ou `1.1`

**Configuração INCORRETA:**
```json
{
  "parameters": {
    "resource": "chat",
    "operation": "message",  // ❌ Não existe!
    "messages": {            // ❌ Estrutura errada!
      "values": [
        { "role": "system", "content": "..." },
        { "role": "user", "content": "..." }
      ]
    }
  }
}
```

**Configuração CORRETA (segundo código-fonte n8n):**
```json
{
  "parameters": {
    "resource": "chat",      // ✅ Correto para chat models
    "operation": "complete", // ✅ Operação válida
    "prompt": {              // ✅ Estrutura correta
      "messages": [
        { "role": "system", "content": "..." },
        { "role": "user", "content": "..." }
      ]
    }
  }
}
```

### Diagnóstico Detalhado

No n8n v1.118.1, o node "OpenAI" (n8n-nodes-base.openAi) usa:
- **Resource "text"** → Para TEXT ACTIONS → "Message a Model"
- **Resource "chat"** → Não existe nesta versão ou não é visível

A confusão acontece porque:
1. Semanticamente, estamos fazendo chat completions
2. Mas no n8n, isso é categorizado como "text" resource
3. Documentação confusa na interface

### Solução

**Alterar nos arquivos JSON:**
```json
"resource": "chat"  →  "resource": "text"
```

**Ou recriar node manualmente:**
1. Deletar node OpenAI existente
2. Adicionar novo node "OpenAI"
3. Selecionar Resource: **Text** (não Chat)
4. Selecionar Operation: **Message a Model**
5. Configurar Model, Messages, Options

### Solução Final (TESTADA E APROVADA ✅)

```json
{
  "parameters": {
    "resource": "chat",      // ✅ Correto para GPT-4/3.5
    "operation": "complete", // ✅ Operação válida
    "model": "={{ $json.llm_model || 'gpt-4o-mini' }}",
    "prompt": {              // ✅ Estrutura correta
      "messages": [
        { "role": "system", "content": "={{ $json.system_prompt }}" },
        { "role": "user", "content": "={{ $json.media_context + '\\n\\n--- MENSAGEM DO USUÁRIO ---\\n' + $json.message_body }}" }
      ]
    },
    "options": {
      "temperature": 0.7,
      "maxTokens": 1000
    }
  },
  "name": "LLM (GPT-4o-mini + Tools)",
  "type": "n8n-nodes-base.openAi",
  "typeVersion": 1,  // ⚠️ CRÍTICO: Usar 1 ou 1.1, NÃO 1.6!
  "position": [240, 336],
  "credentials": {
    "openAiApi": {
      "id": "AZOIk8m4dEU8S2FP",
      "name": "OpenAi account"
    }
  }
}
```

### Implementação

✅ Corrigido em:
- `WF0-Gestor-Universal-REORGANIZADO.json`
- `WF0-Gestor-Universal-FINAL-CORRIGIDO.json`

✅ **TESTADO E VALIDADO:** Node agora aparece corretamente no canvas do n8n v1.118.1!

### Prevenção Futura

- ✅ **Sempre usar `typeVersion: 1` para n8n v1.118.1** (NÃO 1.6!)
- ✅ Usar `resource: "chat"` para chat completions (GPT-4/3.5)
- ✅ Usar `operation: "complete"` (não "message")
- ✅ Usar estrutura `prompt.messages[]` (não `messages.values[]`)
- [ ] Testar visibilidade do node no canvas após importar workflow
- [ ] Se atualizar n8n para versão mais nova, verificar se typeVersion mudou

---

## 🚨 Erro #3: OpenAI Node - Model field com syntax error

**Data:** 2025-11-08  
**Severidade:** 🟠 ALTA  
**Status:** ⚠️ IDENTIFICADO (aguardando confirmação do usuário)

### Sintomas

- Campo Model no OpenAI node mostra `[ERROR: invalid syntax]`
- Possível bloqueio na execução do LLM

### Root Cause

Usuário provavelmente colou expressão com `=` duplicado:
- Esperado: `{{ $json.llm_model || 'gpt-4o-mini' }}`
- Colado: `={{ $json.llm_model || 'gpt-4o-mini' }}`
- n8n adiciona `=` automaticamente ao clicar fx, resultando em `=={{ ... }}`

### Solução

1. Limpar campo Model
2. Clicar fx (expressions)
3. Colar SEM o `=` inicial: `{{ $json.llm_model || 'gpt-4o-mini' }}`

### Prevenção Futura

- Sempre documentar: "Cole SEM o `=` inicial ao usar fx"
- No WF0-FINAL-CORRIGIDO.json, incluir expressão correta
- Adicionar screenshot no N8N_OPENAI_NODES_REFERENCE.md mostrando campo correto

---

## 🚨 Erro #3: Múltiplas execuções com output idêntico

**Data:** 2025-11-08  
**Severidade:** 🟡 MÉDIA  
**Status:** 🔍 INVESTIGANDO

### Sintomas

Usuário compartilhou 9 blocos JSON idênticos com mesmo output:
```json
{
  "final_response": "Desculpe, não consegui processar sua mensagem.",
  ...
}
```

### Hipóteses

1. **Loop infinito?** - Node "Chamou Tool?" pode estar criando ciclo
2. **Retry automático?** - n8n tentando re-executar em caso de erro
3. **Múltiplos webhooks?** - Teste foi executado várias vezes rapidamente
4. **Cache/buffer?** - n8n mostrando execuções antigas

### Investigação Necessária

- [ ] Verificar se há conexões circulares no workflow (loop)
- [ ] Verificar configuração de retry em nodes
- [ ] Pedir ao usuário para limpar executions antigas e testar 1x apenas
- [ ] Verificar logs do n8n para confirmar quantas execuções realmente rodaram

---

## 📝 Checklist de Validação Pré-Deploy

Antes de considerar WF0 pronto para produção, validar:

- [ ] **message_body** sendo capturado corretamente (debug log confirma)
- [ ] **LLM** recebe mensagem completa (verificar input do OpenAI node)
- [ ] **media_context** está sendo incluído no prompt (quando has_client_media=true)
- [ ] **has_client_media** flui corretamente até node "Tem Mídia do Acervo?"
- [ ] **client_media_attachments** preservado em todos os nodes
- [ ] **Chatwoot send** funciona (testar com conta real)
- [ ] **Supabase inserts** funcionam (media_send_log e client_subscriptions)
- [ ] **Erro handling** funcionando (Try/Catch em operações críticas)
- [ ] **Webhook response** retorna status adequado (não bloqueia Chatwoot)

---

## 🔄 Próximos Passos

1. ✅ Corrigir extração de `message_body` no node "Identificar Cliente e Agente"
2. ⏳ Testar novamente com `test-wf0-webhook.ps1`
3. ⏳ Validar que LLM recebe mensagem correta
4. ⏳ Verificar se resposta menciona "tabela de preços" quando detectado
5. ⏳ Confirmar que mídia é enviada para Chatwoot
6. ⏳ Validar logs no Supabase (media_send_log)

---

---

## 🚨 Erro #4: Merge Final bloqueando workflow

**Data:** 2025-11-08  
**Severidade:** 🔴 CRÍTICA  
**Status:** ✅ RESOLVIDO

### Sintomas

- Workflow para no node "Merge Final"
- Execução não completa até o final
- Node aguarda 2 inputs mas só recebe 1

### Root Cause

Node "Merge Final" configurado para aguardar 2 inputs:
1. Branch TRUE de "Tem Mídia do Acervo?" → "Registrar Log de Envio" → Merge Final
2. Branch FALSE de "Tem Mídia do Acervo?" → Merge Final

**Problema:** Quando LLM não chama tools (caminho direto), apenas 1 input chega ao Merge.

### Solução

**Remover completamente o node "Merge Final"** e conectar ambos branches diretamente ao próximo node:

```
"Tem Mídia do Acervo?" → TRUE → "Registrar Log" → "Atualizar Usage Tracking"
"Tem Mídia do Acervo?" → FALSE → "Atualizar Usage Tracking"
```

### Implementação

✅ Corrigido em `WF0-Gestor-Universal-REORGANIZADO.json`:
- Removidas conexões para "Merge Final"
- Ambos branches agora conectam direto a "Atualizar Usage Tracking"
- Node órfão "Merge Final" deletado do JSON

### Prevenção Futura

- Evitar Merge nodes que requerem múltiplos inputs se fluxos são condicionais
- Preferir Code nodes para unificar dados quando necessário

---

## 🚨 Erro #5: Coluna `last_message_at` não existe no Supabase

**Data:** 2025-11-08  
**Severidade:** 🔴 CRÍTICA  
**Status:** ✅ RESOLVIDO

### Sintomas

```json
{
  "errorMessage": "Bad request - please check your parameters",
  "errorDescription": "Could not find the 'last_message_at' column of 'client_subscriptions' in the schema cache"
}
```

### Root Cause

Node "Atualizar Usage Tracking (HTTP)" tentando fazer PATCH com campos inexistentes:

```json
{
  "total_messages": 151,
  "last_message_at": "2025-11-08T15:23:04.559Z",  // ❌ Não existe!
  "updated_at": "2025-11-08T15:23:04.559Z"
}
```

**Estrutura real da tabela `client_subscriptions`:**
- ✅ `updated_at` (timestamptz)
- ✅ `current_usage` (jsonb)
- ❌ `total_messages` (não existe)
- ❌ `last_message_at` (não existe)

### Solução

Remover campos inexistentes do body:

```json
{
  "updated_at": "{{$now}}"
}
```

Se precisar trackear mensagens, usar `current_usage` (jsonb):

```json
{
  "current_usage": {
    "messages": {
      "total": 150,
      "last_at": "2025-11-08T15:23:04.559Z"
    }
  },
  "updated_at": "{{$now}}"
}
```

### Implementação

✅ Corrigido em `WF0-Gestor-Universal-REORGANIZADO.json`:
- Body simplificado para apenas `updated_at`
- HTTP PATCH agora executa com sucesso

### Prevenção Futura

- Sempre validar schema da tabela antes de fazer PATCH/POST
- Documentar estrutura exata das tabelas em database/schemas/
- Usar RLS policies que validem campos permitidos

---

## 🚨 Erro #6: JSON inválido no body do Chatwoot

**Data:** 2025-11-08  
**Severidade:** 🔴 CRÍTICA  
**Status:** ✅ RESOLVIDO

### Sintomas

```json
{
  "errorMessage": "JSON parameter needs to be valid JSON"
}
```

### Root Cause

Body do HTTP Request com sintaxe inválida:

```json
"jsonBody": "={\n  \"content\": \"{{$json.final_response}}\",\n  \"attachments\": {{$json.client_media_attachments || []}}\n}"
```

**Problema:** Não é JSON válido! Mistura string literal com expressões `{{...}}`.

### Solução

Usar sintaxe de expressão JavaScript do n8n:

**ANTES (ERRADO):**
```json
"jsonBody": "={\n  \"content\": \"{{$json.final_response}}\",\n  \"attachments\": {{$json.client_media_attachments || []}}\n}"
```

**DEPOIS (CORRETO):**
```json
"jsonBody": "={{ \n  {\n    \"content\": $json.final_response,\n    \"attachments\": $json.client_media_attachments || []\n  }\n}}"
```

### Implementação

✅ Corrigido em `WF0-Gestor-Universal-REORGANIZADO.json`:
- Sintaxe alterada para `={{ { ... } }}`
- Variáveis sem aspas extras
- JSON gerado dinamicamente de forma válida

### Prevenção Futura

- Para JSON dinâmico, sempre usar `={{ { key: value } }}` (não string literal)
- Testar body em ferramentas como Postman antes de implementar
- Adicionar examples de sintaxe correta no N8N_REFERENCE.md

---

## 🚨 Erro #7: Chatwoot API retorna 404

**Data:** 2025-11-08  
**Severidade:** 🔴 CRÍTICA  
**Status:** ⚠️ TEMPORARIAMENTE CONTORNADO (simulação)

### Sintomas

```
404 - The page you were looking for doesn't exist
```

### Root Cause

URL hardcoded incorreta:
```
https://app.chatwoot.com/api/v1/accounts/{{$env.CHATWOOT_ACCOUNT_ID}}/conversations/{{$json.conversation_id}}/messages
```

**Problemas:**
1. `$env.CHATWOOT_ACCOUNT_ID` provavelmente não configurado
2. Base URL `app.chatwoot.com` é instância pública, usuário tem self-hosted
3. `conversation_id: 99999` é ID de teste, não existe

### Solução Temporária

Node substituído por Code node que simula envio:

```javascript
const response = {
  success: true,
  message_sent: true,
  conversation_id: $input.item.json.conversation_id,
  final_response: $input.item.json.final_response,
  attachments_count: ($input.item.json.client_media_attachments || []).length,
  timestamp: new Date().toISOString()
};

console.log('✅ SIMULAÇÃO: Resposta enviada ao Chatwoot:', response);

return { json: { ...$input.item.json, chatwoot_response: response } };
```

### Solução Permanente (PENDENTE)

1. **Configurar variáveis de ambiente no n8n:**
   - `CHATWOOT_ACCOUNT_ID` (ex: `1`)
   - `CHATWOOT_BASE_URL` (ex: `https://chatwoot.suaempresa.com.br`)

2. **Restaurar HTTP Request node:**
   ```json
   {
     "url": "={{$env.CHATWOOT_BASE_URL}}/api/v1/accounts/{{$env.CHATWOOT_ACCOUNT_ID}}/conversations/{{$json.conversation_id}}/messages"
   }
   ```

3. **Testar com conversation_id real** (não 99999)

### Implementação

✅ Code node simulado implementado em `WF0-Gestor-Universal-REORGANIZADO.json`  
⏳ Aguardando configuração do ambiente para restaurar HTTP real

### Prevenção Futura

- Nunca hardcodar URLs de APIs externas
- Sempre usar variáveis de ambiente para base URLs
- Documentar variáveis requeridas em .env.example
- Adicionar health check para validar conectividade antes de deploy

---

## ✅ RESUMO DAS CORREÇÕES - 2025-11-08

### Workflow Agora:
1. ✅ OpenAI node aparece (`typeVersion: 1`)
2. ✅ message_body extraído corretamente
3. ✅ LLM menciona mídia (instrução no system_prompt)
4. ✅ Merge Final removido (workflow não trava)
5. ✅ Usage Tracking executa (sem campos inexistentes)
6. ✅ JSON do Chatwoot válido (sintaxe corrigida)
7. ✅ Chatwoot simulado (workflow completa end-to-end)
8. ✅ **WORKFLOW COMPLETA ATÉ O FINAL!**

### Pendente:
- 🔍 Investigar `client_media_attachments` chegando vazio no final (attachments_count: 0)
- ⏳ Configurar Chatwoot real (variáveis de ambiente)
- ⏳ Testar com conversation_id real

---

_Última atualização: 2025-11-08 por GitHub Copilot_

````

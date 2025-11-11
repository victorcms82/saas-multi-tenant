# 🚨 FIX URGENTE - LLM Ignorando location_context

## PROBLEMA CONFIRMADO

Bot respondeu com informacoes INVENTADAS:
- ❌ Endereco: "Rua das Flores, 123" (ERRADO!)
- ✅ Endereco correto: "Av. das Americas, 5000 - Sala 301"
- ❌ Imagem: "Recepcao Clinica Sorriso" (ERRADO!)

**CONCLUSAO: LLM esta ignorando location_context e usando RAG com docs errados**

---

## CAUSA RAIZ

O node "Preparar Prompt LLM" provavelmente:
1. Nao esta incluindo location_context no prompt
2. Ou RAG esta sobrescrevendo as informacoes corretas
3. Ou ordem das informacoes no prompt esta errada

---

## SOLUCAO 1: DESABILITAR RAG TEMPORARIAMENTE

### Passo 1: Editar Node "Query RAG"

No n8n, encontre o node que busca RAG e:

**Opcao A: Desabilitar completamente**
- Clicar com botao direito no node
- "Disable"
- Salvar workflow

**Opcao B: Adicionar filtro por client_id**
Se o node usa Pinecone/Weaviate, garantir que:
```javascript
const namespace = `${client_id}/default`;
// Ou adicionar filtro:
filter: {
  client_id: { $eq: client_id }
}
```

### Passo 2: Testar sem RAG

Salvar workflow e testar novamente:
```
Qual o endereco da clinica?
```

**Se responder CERTO → RAG era o problema**
**Se responder ERRADO → Problema no prompt**

---

## SOLUCAO 2: CORRIGIR PROMPT DO LLM

### Node: "Preparar Prompt LLM"

O prompt deve ter esta estrutura:

```javascript
const systemPrompt = $('Construir Contexto Completo').first().json.system_prompt;
const locationContext = $('Construir Contexto Completo').first().json.location_context;
const messageBody = $('Construir Contexto Completo').first().json.message_body;

// RAG (se usado)
const ragDocs = $('Query RAG').all()[0]?.json?.documents || [];
const ragContext = ragDocs.map(d => d.content).join('\n\n');

// CRITICO: location_context DEVE vir DEPOIS do RAG!
const fullPrompt = `${systemPrompt}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 INFORMACOES PRIORITARIAS (USE ESTAS INFORMACOES!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${locationContext}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 CONTEXTO ADICIONAL (Base de conhecimento)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${ragContext}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPORTANTE: Se houver conflito entre as informacoes, USE SEMPRE as "INFORMACOES PRIORITARIAS" acima!

Mensagem do usuario: ${messageBody}`;

return {
  json: {
    prompt: fullPrompt,
    // ...
  }
};
```

**CHAVE: location_context ANTES do RAG para o LLM priorizar!**

---

## SOLUCAO 3: LIMPAR NAMESPACE RAG

Se o problema e documentos errados no RAG:

### Via Pinecone/Weaviate Dashboard:

1. Acessar dashboard do vector DB
2. Filtrar namespace: `estetica_bella_rede/default`
3. Buscar por documentos que mencionem "Clinica Sorriso"
4. Deletar esses documentos

### Via N8N (se tiver workflow de upload):

1. Adicionar validacao:
```javascript
// Antes de fazer embed/upload:
if (document.content.includes('Clinica Sorriso') && client_id === 'estetica_bella_rede') {
  throw new Error('Documento com informacoes de outro cliente!');
}
```

---

## TESTE PASSO-A-PASSO

### Teste 1: Sem RAG
1. Desabilitar node RAG
2. Testar: "Qual o endereco?"
3. Esperado: "Av. das Americas, 5000..."
4. Se OK → RAG era o problema

### Teste 2: Com RAG mas prompt corrigido
1. Reabilitar RAG
2. Aplicar fix do prompt (location_context prioritario)
3. Testar: "Qual o endereco?"
4. Esperado: Usar endereco correto

### Teste 3: Profissionais
1. Testar: "Quais profissionais?"
2. Esperado: Ana Paula Silva, Beatriz Costa, Carlos Mendes, Eduardo Lima
3. NAO deve mencionar: Dra. Ana Silva, Paula Rocha, Renata Oliveira

---

## CHECKLIST DE VALIDACAO

- [ ] Node RAG desabilitado OU filtrado por client_id
- [ ] Prompt inclui location_context ANTES do RAG
- [ ] Teste "Qual o endereco?" retorna correto
- [ ] Teste "Quais profissionais?" retorna correto
- [ ] Imagem correta sendo enviada (ou sem imagem)
- [ ] Nenhuma mencao a "Clinica Sorriso"

---

## SE AINDA NAO FUNCIONAR

**Ultima opcao: Criar conversa nova no Chatwoot**

1. Arquivar conversa atual
2. Criar novo contato
3. Testar com contato limpo (sem historico)

Isso garante que nao e cache de mensagens antigas.

---

## PRIORIDADE DAS ACOES

**AGORA (5 min):**
1. Desabilitar node RAG
2. Testar sem RAG

**SE OK (10 min):**
3. Reabilitar RAG
4. Corrigir ordem do prompt (location_context prioritario)
5. Testar novamente

**SE AINDA FALHAR (20 min):**
6. Limpar documentos errados do RAG
7. Fazer re-upload com validacao

---

**Me avisa qual caminho quer seguir: desabilitar RAG primeiro ou corrigir o prompt?**

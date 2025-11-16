# 🔧 TAREFAS PENDENTES NO WORKFLOW

## ✅ O QUE JÁ ESTÁ IMPLEMENTADO:
- ✅ Node "💾 Salvar Mensagem do Usuário" (já existe)
- ✅ Node "Code in JavaScript" preservando dados (já existe)
- ✅ Node "🧠 Buscar Histórico de Conversa" (já existe, mas precisa modificar body)
- ✅ Node "📝 Formatar Histórico para LLM" (já existe e correto)
- ✅ Node "Preparar Prompt LLM" (já existe e correto)
- ✅ Node "📦 Preparar Mensagens para Memória" (já existe e correto)
- ✅ Node "💾 Salvar Resposta do Assistant" (já existe e correto)
- ✅ Node "🔄 Preservar Dados Após Memória" (já existe e correto)
- ✅ Node "⚙️ Buscar Configuração de Memória" (já existe, mas no lugar errado!)

---

## ❌ O QUE PRECISA SER CORRIGIDO:

### **TAREFA 1: Mover Node "⚙️ Buscar Configuração de Memória"**

**Problema:** Node existe, mas está conectado no lugar errado!

**Estado Atual:**
```
📦 Preparar Mensagens → ⚙️ Buscar Config (inútil aqui!)
                      → 💾 Salvar Assistant
```

**Estado Correto:**
```
Query RAG → ⚙️ Buscar Config → 💾 Salvar User → 🧠 Buscar Histórico
```

**Ação:**
1. **Desconectar** "⚙️ Buscar Config" de "📦 Preparar Mensagens"
2. **Conectar** "Query RAG" → "⚙️ Buscar Config"
3. **Conectar** "⚙️ Buscar Config" → "💾 Salvar Mensagem do Usuário"

**Node ID:** `8810bebf-6156-4e71-bb2c-e2263a789deb`
**Posição Atual:** [3104, 240] (fim do workflow)
**Posição Nova:** Entre Query RAG e Salvar User (~900, -200)

---

### **TAREFA 2: Atualizar Body do Node "🧠 Buscar Histórico de Conversa"**

**Problema:** Valores hardcoded (50 e 24) em vez de dinâmicos

**Node ID:** `99b34291-af91-4eda-b326-ede9d65473e7`

**Body Atual (ERRADO):**
```json
{
  "p_client_id": "{{ $json.client_id }}",
  "p_conversation_id": {{ $json.conversation_id }},
  "p_limit": 50,
  "p_hours_back": 24
}
```

**Body Correto (DINÂMICO):**
```json
{
  "p_client_id": "{{ $json.client_id }}",
  "p_conversation_id": {{ $json.conversation_id }},
  "p_limit": {{ $json.memory_limit }},
  "p_hours_back": {{ $json.memory_hours_back }}
}
```

**Como Fazer:**
1. Abrir node "🧠 Buscar Histórico de Conversa (RPC)"
2. Ir em "Body" → JSON
3. Substituir `50` por `{{ $json.memory_limit }}`
4. Substituir `24` por `{{ $json.memory_hours_back }}`
5. Salvar workflow

---

### **TAREFA 3: Renomear Node "Code in JavaScript"**

**Problema:** Nome genérico, dificulta compreensão do workflow

**Node ID:** `ef7df339-c4dd-4452-a6c6-a538948bdda3`

**Nome Atual:** "Code in JavaScript"
**Nome Correto:** "🔄 Preservar Dados Originais"

**Como Fazer:**
1. Clicar duas vezes no node
2. Mudar título para "🔄 Preservar Dados Originais"
3. Salvar workflow

---

## 🧪 TESTE APÓS CORREÇÕES:

### **1. Validar Conexões:**
```
Query RAG (Namespace Isolado)
  ↓
⚙️ Buscar Configuração de Memória [MOVIDO!]
  ↓
💾 Salvar Mensagem do Usuário
  ↓
🔄 Preservar Dados Originais [RENOMEADO!]
  ↓
🧠 Buscar Histórico de Conversa [BODY ATUALIZADO!]
  ↓
📝 Formatar Histórico para LLM
  ↓
Preparar Prompt LLM
  ↓
... (resto do fluxo) ...
```

### **2. Testar Memória:**
**Mensagem 1:** "Olá! Meu nome é João Pedro"
- Bot responde normalmente

**Mensagem 2:** "Qual é o meu nome?"
- ✅ Bot deve responder: "Seu nome é João Pedro"

### **3. Testar Configuração Dinâmica:**
```sql
-- Mudar config para 10 mensagens e 1 hora
UPDATE memory_config 
SET memory_limit = 10, memory_hours_back = 1
WHERE client_id = 'estetica_bella_rede' AND agent_id = 'default';
```

Enviar nova mensagem e verificar logs:
```
✅ Memória configurada: limit=10, hours=1, enabled=true
```

---

## 📋 CHECKLIST RÁPIDO:

- [ ] **Mover** node "⚙️ Buscar Config" para ANTES de "Salvar User"
- [ ] **Atualizar** Body do "Buscar Histórico" com `{{ $json.memory_limit }}`
- [ ] **Renomear** "Code in JavaScript" para "🔄 Preservar Dados Originais"
- [ ] **Testar** com 2 mensagens (nome e pergunta)
- [ ] **Validar** que config dinâmica funciona (mudar no SQL e testar)

---

## 🎯 RESULTADO ESPERADO:

Após essas 3 correções, o workflow estará **100% funcional** com:
- ✅ Memória salvando ANTES de buscar histórico (timing correto)
- ✅ Configuração dinâmica por client/agent (sem hardcode)
- ✅ Bot lembrando de tudo desde a 2ª mensagem
- ✅ Fácil gerenciar via SQL (alterar limit/hours)

---

**Tempo estimado:** 5 minutos para fazer as 3 correções! 🚀

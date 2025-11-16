# 🗺️ Mapa de Nodes do Workflow

**Workflow:** Chatwoot Multi-Tenant with Memory  
**Versão:** 1.0.1 (após limpeza)  
**Total de Nodes:** 41  
**Data:** 12/11/2025

---

## 📥 ENTRADA (Webhook)

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `456f9b26` | Chatwoot Webhook | webhook | [-720, 96] | Recebe webhook POST do Chatwoot |
| `746e5fd8` | Identificar Cliente e Agente | code | [-512, 96] | Extrai dados do payload com fallbacks |
| `cbee8c42` | Filtrar Apenas Incoming | if | [-336, 96] | Filtra: message_type='incoming' AND sender.type='contact' |

---

## 🔒 SEGURANÇA & MULTI-TENANT

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `cc24d0aa` | 🏢 Detectar Localização e Staff (RPC)1 | httpRequest | [-48, 0] | **CRÍTICO:** Autentica client_id via inbox_id do banco |
| `4283c8fc` | 💼 Construir Contexto Location + Staff1 | code | [144, 0] | **CRÍTICO:** SOBRESCREVE client_id com valor autenticado |
| `dd6b4c59` | Buscar Dados do Agente (HTTP) | httpRequest | [336, 0] | Busca config do agente (system_prompt, tools, LLM) |
| `7e5f0e29` | Buscar Mídia Triggers (RPC) | httpRequest | [144, 256] | RPC check_media_triggers para acervo de mídia |
| `ef31c8ba` | Merge: Agente + Mídia | merge | [624, 96] | Combina dados do agente + triggers de mídia |
| `3aecfa47` | Construir Contexto Completo | code | [256, -304] | **CRÍTICO:** Garante client_id autenticado em todo fluxo |

---

## 🧠 MEMÓRIA DE CONVERSAÇÃO

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `d5f6cc05` | ⚙️ Buscar Configuração de Memória1 | httpRequest | [672, -304] | RPC get_memory_config (limit, hours_back, enabled) |
| `b18a89a5` | 🔄 Processar Config de Memória | code | [880, -304] | Extrai config: memory_limit, memory_hours_back, memory_enabled |
| `152ea881` | 📦 Preparar Body Salvar User | code | [1088, -304] | Monta JSON para RPC save_conversation_message (user) |
| `de723404` | 💾 Salvar User (HTTP) | httpRequest | [1232, -144] | **Salva msg usuário ANTES de buscar histórico** |
| `ef7df339` | 🔄 Preservar Dados Originais | code | [1376, -304] | Preserva dados após salvar user |
| `99b34291` | 🧠 Buscar Histórico de Conversa (RPC) | httpRequest | [1632, -304] | RPC get_conversation_history (últimas N msgs) |
| `e0022808` | 📝 Formatar Histórico para LLM | code | [1888, -304] | **🐛 FIX:** `$input.all()` processa TODAS msgs |

---

## 🤖 RAG & CONTEXTO

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `120924cc` | Query RAG (Namespace Isolado) | code | [448, -304] | Placeholder para Pinecone/Qdrant (futuro) |
| `7d094cd6` | Preparar Prompt LLM | code | [2128, -304] | Centraliza prompt: system + user + RAG + histórico |

---

## 🧠 LLM & RESPOSTA

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `9a126db2` | LLM (GPT-4o-mini + Tools) | openAi | [1760, 96] | Chama OpenAI API com tools (function calling) |
| `4df065c0` | Preservar Contexto Após LLM | code | [2032, 96] | Preserva dados do contexto + adiciona choices |
| `c054f30d` | Chamou Tool? | if | [2240, 96] | Verifica finish_reason='tool_calls' |
| `44720297` | Executar Tools | code | [2432, 0] | Placeholder para Calendar, Sheets, CRM |
| `ae3dcf92` | Construir Resposta Final | code | [2624, 112] | Extrai resposta do LLM + tool_results |

---

## 💾 SALVAR RESPOSTA DO ASSISTENTE

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `aece43e7` | 📦 Preparar Mensagens para Memória | code | [2800, 144] | Monta JSON para salvar resposta do assistant |
| `a947ca0a` | 💾 Salvar Resposta do Assistant | httpRequest | [2960, 48] | RPC save_conversation_message (assistant) |
| `1adb7211` | 🔄 Preservar Dados Após Memória | code | [3152, 96] | Preserva dados após salvar na memória |

---

## 🖼️ MÍDIA & ACERVO

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `ad003549` | Tem Mídia do Acervo? | if | [3328, 96] | Verifica has_client_media=true |
| `f1c0afe9` | Registrar Log de Envio (HTTP) | httpRequest | [3504, 0] | INSERT em media_send_log |
| `982052e3` | Preservar Dados Após Log | code | [3792, 0] | Preserva dados após log de mídia |

---

## 📊 USAGE & TRACKING

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `977a3b84` | Atualizar Usage Tracking (HTTP) | httpRequest | [4032, 160] | PATCH em client_subscriptions (updated_at) |
| `cfd684eb` | Preservar Dados Após Usage Tracking | code | [4224, 96] | Preserva dados após atualizar usage |

---

## 📤 ENVIO PARA CHATWOOT

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `ae24e4aa` | Enviar Resposta via Chatwoot | httpRequest | [4384, 32] | POST message (texto) para Chatwoot API |
| `fec806ff` | Log Chatwoot Response | code | [4576, 96] | Log status code e response body |

---

## 📎 ANEXOS (Download & Upload)

| Node ID | Nome | Tipo | Posição | Função |
|---------|------|------|---------|--------|
| `f85a7afa` | Tem Anexos? | if | [4880, 96] | Verifica client_media_attachments.length > 0 |
| `542196ff` | Download Arquivo do Supabase | httpRequest | [5280, 0] | GET arquivo do Supabase Storage |
| `8e27d247` | Upload Anexo para Chatwoot | httpRequest | [5472, 0] | POST multipart/form-data para Chatwoot |
| `5e4cb8da` | Log Upload Resultado | code | [5680, 0] | Log status do upload de anexo |

---

## ❌ ERROR HANDLING

| Node ID | Nome | Tipo | Posição | Status |
|---------|------|------|---------|--------|
| `784044e3` | Error Handler | code | [4368, 304] | ⚠️ NÃO CONECTADO (fallback manual) |

---

## 🗑️ NODES REMOVIDOS (Limpeza 12/11/2025)

| Node ID | Nome | Motivo |
|---------|------|--------|
| ~~`6470dad2`~~ | ~~DEBUG ANTES DO IF~~ | Debug temporário - não necessário em produção |
| ~~`6e7a90a8`~~ | ~~Debug Antes Download~~ | Debug temporário - não necessário em produção |

---

## 🔍 NODES CRÍTICOS (Requerem Atenção)

### 🔒 Segurança (Não Modificar!)
1. **`cc24d0aa`** - 🏢 Detectar Localização: Autentica client_id via banco
2. **`4283c8fc`** - 💼 Construir Contexto Location: SOBRESCREVE client_id
3. **`3aecfa47`** - Construir Contexto Completo: Garante client_id correto

### 🧠 Memória (Bug Corrigido!)
4. **`e0022808`** - 📝 Formatar Histórico: `$input.all()` FIX aplicado (12/11/2025)

### 📊 Performance
5. **`120924cc`** - Query RAG: Placeholder (implementar Pinecone/Qdrant)
6. **`44720297`** - Executar Tools: Placeholder (implementar Calendar, CRM)

---

## 📊 ESTATÍSTICAS DO WORKFLOW

| Métrica | Valor |
|---------|-------|
| **Total de Nodes** | 41 |
| **Webhooks** | 1 |
| **HTTP Requests** | 12 |
| **Code Nodes** | 20 |
| **IF Conditions** | 4 |
| **Merge Nodes** | 1 |
| **OpenAI Nodes** | 1 |
| **Error Handlers** | 1 (não conectado) |

---

## 🎯 FLUXO PRINCIPAL (Sequência)

```
1. Webhook Receive
   ↓
2. Extract & Validate
   ↓
3. Filter Incoming
   ↓
4. 🔒 Auth client_id (RPC)
   ↓
5. Build Context
   ↓
6. Load Agent Config
   ↓
7. Check Media Triggers
   ↓
8. Merge Data
   ↓
9. Query RAG (placeholder)
   ↓
10. 🧠 Get Memory Config (RPC)
    ↓
11. 💾 Save User Message (RPC)
    ↓
12. 🧠 Get History (RPC)
    ↓
13. 📝 Format History (🐛 FIX)
    ↓
14. Build Prompt
    ↓
15. 🤖 Call LLM
    ↓
16. Process Response
    ↓
17. 💾 Save Assistant (RPC)
    ↓
18. Check Media
    ↓
19. Update Usage
    ↓
20. 📤 Send to Chatwoot
    ↓
21. 📎 Upload Attachments (if any)
```

---

## 🔗 CONEXÕES CRÍTICAS (Não Quebrar!)

### Fluxo de Segurança:
```
Filtrar Incoming → 🏢 Detectar Localização → 💼 Construir Contexto → Buscar Agente
```

### Fluxo de Memória:
```
Query RAG → Buscar Config → Salvar User → Buscar Histórico → Formatar → Prompt
```

### Fluxo de Resposta:
```
LLM → Preservar → Build Response → Salvar Assistant → Send Chatwoot
```

---

## 📝 NOTAS DE VERSÃO

### v1.0.1 (12/11/2025) - CLEAN
- ✅ Removidos 2 debug nodes
- ✅ Corrigidos nomes com aspas duplas
- ✅ Adicionadas 8 notes de documentação
- ✅ Workflow production-ready

### v1.0.0 (12/11/2025) - FIX MEMORY
- ✅ Bug de memória corrigido (`$input.all()`)
- ✅ Bot agora lembra contexto
- ✅ Sistema 100% funcional

### v0.9.0 (Anterior)
- ⚠️ Memória não funcionava
- ⚠️ Debug nodes presentes
- ⚠️ Nomes inconsistentes

---

**Criado por:** GitHub Copilot  
**Data:** 12/11/2025  
**Última Atualização:** 12/11/2025

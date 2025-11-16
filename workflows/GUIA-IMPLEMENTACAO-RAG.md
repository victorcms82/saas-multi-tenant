# 🔍 GUIA DE IMPLEMENTAÇÃO RAG - Sistema Completo

**Data**: 16/11/2025  
**Status**: ✅ Pronto para implementar  
**Tempo Estimado**: 1-2h

---

## 📋 O QUE FOI CRIADO

### 1. **Migration SQL** (`database/migrations/020_create_rag_system.sql`)
- ✅ Extensão pgvector
- ✅ Tabela `rag_documents` com suporte a embeddings (1536 dims)
- ✅ Índice IVFFlat para busca vetorial rápida
- ✅ RPC `query_rag_documents` (busca similar)
- ✅ RPC `save_rag_document` (salva com deduplicação)
- ✅ RPC `delete_rag_documents_by_source` (delete por fonte)
- ✅ View `rag_statistics` (estatísticas por cliente)
- ✅ Row Level Security (RLS) habilitado
- ✅ Triggers e constraints

### 2. **Código Node Query RAG** (`workflows/CODIGO-QUERY-RAG-REAL.js`)
- ✅ Gera embedding da pergunta (OpenAI ada-002)
- ✅ Busca documentos similares no Supabase
- ✅ Formata contexto para o LLM
- ✅ Tratamento de erros (não bloqueia fluxo)
- ✅ Logs detalhados

### 3. **Workflow de Ingestion** (`workflows/RAG-INGESTION-WORKFLOW.json`)
- ✅ Webhook para upload
- ✅ Suporte a URL, texto puro, PDF (futuro)
- ✅ Chunking automático (2000 chars, overlap 200)
- ✅ Gera embeddings por chunk
- ✅ Salva no Supabase com deduplicação
- ✅ Resumo de sucesso/falhas

---

## 🚀 PASSO A PASSO DE IMPLEMENTAÇÃO

### **PASSO 1: Executar Migration SQL**

```bash
# 1. Conectar no Supabase
# https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq

# 2. Ir em SQL Editor

# 3. Copiar conteúdo de database/migrations/020_create_rag_system.sql

# 4. Colar e executar (Run)

# 5. Verificar mensagens:
#    ✅ Extensão vector: OK
#    ✅ Tabela rag_documents: OK
#    ✅ Function query_rag_documents: OK
#    ✅ Function save_rag_document: OK
```

**Validação:**
```sql
-- Verificar tabela criada
SELECT COUNT(*) FROM rag_documents;
-- Deve retornar 0 (vazio)

-- Verificar function
SELECT proname FROM pg_proc WHERE proname LIKE '%rag%';
-- Deve listar query_rag_documents, save_rag_document, etc
```

---

### **PASSO 2: Atualizar Node Query RAG no n8n**

```bash
# 1. Abrir n8n: https://n8n.evolutedigital.com.br

# 2. Abrir workflow: chatwoot-multi-tenant-with-memory-v1.0.0

# 3. Localizar node: "Query RAG (Namespace Isolado)"

# 4. Substituir código:
#    - Copiar conteúdo de workflows/CODIGO-QUERY-RAG-REAL.js
#    - Colar no node (substituir tudo)

# 5. Salvar workflow
```

**IMPORTANTE:**
- ⚠️ NÃO remover `$input.item.json` e `return { json: {...} }`
- ⚠️ O código já está pronto, só copiar/colar

---

### **PASSO 3: Importar Workflow de Ingestion**

```bash
# 1. No n8n, clicar em: Workflows → Import

# 2. Selecionar arquivo: workflows/RAG-INGESTION-WORKFLOW.json

# 3. Nome do workflow: "RAG Document Ingestion"

# 4. Ativar webhook:
#    - Abrir node "Webhook Trigger"
#    - Copiar URL do webhook
#    - Exemplo: https://n8n.evolutedigital.com.br/webhook/rag-upload

# 5. Salvar e ativar workflow
```

---

### **PASSO 4: Testar Sistema RAG**

#### A. Upload de Documento de Teste

```bash
# Criar arquivo teste.txt com conteúdo:
cat > teste.txt << EOF
Horário de Funcionamento da Clínica:
- Segunda a Sexta: 8h às 18h
- Sábado: 8h às 12h
- Domingo: Fechado

Serviços Oferecidos:
- Limpeza dentária: R$ 150
- Clareamento dental: R$ 800
- Extração de dente: R$ 200
- Canal: R$ 1200

Profissionais Disponíveis:
- Dra. Maria Silva - Dentista
- Dr. João Santos - Ortodontista
EOF

# Fazer upload via webhook:
curl -X POST https://n8n.evolutedigital.com.br/webhook/rag-upload \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "clinica_sorriso_001",
    "agent_id": "default",
    "document_type": "txt",
    "file_name": "teste.txt",
    "content": "Horário de Funcionamento da Clínica:\n- Segunda a Sexta: 8h às 18h\n- Sábado: 8h às 12h\n- Domingo: Fechado\n\nServiços Oferecidos:\n- Limpeza dentária: R$ 150\n- Clareamento dental: R$ 800\n- Extração de dente: R$ 200\n- Canal: R$ 1200\n\nProfissionais Disponíveis:\n- Dra. Maria Silva - Dentista\n- Dr. João Santos - Ortodontista",
    "metadata": {
      "tags": ["horarios", "precos", "servicos"],
      "author": "admin"
    }
  }'
```

**Resposta esperada:**
```json
{
  "success": true,
  "total_chunks": 1,
  "success_count": 1,
  "fail_count": 0,
  "client_id": "clinica_sorriso_001",
  "agent_id": "default",
  "file_name": "teste.txt"
}
```

#### B. Verificar no Supabase

```sql
-- Ver documentos inseridos
SELECT 
  id, 
  client_id, 
  agent_id, 
  LEFT(content, 50) as preview,
  source_type,
  file_name,
  created_at
FROM rag_documents
ORDER BY created_at DESC
LIMIT 5;
```

#### C. Testar Query RAG

```bash
# Enviar mensagem via Chatwoot:
"Qual o horário de funcionamento?"

# Verificar logs no n8n (node Query RAG):
# ✅ Embedding gerado
# ✅ Documentos encontrados: 1
# ✅ Doc 1: 95% similar - "Horário de Funcionamento..."
# ✅ Contexto RAG formatado
```

**Resposta esperada do bot:**
```
O horário de funcionamento da clínica é:
- Segunda a Sexta: 8h às 18h
- Sábado: 8h às 12h
- Domingo: Fechado

[FONTE: teste.txt]
```

---

## 📊 CUSTOS ESTIMADOS

### OpenAI API
| Operação | Modelo | Custo Unitário | Estimativa |
|----------|--------|----------------|------------|
| **Embedding (ingestion)** | ada-002 | $0.0001/1K tokens | $0.0001/chunk |
| **Embedding (query)** | ada-002 | $0.0001/1K tokens | $0.00001/msg |

**Exemplo:**
- Upload 100 páginas (200 chunks): $0.02
- 1000 queries/dia: $0.01/dia = $0.30/mês

### Supabase
- pgvector: **GRÁTIS** (incluído no plano free)
- Storage: Até 500MB grátis

**Total estimado:** ~$0.50/mês para 1000 mensagens/dia

---

## 🔧 CONFIGURAÇÕES AVANÇADAS

### Ajustar Threshold de Similaridade

No `CODIGO-QUERY-RAG-REAL.js`:
```javascript
p_threshold: 0.7  // 70% similaridade mínima

// Ajustar conforme necessidade:
// 0.9 = Muito restritivo (só retorna documentos quase idênticos)
// 0.7 = Balanceado (recomendado)
// 0.5 = Permissivo (retorna mais documentos, menos precisos)
```

### Ajustar Número de Documentos Retornados

```javascript
p_limit: 5  // Top 5 documentos

// Ajustar conforme tamanho do contexto:
// 3 = Contexto curto (~1500 chars)
// 5 = Contexto médio (~2500 chars) - recomendado
// 10 = Contexto longo (~5000 chars)
```

### Ajustar Tamanho dos Chunks

No workflow de ingestion (`Chunking` node):
```javascript
const CHUNK_SIZE = 2000; // ~500 tokens
const OVERLAP = 200;     // 50 tokens overlap

// Ajustar conforme tipo de documento:
// Textos técnicos/documentação: 2000 chars (atual)
// Conversas/FAQ: 500 chars (mais fragmentado)
// Artigos longos: 4000 chars (chunks maiores)
```

---

## 🐛 TROUBLESHOOTING

### Problema 1: "relation rag_documents does not exist"

**Solução:** Migration não foi executada
```sql
-- Verificar se tabela existe
SELECT tablename FROM pg_tables WHERE tablename = 'rag_documents';

-- Se não existe, executar migration 020
```

---

### Problema 2: "Nenhum documento encontrado"

**Possíveis causas:**
1. Threshold muito alto (>0.8)
2. Documento não foi uploadado para o client_id correto
3. Embedding da query muito diferente do documento

**Solução:**
```sql
-- Verificar documentos do cliente
SELECT COUNT(*), client_id, agent_id 
FROM rag_documents 
GROUP BY client_id, agent_id;

-- Testar com threshold mais baixo (0.5)
```

---

### Problema 3: "OpenAI API error"

**Possíveis causas:**
1. API key inválida ou expirada
2. Limite de rate excedido
3. Texto muito longo (>8191 tokens)

**Solução:**
```javascript
// Verificar API key no node
const openaiApiKey = data.llm_api_key || process.env.OPENAI_API_KEY;

// Truncar texto muito longo antes de gerar embedding
if (messageBody.length > 8000) {
  messageBody = messageBody.substring(0, 8000);
}
```

---

### Problema 4: "Embedding dimensão errada"

**Erro:** `expected 1536 dimensions, got X`

**Solução:** Verificar modelo usado
```javascript
// CORRETO:
model: 'text-embedding-ada-002'  // 1536 dims

// ERRADO:
model: 'text-embedding-3-small'  // 1536 dims (ok, mas mais caro)
model: 'text-embedding-3-large'  // 3072 dims (incompatível!)
```

---

## 📈 PRÓXIMOS PASSOS (Melhorias Futuras)

### 1. **Cache de Embeddings**
- Salvar embedding da query em Redis
- Evitar regenerar embedding para perguntas idênticas
- **Economia:** ~50% dos custos de embedding

### 2. **Hybrid Search**
- Combinar vector search + keyword search (tsvector)
- Melhor para perguntas específicas
- **Implementação:** Já está na migration (comentada)

### 3. **Reranking**
- Usar modelo de reranking após busca inicial
- Melhora precisão em 20-30%
- **Custo adicional:** $0.0001/rerank

### 4. **Auto-Ingestion**
- Webhook do Google Drive/Dropbox
- Upload automático de documentos novos
- **Tempo:** 4h implementação

### 5. **Document Management UI**
- Interface para listar/deletar documentos
- Ver estatísticas (rag_statistics view)
- **Tempo:** 8h implementação

---

## ✅ CHECKLIST FINAL

**Antes de considerar RAG "pronto":**

- [ ] Migration 020 executada no Supabase
- [ ] Node Query RAG atualizado no workflow principal
- [ ] Workflow de ingestion importado e ativo
- [ ] Documento de teste uploadado com sucesso
- [ ] Query no Supabase retorna documento
- [ ] Pergunta via Chatwoot usa contexto RAG na resposta
- [ ] Logs mostram: embedding gerado + documentos encontrados + contexto formatado
- [ ] Threshold ajustado (0.7 recomendado)
- [ ] Documentação atualizada (STATUS-ATUAL)

---

## 📞 RESUMO EXECUTIVO

**O que temos:**
- ✅ Migration SQL completa (tabela + RPCs + RLS)
- ✅ Código do node Query RAG funcional
- ✅ Workflow de ingestion completo
- ✅ Sistema de chunking automático
- ✅ Deduplicação de documentos
- ✅ Multi-tenant isolado

**O que falta:**
- ⬜ Executar migration no Supabase
- ⬜ Atualizar node no workflow
- ⬜ Importar workflow de ingestion
- ⬜ Testar com documento real

**Tempo estimado:** 1-2h  
**Dificuldade:** 🟢 Baixa (tudo documentado)  
**Risco:** 🟢 Baixo (não quebra nada existente)

---

**Criado por**: GitHub Copilot  
**Data**: 16/11/2025  
**Versão**: 1.0

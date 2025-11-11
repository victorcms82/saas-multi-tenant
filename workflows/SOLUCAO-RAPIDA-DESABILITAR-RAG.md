# 🚀 SOLUÇÃO RÁPIDA - Desabilitar RAG Temporariamente

## POR QUE ESTA É A MELHOR OPÇÃO AGORA?

✅ **2 minutos** vs 20+ minutos investigando
✅ **Testa imediatamente** se o problema é o RAG
✅ **Sem risco** de deletar dados importantes
✅ **Reversível** - basta reativar

---

## PASSO 1: DESABILITAR NODE DE RAG NO N8N

### Opção A: Desativar o Node

1. Abrir workflow **WF0-Gestor-Universal** no n8n
2. Procurar node com nome tipo:
   - "Query RAG"
   - "Buscar RAG"
   - "Vector Search"
   - "Semantic Search"
3. **Clicar com botão direito** no node
4. Selecionar **"Disable"** (ou "Desativar")
5. **Salvar workflow** (Ctrl+S)

### Opção B: Remover do Fluxo (Mais Seguro)

1. Identificar o node de RAG
2. Ver quais nodes estão conectados **ANTES** e **DEPOIS**
3. Conectar o node ANTES diretamente ao node DEPOIS
4. Deletar (ou desabilitar) o node de RAG
5. Salvar workflow

---

## PASSO 2: TESTAR NO WHATSAPP

```
Mensagem 1: "Qual o endereço da clínica?"
Esperado: "Av. das Américas, 5000 - Sala 301"

Mensagem 2: "Quais profissionais vocês têm?"
Esperado: Ana Paula Silva, Beatriz Costa, Carlos Mendes, Eduardo Lima

Mensagem 3: "Que tipo de clínica é essa?"
Esperado: "Clínica de estética" (SEM mencionar odontologia)
```

---

## PASSO 3: INTERPRETAR RESULTADOS

### ✅ Se funcionou (respostas corretas):
**PROBLEMA CONFIRMADO:** RAG está contaminado!

**Próximos passos:**
1. Manter RAG desabilitado por enquanto
2. Investigar onde está o RAG (Redis/Pinecone/Qdrant)
3. Limpar dados contaminados
4. Reativar RAG limpo

### ❌ Se ainda deu errado (respostas incorretas):
**O problema NÃO é o RAG!**

**Verificar:**
1. System prompt está correto?
2. Node "Construir Contexto" está funcionando?
3. LLM está recebendo o location_context?

---

## PASSO 4: ENQUANTO RAG ESTÁ DESABILITADO

O bot vai funcionar usando **APENAS**:
- ✅ System prompt (já corrigido)
- ✅ Location context (lista de profissionais do banco)
- ✅ Dados em tempo real do Supabase

**Limitações temporárias:**
- ❌ Não vai buscar documentos/PDFs
- ❌ Não vai usar conhecimento pregresso
- ❌ Não vai lembrar conversas antigas (se for isso que usa RAG)

**Mas para testar, é perfeito!**

---

## DIAGRAMA DO FLUXO

### Antes (com RAG):
```
Webhook → Location Context → RAG → LLM → Chatwoot
                                ↑ 
                            CONTAMINADO
```

### Depois (sem RAG):
```
Webhook → Location Context → LLM → Chatwoot
                              ↑
                      DADOS LIMPOS DO DB
```

---

## QUANDO REATIVAR O RAG?

Somente depois de:
1. ✅ Confirmar que funciona sem RAG
2. ✅ Descobrir onde está o RAG (Redis/Pinecone/etc)
3. ✅ Limpar documentos contaminados
4. ✅ Implementar validação para não contaminar de novo

---

## COMANDOS ÚTEIS (SE PRECISAR)

### Ver logs do n8n:
```bash
# Se for Docker
docker logs n8n -f --tail 100

# Se for Easypanel
# Acessar via interface do Easypanel
```

### Backup do workflow antes de mexer:
1. n8n → Workflows → WF0-Gestor-Universal
2. Clicar nos 3 pontinhos
3. "Download"
4. Salvar JSON como backup

---

## QUER FAZER AGORA?

1. **Desabilitar RAG no n8n** (2 min)
2. **Testar no WhatsApp** (1 min)
3. **Me avisar o resultado** 

Se funcionar, problema RESOLVIDO temporariamente! 🎉

Se não funcionar, investigamos mais fundo. 🔍

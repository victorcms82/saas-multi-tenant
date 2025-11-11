# 🔍 INVESTIGAR REDIS - DIRETO NO EASYPANEL TERMINAL

**Mais rápido e direto!** Sem precisar de credenciais ou SSH!

---

## 📋 PASSO A PASSO

### 1️⃣ Abrir Terminal do Redis no Easypanel

1. Acessar **Easypanel** → Seu Projeto
2. Clicar em **Services** → **Redis**
3. Aba **Terminal** (ou "Shell" ou "Console")
4. Você verá um terminal já conectado ao Redis!

---

### 2️⃣ Comandos para Investigar Cache

Copie e cole **UM POR VEZ** no terminal:

```bash
# ===== INVESTIGAÇÃO DB-0 (Buffer/Queues) =====
echo "━━━━━━━━━━ DB-0 (Buffer) ━━━━━━━━━━"
redis-cli -n 0 KEYS "*bella*"
redis-cli -n 0 KEYS "*sorriso*"
redis-cli -n 0 DBSIZE
echo ""

# ===== INVESTIGAÇÃO DB-1 (Memory/Cache) =====
echo "━━━━━━━━━━ DB-1 (Cache) ━━━━━━━━━━"
redis-cli -n 1 KEYS "*bella*"
redis-cli -n 1 KEYS "*sorriso*"
redis-cli -n 1 KEYS "*clinica*"
redis-cli -n 1 KEYS "*estetica*"
redis-cli -n 1 DBSIZE
echo ""

# ===== BUSCAR CHAVES COM CONTEXTO =====
echo "━━━━━━━━━━ Contextos ━━━━━━━━━━"
redis-cli -n 1 KEYS "*context*"
redis-cli -n 1 KEYS "*response*"
redis-cli -n 1 KEYS "*prompt*"
echo ""

# ===== VER CONTEÚDO DE UMA CHAVE =====
# Se aparecer chaves acima, ver conteúdo:
# redis-cli -n 1 GET "NOME_DA_CHAVE_AQUI"
```

---

### 3️⃣ Interpretar Resultados

**Se aparecer MUITAS chaves:**
```
1) "estetica_bella_rede:context:12345"
2) "clinica_sorriso_001:response:67890"
3) ...
```
✅ **Isso é NORMAL!** Cada cliente tem suas chaves.

---

**Se aparecer CHAVES MISTURADAS:**
```
1) "estetica_bella_rede:context:12345"
   Conteúdo: "Clinica Sorriso odontologia..."  ❌ PROBLEMA!
```
⚠️ **Contaminação detectada!** Chave da Bella tem dados da Clínica Sorriso.

---

### 4️⃣ Ver Conteúdo de Chave Suspeita

Se encontrou chave suspeita, ver conteúdo:

```bash
# Substituir NOME_DA_CHAVE pelo nome real que apareceu
redis-cli -n 1 GET "NOME_DA_CHAVE"

# Exemplo:
redis-cli -n 1 GET "estetica_bella_rede:context:12345"
```

**O que procurar:**
- ❌ Chave da Bella contendo "Clínica Sorriso", "odontologia", "dentista"
- ❌ Chave da Clínica Sorriso contendo "Bella Estética", "harmonização"
- ❌ Imagens erradas: `consultorio-recepcao.jpg` em chave da Bella (se for da Clínica)

---

### 5️⃣ Limpar Cache (Se Encontrou Problema)

**OPÇÃO A: Limpar APENAS DB-1 (Cache) - RECOMENDADO** ✅

```bash
# Confirmar DB atual
redis-cli PING  # Deve retornar "PONG"

# Limpar DB-1 (cache)
redis-cli -n 1 FLUSHDB

# Verificar se limpou
redis-cli -n 1 DBSIZE  # Deve retornar: (integer) 0

echo "✅ Cache DB-1 limpo! Cache será regenerado automaticamente."
```

**Impacto:**
- ✅ Cache limpo (problema resolvido)
- ✅ Performance pode cair por ~5 minutos (enquanto regenera)
- ✅ Nenhum dado permanente perdido
- ✅ Reversível (cache regenera sozinho)

---

**OPÇÃO B: Limpar AMBOS DB-0 e DB-1** ⚠️ MAIS AGRESSIVO

```bash
# ⚠️ CUIDADO: Isso limpa buffer de mensagens também!

# Limpar DB-0 (buffer)
redis-cli -n 0 FLUSHDB

# Limpar DB-1 (cache)
redis-cli -n 1 FLUSHDB

echo "✅ Ambos DBs limpos!"
```

**Quando usar:**
- Se DB-0 também tem problemas
- Se problema persistir após limpar só DB-1

---

**OPÇÃO C: Limpar chaves específicas** 🎯 CIRÚRGICO

```bash
# Deletar chaves específicas (substituir pelo nome real)
redis-cli -n 1 DEL "estetica_bella_rede:context:12345"
redis-cli -n 1 DEL "clinica_sorriso_001:response:67890"

# Ou deletar por padrão (CUIDADO!)
redis-cli -n 1 --scan --pattern "*bella*context*" | xargs redis-cli -n 1 DEL

echo "✅ Chaves específicas deletadas!"
```

---

### 6️⃣ Testar no WhatsApp

Após limpar cache:

1. **Esperar 30 segundos** (n8n detectar mudança)
2. **Enviar mensagem teste:**
   ```
   Qual o endereço da clínica?
   ```
3. **Verificar resposta:**
   - ✅ **Correto:** "Av. das Américas, 5000 - Sala 301"
   - ❌ **Ainda errado:** "Rua das Flores, 123" → Problema não é Redis!

---

## 🔬 COMANDOS ÚTEIS EXTRAS

### Ver Info Geral do Redis
```bash
redis-cli INFO
redis-cli INFO stats
redis-cli INFO keyspace
```

### Monitorar em Tempo Real
```bash
# Ver TODOS os comandos executados (debug)
redis-cli MONITOR

# Parar: Ctrl+C
```

### Ver Memória Usada
```bash
redis-cli INFO memory
```

### Buscar chaves por TTL
```bash
# Ver TTL de uma chave (tempo até expirar)
redis-cli TTL "nome_da_chave"

# -1 = sem expiração
# -2 = chave não existe
# número positivo = segundos até expirar
```

---

## 📊 DIAGNÓSTICO RÁPIDO

Execute este bloco completo de uma vez:

```bash
echo "=========================================="
echo "🔍 DIAGNÓSTICO REDIS MULTI-TENANT"
echo "=========================================="
echo ""
echo "📊 DB-0 (Buffer/Queues):"
redis-cli -n 0 DBSIZE
echo ""
echo "💾 DB-1 (Memory/Cache):"
redis-cli -n 1 DBSIZE
echo ""
echo "🔑 Chaves Bella Estética:"
redis-cli -n 1 KEYS "*bella*" | wc -l
echo ""
echo "🔑 Chaves Clínica Sorriso:"
redis-cli -n 1 KEYS "*sorriso*" | wc -l
echo ""
echo "📈 Memória Redis:"
redis-cli INFO memory | grep used_memory_human
echo ""
echo "⚡ Redis Online?"
redis-cli PING
echo "=========================================="
```

**Resultado esperado:**
```
==========================================
🔍 DIAGNÓSTICO REDIS MULTI-TENANT
==========================================

📊 DB-0 (Buffer/Queues):
(integer) 5

💾 DB-1 (Memory/Cache):
(integer) 23

🔑 Chaves Bella Estética:
12

🔑 Chaves Clínica Sorriso:
11

📈 Memória Redis:
used_memory_human:2.34M

⚡ Redis Online?
PONG
==========================================
```

---

## 🚨 TROUBLESHOOTING

### Problema: "redis-cli: command not found"

**Solução:** Redis não está instalado no container. Tentar:

```bash
# Opção 1: Instalar redis-cli
apt-get update && apt-get install -y redis-tools

# Opção 2: Usar redis diretamente (se for Alpine Linux)
apk add redis

# Opção 3: Usar redis-cli via nc (netcat)
echo "PING" | nc localhost 6379
```

---

### Problema: "Could not connect to Redis"

**Solução:** Redis não está rodando. No Easypanel:
1. Services → Redis → **Restart**
2. Aguardar 30 segundos
3. Tentar novamente

---

### Problema: Cache limpo mas problema persiste

**Possíveis causas:**
1. ❌ Problema não é Redis (pode ser hardcoded no workflow)
2. ❌ Cache em outro lugar (n8n interno?)
3. ❌ LLM fazendo hallucination (system prompt fraco)

**Próximos passos:**
- Investigar workflow para URLs hardcoded
- Fortalecer system prompt
- Verificar se n8n tem cache próprio

---

## ✅ CHECKLIST

Após investigar:

- [ ] Redis acessível (PONG)
- [ ] DB-1 tem chaves?
- [ ] Encontrou contaminação?
- [ ] Limpou cache (se necessário)
- [ ] Testou no WhatsApp
- [ ] Problema resolvido? ✅
- [ ] Se não: Problema não é Redis ❌

---

**Resultado:**
- ✅ **Redis OK:** Problema resolvido!
- ❌ **Redis limpo mas problema continua:** Investigar workflow/hardcoded images

---

**Tempo estimado:** 5-10 minutos

**Próximo passo se não resolver:**
- Inspecionar workflow para hardcoded image URLs
- Fortalecer system prompt com regras anti-hallucination

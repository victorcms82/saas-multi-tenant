# Verificar Cache Redis no Easypanel

## 🎯 Objetivo
Verificar se há cache de mídia da Clínica Sorriso sendo usado incorretamente pela Bella Estética

## 📋 Passos no Easypanel

### 1. Acessar o Terminal do Redis

1. No painel do Easypanel, vá em **Services**
2. Localize o serviço **Redis** (ou o container que roda Redis para n8n)
3. Clique em **Terminal** ou **Console**

### 2. Conectar ao Redis CLI

No terminal do container, execute:

```bash
redis-cli
```

### 3. Verificar Todas as Keys

```redis
# Listar TODAS as keys (cuidado em produção - pode ser muitas)
KEYS *

# OU buscar por padrões específicos:
KEYS *media*
KEYS *client*
KEYS *estetica_bella*
KEYS *clinica_sorriso*
KEYS *workflow*
KEYS *cache*
```

### 4. Investigar Keys Suspeitas

Para cada key encontrada, verifique o conteúdo:

```redis
# Ver tipo da key
TYPE nome_da_key

# Se for STRING:
GET nome_da_key

# Se for HASH:
HGETALL nome_da_key

# Se for LIST:
LRANGE nome_da_key 0 -1

# Se for SET:
SMEMBERS nome_da_key
```

### 5. Buscar por Mídia da Clínica Sorriso

Procure por:
- `equipe-completa.jpg`
- `consultorio-recepcao.jpg`
- `tabela-precos.pdf`
- `clinica_sorriso_001`

Comandos úteis:

```redis
# Procurar em TODAS as keys (pode demorar)
KEYS *equipe*
KEYS *sorriso*

# Ver informações de uma key específica
TTL nome_da_key  # Tempo de expiração
```

### 6. Limpar Cache (se encontrar problema)

```redis
# Deletar key específica
DEL nome_da_key

# OU limpar TUDO (⚠️ USE COM CUIDADO!)
FLUSHDB  # Limpa database atual
FLUSHALL # Limpa TODOS os databases
```

## 🔍 O que Procurar

### ❌ **PROBLEMA CONFIRMADO se encontrar:**
- Keys com `clinica_sorriso` sendo usadas por `estetica_bella`
- Keys de mídia sem `client_id` (compartilhadas globalmente)
- Cache de workflow com hardcoded `clinica_sorriso_001`

### ✅ **CORRETO:**
- Keys separadas por client_id: `media:estetica_bella_rede:*`
- Nenhum cache cross-tenant
- Keys com TTL (expiração automática)

## 📊 Comandos de Diagnóstico Avançados

```redis
# Ver estatísticas do Redis
INFO stats

# Ver todas as databases
INFO keyspace

# Verificar memória usada
INFO memory

# Monitorar comandos em tempo real (Ctrl+C para sair)
MONITOR
```

## 🚨 Se NÃO tiver acesso ao Redis CLI

### Alternativa 1: Via Docker (se tiver acesso SSH)

```bash
# Listar containers
docker ps | grep redis

# Acessar container
docker exec -it <container_id_redis> redis-cli

# Executar comandos direto
docker exec -it <container_id_redis> redis-cli KEYS "*media*"
```

### Alternativa 2: Via n8n (se tiver Redis node)

No n8n, crie um workflow temporário com node **Redis**:
- Operation: `keys`
- Pattern: `*media*`

## 📝 Resultados Esperados

### Cenário 1: Cache é o problema
```
Keys encontradas:
- workflow:media:equipe-completa.jpg -> tem dados da clinica_sorriso
- Solução: FLUSHDB ou DEL específico
```

### Cenário 2: Cache está limpo
```
Keys encontradas:
- (vazio) OU
- Keys específicas por client_id corretas
- Solução: Problema está no workflow n8n, não no cache
```

## ⚡ Quick Test

Execute isto para teste rápido:

```bash
# Dentro do container Redis
redis-cli --scan --pattern "*" | head -20
redis-cli GET "workflow:default:media" 2>/dev/null || echo "Key não encontrada"
```

---

## 📤 Próximo Passo

Depois de executar, me envie:
1. Output de `KEYS *media*`
2. Output de `KEYS *sorriso*`
3. Output de `KEYS *bella*`
4. Conteúdo de qualquer key suspeita (GET/HGETALL)

Com isso, vou saber se o problema é cache ou se está no código do workflow!

# 🛠️ Comandos Úteis - Plataforma SaaS Multi-Tenant

## 📋 Quick Reference

### n8n

```bash
# Acessar n8n
https://seu-n8n.com

# Ver logs do n8n (Docker)
docker logs -f easypanel-n8n

# Reiniciar n8n
docker restart easypanel-n8n

# Backup workflows
curl https://seu-n8n.com/api/v1/workflows \
  -H "X-N8N-API-KEY: sua-chave" > workflows-backup.json
```

### Supabase

```bash
# Conectar ao banco
psql "postgresql://postgres:[SENHA]@db.[PROJETO].supabase.co:5432/postgres"

# Backup database
pg_dump "postgresql://postgres:[SENHA]@db.[PROJETO].supabase.co:5432/postgres" \
  > backup-$(date +%Y%m%d).sql

# Restore database
psql "postgresql://postgres:[SENHA]@db.[PROJETO].supabase.co:5432/postgres" \
  < backup-20251106.sql
```

### Redis

```bash
# Conectar ao Redis
redis-cli -h [HOST] -p 6379 -a [SENHA]

# Listar todas as keys
KEYS *

# Ver keys por pattern
KEYS buffer:*
KEYS memory:*
KEYS embedding:*

# Flush database (CUIDADO!)
# FLUSHDB  # Apenas DB atual
# FLUSHALL # Todas DBs

# Info do Redis
INFO

# Monitorar comandos em tempo real
MONITOR
```

---

## 🔍 Queries SQL Úteis

### Monitoramento

```sql
-- Dashboard em tempo real (últimas 24h)
SELECT 
  client_id,
  COUNT(*) as total_executions,
  COUNT(*) FILTER (WHERE status = 'success') as successful,
  COUNT(*) FILTER (WHERE status = 'error') as errors,
  ROUND(AVG(total_latency_ms)::numeric, 2) as avg_latency_ms,
  ROUND(SUM(total_cost_usd)::numeric, 6) as total_cost_usd,
  SUM(total_tokens) as total_tokens
FROM agent_executions
WHERE timestamp > now() - interval '24 hours'
GROUP BY client_id
ORDER BY total_executions DESC;

-- Últimas 10 execuções de um cliente
SELECT 
  timestamp,
  conversation_id,
  LEFT(user_message, 50) as message,
  LEFT(agent_response, 50) as response,
  total_latency_ms,
  total_cost_usd,
  status
FROM agent_executions
WHERE client_id = 'SEU_CLIENT_ID'
ORDER BY timestamp DESC
LIMIT 10;

-- Execuções com erro
SELECT 
  timestamp,
  client_id,
  error_message,
  status
FROM agent_executions
WHERE status != 'success'
ORDER BY timestamp DESC
LIMIT 20;

-- Performance por hora (hoje)
SELECT 
  date_trunc('hour', timestamp) as hour,
  COUNT(*) as executions,
  ROUND(AVG(total_latency_ms)::numeric, 2) as avg_latency,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_latency_ms)::numeric, 2) as p95_latency
FROM agent_executions
WHERE timestamp > date_trunc('day', now())
GROUP BY hour
ORDER BY hour DESC;
```

### Billing & Usage

```sql
-- Custos do mês atual
SELECT 
  client_id,
  total_requests,
  total_tokens,
  images_generated,
  rag_searches,
  ROUND(total_cost_usd::numeric, 2) as cost_usd
FROM client_usage
WHERE billing_period = date_trunc('month', now())
ORDER BY total_cost_usd DESC;

-- Projeção de custo mensal
WITH daily_avg AS (
  SELECT 
    client_id,
    AVG(daily_cost) as avg_daily_cost
  FROM (
    SELECT 
      client_id,
      date_trunc('day', timestamp) as day,
      SUM(total_cost_usd) as daily_cost
    FROM agent_executions
    WHERE timestamp > now() - interval '7 days'
    GROUP BY client_id, day
  ) daily
  GROUP BY client_id
)
SELECT 
  client_id,
  ROUND((avg_daily_cost * 30)::numeric, 2) as projected_monthly_cost
FROM daily_avg
ORDER BY projected_monthly_cost DESC;

-- Rate limits próximos do limite
SELECT 
  r.client_id,
  c.client_name,
  r.minute_count,
  (c.rate_limits->>'requests_per_minute')::int as limit_per_minute,
  r.day_count,
  (c.rate_limits->>'requests_per_day')::int as limit_per_day,
  r.month_tokens,
  (c.rate_limits->>'tokens_per_month')::int as limit_tokens_month
FROM rate_limit_buckets r
JOIN clients c ON c.client_id = r.client_id
WHERE 
  r.minute_count > (c.rate_limits->>'requests_per_minute')::int * 0.8
  OR r.day_count > (c.rate_limits->>'requests_per_day')::int * 0.8
  OR r.month_tokens > (c.rate_limits->>'tokens_per_month')::int * 0.8;
```

### RAG & Documents

```sql
-- Documentos por cliente
SELECT 
  client_id,
  COUNT(DISTINCT document_id) as total_documents,
  COUNT(*) as total_chunks,
  SUM(chunk_tokens) as total_tokens
FROM rag_documents
WHERE is_active = true
GROUP BY client_id
ORDER BY total_documents DESC;

-- Documentos mais usados (top 10)
SELECT 
  r.source_name,
  r.source_type,
  COUNT(*) as times_used,
  ROUND(AVG(similarity)::numeric, 3) as avg_similarity
FROM rag_documents r
JOIN LATERAL (
  SELECT similarity
  FROM jsonb_to_recordset(
    (SELECT rag_context FROM agent_executions WHERE rag_context IS NOT NULL LIMIT 1000)
  ) AS x(id uuid, similarity numeric)
  WHERE x.id = r.id
) searches ON true
GROUP BY r.source_name, r.source_type
ORDER BY times_used DESC
LIMIT 10;

-- Chunks de baixa qualidade (score < 0.5)
SELECT 
  document_id,
  source_name,
  chunk_index,
  quality_score,
  LEFT(chunk_text, 100) as preview
FROM rag_documents
WHERE quality_score < 0.5
  AND is_active = true
ORDER BY quality_score ASC
LIMIT 20;
```

### Analytics

```sql
-- Conversas ativas (últimos 7 dias)
SELECT 
  client_id,
  COUNT(DISTINCT conversation_id) as active_conversations,
  COUNT(DISTINCT contact_id) as unique_contacts
FROM agent_executions
WHERE timestamp > now() - interval '7 days'
GROUP BY client_id;

-- Horários de pico
SELECT 
  EXTRACT(hour FROM timestamp) as hour,
  COUNT(*) as executions
FROM agent_executions
WHERE timestamp > now() - interval '7 days'
GROUP BY hour
ORDER BY hour;

-- Ferramentas mais usadas
SELECT 
  tool->>'tool_name' as tool_name,
  COUNT(*) as times_used
FROM agent_executions,
  jsonb_array_elements(tools_called) as tool
WHERE timestamp > now() - interval '30 days'
GROUP BY tool_name
ORDER BY times_used DESC;

-- Taxa de conversão (leads → qualificados)
-- Exemplo: baseado em memory.lead_stage
SELECT 
  client_id,
  COUNT(*) FILTER (WHERE memory->>'lead_stage' = 'new') as new_leads,
  COUNT(*) FILTER (WHERE memory->>'lead_stage' = 'qualified') as qualified,
  ROUND(
    COUNT(*) FILTER (WHERE memory->>'lead_stage' = 'qualified')::numeric / 
    NULLIF(COUNT(*) FILTER (WHERE memory->>'lead_stage' = 'new'), 0) * 100,
    2
  ) as conversion_rate
FROM (
  SELECT DISTINCT ON (client_id, conversation_id)
    client_id,
    conversation_id,
    conversation_history->-1 as memory
  FROM agent_executions
  WHERE timestamp > now() - interval '30 days'
) conversations
GROUP BY client_id;
```

---

## 🧹 Manutenção

### Limpeza de Dados Antigos

```sql
-- Deletar execuções antigas (> 90 dias)
DELETE FROM agent_executions
WHERE timestamp < now() - interval '90 days';

-- Arquivar chunks antigos de RAG
UPDATE rag_documents
SET is_active = false
WHERE metadata->>'expires_at' IS NOT NULL
  AND (metadata->>'expires_at')::timestamptz < now();

-- Limpar rate limit buckets de clientes inativos
DELETE FROM rate_limit_buckets
WHERE client_id IN (
  SELECT client_id FROM clients WHERE is_active = false
);
```

### Redis Cleanup

```bash
# Limpar buffers expirados (já acontece automaticamente via TTL)
# Mas pode forçar se necessário:
redis-cli --scan --pattern "buffer:*" | xargs -L 100 redis-cli DEL

# Limpar memórias antigas (> 30 dias sem interação)
# Fazer via script Python/Node, exemplo:
# for key in redis.scan_iter("memory:*"):
#   last_interaction = redis.hget(key, "last_interaction")
#   if older_than_30_days(last_interaction):
#     redis.delete(key)
```

---

## 🧪 Testes

### Testar Webhook

```bash
# Mensagem simples
curl -X POST "https://seu-n8n.com/webhook/gestor-ia?client_id=test-client" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation": {"id": 123},
    "sender": {"name": "Teste", "phone_number": "+5521999999999"},
    "content": "Olá, teste!",
    "message_type": "text",
    "inbox": {"id": 1},
    "account": {"id": 1}
  }'

# Teste de load (100 requisições)
for i in {1..100}; do
  curl -X POST "https://seu-n8n.com/webhook/gestor-ia?client_id=test-client" \
    -H "Content-Type: application/json" \
    -d "{\"conversation\":{\"id\":$i},\"sender\":{\"name\":\"User$i\"},\"content\":\"Mensagem $i\"}" &
done
wait
```

### Testar RAG Search

```sql
-- Testar busca direta
SELECT * FROM search_rag_hybrid(
  p_namespace := 'test-client-rag',
  p_query_embedding := (
    -- Pegar embedding de uma query de teste
    SELECT embedding FROM rag_documents 
    WHERE rag_namespace = 'test-client-rag' 
    LIMIT 1
  ),
  p_query_text := 'preços',
  p_limit := 5,
  p_semantic_weight := 0.7,
  p_min_similarity := 0.7
);
```

### Testar Rate Limit

```sql
-- Simular incremento
SELECT check_and_increment_rate_limit('test-client', 500);

-- Ver status atual
SELECT * FROM rate_limit_buckets WHERE client_id = 'test-client';

-- Resetar (para testes)
DELETE FROM rate_limit_buckets WHERE client_id = 'test-client';
```

---

## 📊 Exports

### Exportar Dados

```bash
# Exportar execuções do mês
psql "postgresql://..." -c "
COPY (
  SELECT * FROM agent_executions 
  WHERE timestamp >= date_trunc('month', now())
) TO STDOUT CSV HEADER
" > executions-$(date +%Y%m).csv

# Exportar usage
psql "postgresql://..." -c "
COPY (
  SELECT * FROM client_usage 
  WHERE billing_period = date_trunc('month', now())
) TO STDOUT CSV HEADER
" > usage-$(date +%Y%m).csv
```

### Gerar Relatórios

```sql
-- Relatório mensal por cliente
SELECT 
  c.client_id,
  c.client_name,
  c.package,
  u.total_requests,
  u.total_tokens,
  u.images_generated,
  ROUND(u.total_cost_usd::numeric, 2) as cost_usd,
  CASE 
    WHEN c.package = 'starter' THEN 197.00
    WHEN c.package = 'pro' THEN 497.00
    WHEN c.package = 'enterprise' THEN 997.00
  END as monthly_revenue,
  ROUND(
    (CASE 
      WHEN c.package = 'starter' THEN 197.00
      WHEN c.package = 'pro' THEN 497.00
      WHEN c.package = 'enterprise' THEN 997.00
    END - u.total_cost_usd)::numeric,
    2
  ) as profit
FROM clients c
LEFT JOIN client_usage u ON u.client_id = c.client_id
  AND u.billing_period = date_trunc('month', now())
WHERE c.is_active = true
ORDER BY profit DESC;
```

---

## 🚨 Alertas & Monitoramento

### Queries para Alertas

```sql
-- Clientes próximos do limite (> 90% quota)
SELECT 
  c.client_id,
  c.admin_email,
  r.month_tokens,
  (c.rate_limits->>'tokens_per_month')::int as limit,
  ROUND(r.month_tokens::numeric / (c.rate_limits->>'tokens_per_month')::int * 100, 2) as usage_percent
FROM rate_limit_buckets r
JOIN clients c ON c.client_id = r.client_id
WHERE r.month_tokens > (c.rate_limits->>'tokens_per_month')::int * 0.9;

-- Erros aumentando (> 5% nas últimas 2 horas)
SELECT 
  client_id,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE status = 'error') as errors,
  ROUND(COUNT(*) FILTER (WHERE status = 'error')::numeric / COUNT(*) * 100, 2) as error_rate
FROM agent_executions
WHERE timestamp > now() - interval '2 hours'
GROUP BY client_id
HAVING COUNT(*) FILTER (WHERE status = 'error')::numeric / COUNT(*) > 0.05;

-- Latência alta (> 5s)
SELECT 
  client_id,
  conversation_id,
  total_latency_ms,
  timestamp
FROM agent_executions
WHERE total_latency_ms > 5000
  AND timestamp > now() - interval '1 hour'
ORDER BY total_latency_ms DESC;
```

---

## 🔧 Troubleshooting

### Debug Workflow

```bash
# Ver execuções do n8n
curl https://seu-n8n.com/api/v1/executions \
  -H "X-N8N-API-KEY: sua-chave" \
  | jq '.data[] | {id, mode, status, startedAt}'

# Ver detalhes de uma execução
curl https://seu-n8n.com/api/v1/executions/[EXECUTION_ID] \
  -H "X-N8N-API-KEY: sua-chave" \
  | jq .
```

### Debug LLM

```sql
-- Ver prompts enviados ao LLM
SELECT 
  timestamp,
  client_id,
  LEFT(system_prompt_used, 100) as prompt_preview,
  llm_model,
  prompt_tokens,
  completion_tokens
FROM agent_executions
WHERE client_id = 'SEU_CLIENT_ID'
ORDER BY timestamp DESC
LIMIT 5;
```

### Debug RAG

```sql
-- Ver contexto RAG usado
SELECT 
  timestamp,
  client_id,
  rag_context->0->>'source_name' as top_source,
  rag_context->0->>'similarity' as similarity,
  jsonb_array_length(rag_context) as chunks_used
FROM agent_executions
WHERE rag_context IS NOT NULL
  AND client_id = 'SEU_CLIENT_ID'
ORDER BY timestamp DESC
LIMIT 10;
```

---

**Última atualização**: 06/11/2025  
**Autor**: Victor Castro - Evolute Digital

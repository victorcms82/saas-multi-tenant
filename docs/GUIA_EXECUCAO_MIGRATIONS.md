# 🚀 GUIA DE EXECUÇÃO DAS MIGRATIONS

**Data:** 06/11/2025  
**Status:** ✅ Pronto para execução

---

## 📋 PRÉ-REQUISITOS

- [ ] Backup do banco de dados Supabase
- [ ] Acesso ao Supabase SQL Editor
- [ ] Cliente existente: `clinica_sorriso_001` (opcional)

---

## 🎯 ORDEM DE EXECUÇÃO

### 1️⃣ Migration 001 - Tabela Agents

**Arquivo:** `database/migrations/001_add_agents_table_CUSTOM.sql`

**O que faz:**
- Cria tabela `agents` com suporte a múltiplos agentes por cliente
- Migra dados de `clients` → `agents` (agente 'default')
- Adiciona campo `max_agents` em `clients`
- Atualiza tabelas relacionadas (rag_documents, agent_executions, channels)

**Executar:**
```bash
# Via Supabase Dashboard
1. Abra SQL Editor
2. Cole o conteúdo de 001_add_agents_table_CUSTOM.sql
3. Execute (Run)

# Ou via psql
psql $SUPABASE_CONNECTION_STRING -f database/migrations/001_add_agents_table_CUSTOM.sql
```

**Tempo estimado:** 10-30 segundos

**Output esperado:**
```
========================================
MIGRATION 001: Migrando dados de clients → agents
========================================
Clientes encontrados: 1
Agentes criados: 1
Formato rag_namespace: client_id/default
Tabela rag_documents não existe (ok, será criada depois)
Tabela agent_executions não existe (ok, será criada depois)
Tabela channels não existe (ok)

========================================
VERIFICAÇÃO DE INTEGRIDADE
========================================
Total de clientes: 1
Total de agentes: 1
Nenhum agente órfão (OK)
Todos os clientes têm pelo menos 1 agente (OK)

✅ Migration 001 completa!
========================================
```

---

### 2️⃣ Migration 002 - Sistema de Marketplace

**Arquivo:** `database/migrations/002_add_marketplace_tables.sql`

**O que faz:**
- Cria 6 tabelas: `agent_templates`, `client_subscriptions`, `feature_pricing`, `client_usage`, `pricing_experiments`, `subscription_events`
- Popula 4 templates iniciais (SDR Starter, SDR Pro, Suporte Básico, Suporte Premium)
- Cria 5 features de pricing (transcrição, imagens, docs RAG, etc)
- **MIGRA clientes existentes:**
  - Atualiza `agents.template_id` baseado no package antigo
  - Cria assinaturas ativas para todos os agentes
  - Adiciona FK `agents → agent_templates`
- Cria 12 funções de negócio
- Cria 3 views úteis
- Cria triggers automáticos

**Executar:**
```bash
# Via Supabase Dashboard
1. Abra SQL Editor
2. Cole o conteúdo de 002_add_marketplace_tables.sql
3. Execute (Run)

# Ou via psql
psql $SUPABASE_CONNECTION_STRING -f database/migrations/002_add_marketplace_tables.sql
```

**Tempo estimado:** 1-2 minutos

**Output esperado:**
```
========================================
MIGRANDO CLIENTES EXISTENTES
========================================
Agentes atualizados com template_id: 1
Assinaturas criadas para clientes existentes: 1
FK agents → agent_templates criada

✅ Migração de clientes existentes completa!
========================================

========================================
MIGRATION 002 COMPLETA
========================================
Templates criados: 4
Features de pricing criadas: 5
Agentes com template_id: 1
Assinaturas ativas: 1

✅ Sistema de marketplace FLEXÍVEL criado!
✅ Clientes existentes migrados com sucesso!
========================================
```

---

### 3️⃣ Validação do Sistema (Opcional mas Recomendado)

**Arquivo:** `database/migrations/003_validate_system.sql`

**O que faz:**
- Verifica estrutura de tabelas
- Valida foreign keys
- Detecta dados órfãos
- Checa índices
- Mostra estatísticas (MRR, clientes, agentes, etc)

**Executar:**
```bash
psql $SUPABASE_CONNECTION_STRING -f database/migrations/003_validate_system.sql
```

**Output esperado:**
```
========================================
VALIDAÇÃO DE INTEGRIDADE DO SISTEMA
========================================

1. Verificando estrutura de tabelas...
  ✅ Tabela agents existe
  ✅ Tabela agent_templates existe
  ✅ Tabela client_subscriptions existe

2. Verificando foreign keys...
  ✅ FK agents → agent_templates existe
  ✅ FKs de client_subscriptions existem (3 encontradas)

3. Verificando integridade de dados...
  ✅ Nenhum agente órfão
  ✅ Todos os agentes têm template_id
  ✅ Todos os template_id são válidos
  ✅ Todas as assinaturas têm agente correspondente

4. Estatísticas do sistema:
  📊 Clientes: 1
  📊 Agentes ativos: 1
  📊 Templates disponíveis: 4
  📊 Assinaturas ativas: 1
  💰 MRR Total: R$ 697

========================================
RESULTADO DA VALIDAÇÃO
========================================
❌ Erros críticos: 0
⚠️  Avisos: 0

✅✅✅ SISTEMA 100% ÍNTEGRO! ✅✅✅
========================================
```

---

## 🔍 VERIFICAÇÃO MANUAL

Após executar as migrations, rode estas queries para confirmar:

### 1. Ver agente migrado
```sql
SELECT 
  client_id, agent_id, template_id, agent_name, is_active
FROM agents
WHERE client_id = 'clinica_sorriso_001';
```

**Esperado:**
```
client_id            | agent_id | template_id | agent_name       | is_active
--------------------+----------+-------------+------------------+-----------
clinica_sorriso_001 | default  | sdr-starter | Agente Principal | true
```

### 2. Ver assinatura criada
```sql
SELECT 
  client_id, agent_id, template_id, status, monthly_price
FROM client_subscriptions
WHERE client_id = 'clinica_sorriso_001';
```

**Esperado:**
```
client_id            | agent_id | template_id | status | monthly_price
--------------------+----------+-------------+--------+---------------
clinica_sorriso_001 | default  | sdr-starter | active | 697.00
```

### 3. Ver templates disponíveis
```sql
SELECT template_id, template_name, monthly_price, is_active
FROM agent_templates
ORDER BY monthly_price;
```

**Esperado:**
```
template_id      | template_name    | monthly_price | is_active
-----------------+------------------+---------------+-----------
support-basic    | Suporte Básico   | 497.00        | true
sdr-starter      | SDR Starter      | 697.00        | true
support-premium  | Suporte Premium  | 997.00        | true
sdr-pro          | SDR Pro          | 1297.00       | true
```

### 4. Ver MRR total
```sql
SELECT 
  COUNT(*) as total_subscriptions,
  SUM(monthly_price) as mrr_total
FROM client_subscriptions
WHERE status = 'active';
```

**Esperado:**
```
total_subscriptions | mrr_total
--------------------+-----------
1                   | 697.00
```

---

## 🚨 TROUBLESHOOTING

### Erro: "function handle_updated_at() does not exist"

**Solução:** Execute antes da Migration 001:
```sql
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Erro: "table packages does not exist"

**Isso é normal!** A Migration 001 tenta fazer JOIN com `packages` mas falha silenciosamente. Isso foi resolvido removendo essa dependência.

### Erro: "duplicate key value violates unique constraint"

**Causa:** Rodou a migration 2x.  
**Solução:** Rodar rollback e executar novamente.

---

## 🔄 ROLLBACK (Se necessário)

### Reverter Migration 002
```sql
DROP TABLE IF EXISTS public.subscription_events CASCADE;
DROP TABLE IF EXISTS public.pricing_experiments CASCADE;
DROP TABLE IF EXISTS public.client_usage CASCADE;
DROP TABLE IF EXISTS public.feature_pricing CASCADE;
DROP TABLE IF EXISTS public.client_subscriptions CASCADE;
DROP TABLE IF EXISTS public.agent_templates CASCADE;

-- Remover FK de agents
ALTER TABLE public.agents DROP CONSTRAINT IF EXISTS fk_agents_template;
```

### Reverter Migration 001
```sql
DROP TABLE IF EXISTS public.agents CASCADE;
ALTER TABLE public.clients DROP COLUMN IF EXISTS max_agents;
ALTER TABLE public.rag_documents DROP COLUMN IF EXISTS agent_id;
ALTER TABLE public.agent_executions DROP COLUMN IF EXISTS agent_id;
ALTER TABLE public.channels DROP COLUMN IF EXISTS assigned_agent_id;
```

---

## ✅ CHECKLIST FINAL

- [ ] Migration 001 executada com sucesso
- [ ] Migration 002 executada com sucesso
- [ ] Validação 003 rodada (0 erros)
- [ ] Queries de verificação manual OK
- [ ] Cliente existente migrado (se aplicável)
- [ ] MRR calculado corretamente

---

## 📚 PRÓXIMOS PASSOS

1. **Testar criação de nova assinatura:**
   ```sql
   SELECT create_subscription_from_template(
     'clinica_sorriso_001',
     'sdr-vendas',
     'sdr-pro',
     7  -- 7 dias de trial
   );
   ```

2. **Testar incremento de uso:**
   ```sql
   SELECT increment_usage(
     'clinica_sorriso_001',
     'default',
     'messages',
     100
   );
   ```

3. **Ver uso atual:**
   ```sql
   SELECT current_usage
   FROM client_subscriptions
   WHERE client_id = 'clinica_sorriso_001';
   ```

4. **Explorar views:**
   ```sql
   -- Revenue por template
   SELECT * FROM v_template_revenue;
   
   -- Alertas de uso
   SELECT * FROM v_usage_alerts;
   
   -- Trials expirando
   SELECT * FROM v_trials_expiring_soon;
   ```

---

## 🎉 CONCLUSÃO

Após executar as migrations com sucesso, você terá:

✅ **Sistema multi-agente** funcionando  
✅ **Marketplace flexível** com 4 templates  
✅ **Sistema de assinaturas** ativo  
✅ **Tracking de uso** em tempo real  
✅ **Billing automatizado** (MRR calculado)  
✅ **Audit log completo** de mudanças  
✅ **12 funções de negócio** prontas  
✅ **Cliente existente migrado** automaticamente  

**Sistema totalmente operacional e pronto para escalar! 🚀**

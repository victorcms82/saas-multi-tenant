# 🚀 GUIA DE EXECUÇÃO DAS MIGRATIONS

Execute na ordem no **SQL Editor** do Supabase Dashboard:

---

## 📍 Onde Executar

1. **Acesse:** https://supabase.com/dashboard
2. **Selecione seu projeto**
3. **Vá em:** `SQL Editor` (menu lateral esquerdo, ícone `<>`)
4. **Clique em:** `New query`
5. **Cole cada migration abaixo na ordem**
6. **Execute:** Clique em `Run` ou `Ctrl+Enter`

---

## 🔄 MIGRATION 001: Tabela AGENTS

**Arquivo:** `database/migrations/001_add_agents_table_CUSTOM.sql`

**O que faz:**
- Cria tabela `agents` (múltiplos agentes por cliente)
- Migra dados de `clients` → cria agente 'default' para cada cliente
- Adiciona campo `max_agents` em `clients`
- Atualiza tabelas relacionadas (rag_documents, agent_executions, channels)

**Execute:**
```bash
# Copie TODO o conteúdo de: database/migrations/001_add_agents_table_CUSTOM.sql
# Cole no SQL Editor e execute
```

**Resultado esperado:**
```
✅ Tabela agents criada
✅ 1 agente migrado (clinica_sorriso_001/default)
✅ Campo max_agents adicionado
✅ Verificação de integridade OK
```

---

## 🏪 MIGRATION 002: Sistema de Marketplace

**Arquivo:** `database/migrations/002_add_marketplace_tables.sql`

**O que faz:**
- Cria 6 tabelas do marketplace
- Adiciona 4 templates iniciais (SDR Starter R$697, SDR Pro R$1297, Support Basic R$497, Support Premium R$997)
- Migra `agents.template_id` baseado no package antigo
- Cria subscriptions para clientes existentes
- Adiciona 12 funções de negócio
- Cria 4 views úteis (incluindo `v_template_profitability` com margens reais)

**Execute:**
```bash
# Copie TODO o conteúdo de: database/migrations/002_add_marketplace_tables.sql
# Cole no SQL Editor e execute
```

**Resultado esperado:**
```
✅ 6 tabelas criadas
✅ 4 templates inseridos
✅ 1 subscription criada
✅ 12 funções criadas
✅ 4 views criadas
```

---

## ✅ MIGRATION 003: Validação

**Arquivo:** `database/migrations/003_validate_system.sql`

**O que faz:**
- Valida integridade de todas as tabelas
- Verifica FKs e índices
- Calcula estatísticas (MRR, agents, subscriptions)
- Gera relatório de saúde do sistema

**Execute:**
```bash
# Copie TODO o conteúdo de: database/migrations/003_validate_system.sql
# Cole no SQL Editor e execute
```

**Resultado esperado:**
```
✅ 0 erros encontrados
✅ Todas as FKs válidas
✅ MRR calculado
✅ Sistema 100% íntegro
```

---

## 🧪 QUERIES DE TESTE

Após executar as 3 migrations, teste com estas queries:

### 1️⃣ Ver Agentes Criados
```sql
SELECT * FROM public.agents;
```

### 2️⃣ Ver Templates do Marketplace
```sql
SELECT template_id, template_name, monthly_price, support_hours_included 
FROM public.agent_templates;
```

### 3️⃣ Ver Subscriptions Criadas
```sql
SELECT 
  s.client_id,
  s.agent_id,
  t.template_name,
  s.status,
  s.monthly_price
FROM public.client_subscriptions s
JOIN public.agent_templates t ON s.template_id = t.template_id;
```

### 4️⃣ Ver Lucratividade Real 🔥
```sql
SELECT 
  template_name,
  monthly_price_usd,
  total_cost_usd,
  profit_per_client_usd,
  profit_margin_percentage,
  active_subscriptions,
  total_monthly_profit_usd
FROM v_template_profitability;
```

---

## 🆘 Troubleshooting

### Erro: "relation already exists"
✅ **Normal!** As migrations usam `IF NOT EXISTS`, podem ser executadas múltiplas vezes.

### Erro: "foreign key constraint"
❌ **Executou fora de ordem!** Execute Migration 001 primeiro, depois 002, depois 003.

### Erro: "function handle_updated_at does not exist"
❌ **Falta função base!** Execute este SQL primeiro:
```sql
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 📊 Checklist Final

- [ ] Migration 001 executada (tabela agents criada)
- [ ] Migration 002 executada (marketplace completo)
- [ ] Migration 003 executada (validação OK)
- [ ] Query de teste 1 (ver agentes) ✅
- [ ] Query de teste 2 (ver templates) ✅
- [ ] Query de teste 3 (ver subscriptions) ✅
- [ ] Query de teste 4 (ver lucratividade) ✅

---

## 🎯 Próximos Passos

Após executar tudo com sucesso:

1. **Atualizar n8n workflows** para usar `agents` em vez de `clients`
2. **Testar criação de novo agente** via API
3. **Configurar billing** (Stripe/PagSeguro)
4. **Implementar frontend** do marketplace

---

**Criado em:** 06/11/2025  
**Versão:** 1.0

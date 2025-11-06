# 📚 Guia de Uso do Marketplace Multi-Agente

## 🎯 Visão Geral

Sistema flexível de marketplace de agentes com:
- ✅ Preços editáveis sem migrations
- ✅ A/B testing nativo
- ✅ Histórico automático de mudanças
- ✅ Customização por cliente
- ✅ Audit log completo

---

## 🚀 Operações Comuns

### 1. **Criar Nova Assinatura (Trial)**

```sql
-- Criar trial de 7 dias para cliente
SELECT create_subscription_from_template(
  'clinica_sorriso_001',  -- client_id
  'sdr-vendas',           -- agent_id (novo)
  'sdr-starter',          -- template_id
  7                       -- dias de trial
);

-- Retorna: UUID da assinatura
-- Ex: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
```

### 2. **Ativar Assinatura Após Trial**

```sql
-- Cliente decidiu pagar
SELECT activate_subscription('a1b2c3d4-e5f6-7890-abcd-ef1234567890');

-- Automaticamente:
-- - status: trial → active
-- - subscription_start_date: now()
-- - next_billing_date: now() + 1 month
```

### 3. **Registrar Uso de Mensagens**

```sql
-- Incrementar 1 mensagem
SELECT increment_usage(
  'clinica_sorriso_001',
  'sdr-vendas',
  'messages',
  1
);

-- Incrementar 10 minutos de transcrição
SELECT increment_usage(
  'clinica_sorriso_001',
  'sdr-vendas',
  'transcription_minutes',
  10
);

-- Se atingir limite, mostra WARNING (mas não bloqueia)
```

### 4. **Cancelar Assinatura**

```sql
-- Cancelar com motivo
SELECT cancel_subscription(
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'Cliente achou preço alto'
);

-- Status: active → cancelled
-- cancelled_at: now()
-- Registrado em subscription_events
```

---

## 💰 Gestão de Preços

### 1. **Mudar Preço de um Template**

```sql
-- Aumentar preço do SDR Starter
UPDATE agent_templates 
SET monthly_price = 797.00
WHERE template_id = 'sdr-starter';

-- ✅ Histórico salvo automaticamente em price_history
-- ✅ Assinaturas existentes mantêm preço original (via template_snapshot)
```

### 2. **Ver Histórico de Preços**

```sql
SELECT 
  template_id,
  template_name,
  monthly_price as preco_atual,
  price_history
FROM agent_templates
WHERE template_id = 'sdr-starter';

-- Retorna:
-- {
--   "date": "2025-11-06T10:30:00Z",
--   "old_price": 697,
--   "new_price": 797,
--   "changed_by": "postgres"
-- }
```

### 3. **Criar Desconto para Cliente Específico**

```sql
-- Cliente VIP: 20% de desconto
UPDATE client_subscriptions
SET 
  discount_percentage = 20,
  discount_reason = 'Cliente VIP - contrato anual',
  monthly_price = monthly_price * 0.8
WHERE client_id = 'cliente_vip_001'
  AND template_id = 'sdr-pro';
```

---

## 🧪 A/B Testing de Preços

### 1. **Criar Experimento**

```sql
INSERT INTO pricing_experiments (
  experiment_id,
  name,
  hypothesis,
  status,
  variants
) VALUES (
  'sdr_price_test_nov_2025',
  'Teste de Preço SDR Starter',
  'Aumentar de R$ 697 para R$ 797 não reduz conversão',
  'running',
  '[
    {"variant": "control", "price": 697, "weight": 0.5},
    {"variant": "test", "price": 797, "weight": 0.5}
  ]'::jsonb
);
```

### 2. **Criar Variants do Template**

```sql
-- Variant A (control)
INSERT INTO agent_templates (
  template_id, template_name, category,
  monthly_price, variant, variant_weight, experiment_id,
  -- ... outros campos
) VALUES (
  'sdr-starter-control', 'SDR Starter', 'sales',
  697, 'control', 0.5, 'sdr_price_test_nov_2025',
  -- ...
);

-- Variant B (test)
INSERT INTO agent_templates (
  template_id, template_name, category,
  monthly_price, variant, variant_weight, experiment_id,
  -- ... outros campos
) VALUES (
  'sdr-starter-test', 'SDR Starter', 'sales',
  797, 'test', 0.5, 'sdr_price_test_nov_2025',
  -- ...
);
```

### 3. **Ver Resultados**

```sql
SELECT 
  e.experiment_id,
  e.name,
  e.hypothesis,
  COUNT(s.id) as total_subscriptions,
  AVG(s.monthly_price) as avg_price,
  SUM(s.total_paid) as total_revenue
FROM pricing_experiments e
JOIN agent_templates t ON t.experiment_id = e.experiment_id
LEFT JOIN client_subscriptions s ON s.template_id = t.template_id
WHERE e.experiment_id = 'sdr_price_test_nov_2025'
GROUP BY e.experiment_id, e.name, e.hypothesis;
```

---

## 📊 Queries Úteis

### 1. **Dashboard de Revenue**

```sql
-- MRR por template
SELECT * FROM v_template_revenue
ORDER BY monthly_recurring_revenue DESC;

-- Resultado:
-- template_id     | template_name | active_subscriptions | monthly_recurring_revenue
-- sdr-pro         | SDR Pro       | 25                  | 32,425.00
-- sdr-starter     | SDR Starter   | 47                  | 32,759.00
```

### 2. **Alertas de Uso**

```sql
-- Clientes chegando ao limite
SELECT * FROM v_usage_alerts
ORDER BY usage_percentage DESC;

-- Resultado:
-- client_id           | agent_id    | messages_used | messages_limit | usage_percentage
-- clinica_abc_001     | sdr-main    | 4850          | 5000          | 97.00
-- escritorio_xyz_002  | support-bot | 4200          | 5000          | 84.00
```

### 3. **Trials Expirando**

```sql
-- Trials terminando nos próximos 7 dias
SELECT * FROM v_trials_expiring_soon;

-- Resultado:
-- client_id         | agent_id  | template_name | trial_end_date | days_remaining
-- dental_care_003   | sdr-1     | SDR Starter   | 2025-11-08     | 2
-- consultorio_004   | support   | Suporte Básico| 2025-11-10     | 4
```

### 4. **Clientes com Múltiplos Agentes**

```sql
SELECT 
  client_id,
  COUNT(*) as total_agents,
  SUM(monthly_price) as monthly_total,
  array_agg(template_id) as agent_types
FROM client_subscriptions
WHERE status = 'active'
GROUP BY client_id
HAVING COUNT(*) > 1
ORDER BY monthly_total DESC;
```

### 5. **Churn Analysis**

```sql
-- Cancelamentos por motivo
SELECT 
  subscription_metadata->>'cancellation_reason' as motivo,
  COUNT(*) as quantidade,
  ROUND(AVG(EXTRACT(DAY FROM (cancelled_at - subscription_start_date))), 0) as dias_medio_antes_cancelar
FROM client_subscriptions
WHERE status = 'cancelled'
  AND cancelled_at IS NOT NULL
GROUP BY subscription_metadata->>'cancellation_reason'
ORDER BY quantidade DESC;
```

---

## 🔄 Manutenção Mensal

### 1. **Reset de Uso (Rodar no dia 1)**

```sql
-- Reset automático de contadores
SELECT reset_monthly_usage();

-- Cria registros de usage para billing
INSERT INTO client_usage (client_id, agent_id, month, usage_data, base_cost)
SELECT 
  client_id,
  agent_id,
  date_trunc('month', now() - interval '1 month') as month,
  current_usage,
  monthly_price
FROM client_subscriptions
WHERE status = 'active';
```

### 2. **Processar Billing**

```sql
-- Listar assinaturas para cobrar
SELECT 
  s.id,
  s.client_id,
  c.client_name,
  s.monthly_price,
  s.next_billing_date,
  s.payment_method
FROM client_subscriptions s
JOIN clients c ON s.client_id = c.client_id
WHERE s.status = 'active'
  AND s.next_billing_date <= now()
ORDER BY s.next_billing_date;
```

### 3. **Expirar Trials**

```sql
-- Mudar trials expirados para 'expired'
UPDATE client_subscriptions
SET status = 'expired'
WHERE status = 'trial'
  AND trial_end_date < now();
```

---

## 🛠️ Customizações Avançadas

### 1. **Override de Limites para Cliente Específico**

```sql
-- Cliente negociou 10k mensagens ao invés de 5k
UPDATE client_subscriptions
SET custom_limits = '{
  "messages_per_month": 10000
}'::jsonb
WHERE client_id = 'cliente_enterprise_001'
  AND agent_id = 'sdr-principal';

-- Sistema respeita custom_limits ao verificar uso
```

### 2. **Adicionar Features Extras**

```sql
-- Cliente ganhou LinkedIn integration de brinde
UPDATE client_subscriptions
SET custom_features = array_append(custom_features, 'linkedin_integration')
WHERE client_id = 'cliente_vip_002'
  AND agent_id = 'sdr-1';
```

### 3. **Metadata Customizada**

```sql
-- Adicionar info de aquisição
UPDATE client_subscriptions
SET subscription_metadata = subscription_metadata || '{
  "acquisition_channel": "webinar_nov_2025",
  "sales_rep": "João Silva",
  "referral_code": "PARTNER20",
  "onboarding_completed": true
}'::jsonb
WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
```

---

## 🔍 Auditoria e Compliance

### 1. **Ver Histórico Completo de uma Assinatura**

```sql
SELECT 
  e.created_at,
  e.event_type,
  e.event_data,
  e.triggered_by,
  e.notes
FROM subscription_events e
WHERE subscription_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY e.created_at DESC;

-- Mostra TODAS as mudanças: criação, ativação, pausas, cancelamento, etc.
```

### 2. **Rastrear Mudanças de Preço**

```sql
-- Quem mudou o preço do SDR Pro e quando?
SELECT 
  template_id,
  template_name,
  price_history
FROM agent_templates
WHERE template_id = 'sdr-pro'
  AND jsonb_array_length(price_history) > 0;
```

### 3. **Receita Total por Cliente**

```sql
SELECT 
  c.client_id,
  c.client_name,
  COUNT(s.id) as total_agents,
  SUM(s.total_paid) as lifetime_value,
  MIN(s.created_at) as customer_since,
  EXTRACT(MONTH FROM age(now(), MIN(s.created_at))) as months_active
FROM clients c
JOIN client_subscriptions s ON c.client_id = s.client_id
GROUP BY c.client_id, c.client_name
ORDER BY lifetime_value DESC
LIMIT 20;
```

---

## 📈 Métricas de Negócio

### 1. **MRR (Monthly Recurring Revenue)**

```sql
SELECT 
  SUM(monthly_price) as mrr,
  COUNT(*) as active_subscriptions,
  ROUND(AVG(monthly_price), 2) as avg_subscription_value
FROM client_subscriptions
WHERE status = 'active';
```

### 2. **Churn Rate**

```sql
WITH monthly_stats AS (
  SELECT 
    date_trunc('month', created_at) as month,
    COUNT(*) FILTER (WHERE status = 'active') as active,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled
  FROM client_subscriptions
  GROUP BY month
)
SELECT 
  month,
  active,
  cancelled,
  ROUND(cancelled::numeric / NULLIF(active, 0) * 100, 2) as churn_rate_percent
FROM monthly_stats
ORDER BY month DESC
LIMIT 12;
```

### 3. **Trial Conversion Rate**

```sql
SELECT 
  template_id,
  COUNT(*) FILTER (WHERE status = 'trial') as trials,
  COUNT(*) FILTER (WHERE status = 'active' AND subscription_start_date IS NOT NULL) as converted,
  ROUND(
    COUNT(*) FILTER (WHERE status = 'active')::numeric / 
    NULLIF(COUNT(*), 0) * 100, 
    2
  ) as conversion_rate_percent
FROM client_subscriptions
WHERE created_at >= now() - interval '90 days'
GROUP BY template_id
ORDER BY conversion_rate_percent DESC;
```

---

## 🚨 Troubleshooting

### Erro: "Cliente atingiu limite máximo de agentes"

```sql
-- Ver limite atual do cliente
SELECT client_id, max_agents FROM clients WHERE client_id = 'seu_cliente_001';

-- Ver quantos agentes ele tem
SELECT COUNT(*) 
FROM client_subscriptions 
WHERE client_id = 'seu_cliente_001' 
  AND status IN ('trial', 'active', 'paused');

-- Aumentar limite
UPDATE clients SET max_agents = 5 WHERE client_id = 'seu_cliente_001';
```

### Erro: "Template não encontrado ou inativo"

```sql
-- Verificar se template existe e está ativo
SELECT template_id, template_name, is_active 
FROM agent_templates 
WHERE template_id = 'sdr-starter';

-- Ativar template
UPDATE agent_templates SET is_active = true WHERE template_id = 'sdr-starter';
```

### Warning: Cliente excedeu limite de mensagens

```sql
-- Ver uso atual vs limite
SELECT 
  s.client_id,
  s.agent_id,
  s.current_usage->>'messages_this_month' as usado,
  t.usage_limits->>'messages_per_month' as limite
FROM client_subscriptions s
JOIN agent_templates t ON s.template_id = t.template_id
WHERE s.client_id = 'cliente_001' AND s.agent_id = 'sdr-1';

-- Opção 1: Aumentar limite temporariamente
UPDATE client_subscriptions
SET custom_limits = '{"messages_per_month": 10000}'::jsonb
WHERE client_id = 'cliente_001' AND agent_id = 'sdr-1';

-- Opção 2: Reset manual do contador (emergência)
UPDATE client_subscriptions
SET current_usage = jsonb_set(current_usage, '{messages_this_month}', '0')
WHERE client_id = 'cliente_001' AND agent_id = 'sdr-1';
```

---

## 📝 Best Practices

### 1. **Sempre Use Funções para Operações Críticas**

```sql
-- ❌ NÃO faça assim:
INSERT INTO client_subscriptions (...) VALUES (...);

-- ✅ FAÇA assim:
SELECT create_subscription_from_template(...);
```

### 2. **Preserve o template_snapshot**

O campo `template_snapshot` garante que mudanças no template não afetam assinaturas antigas. NUNCA edite manualmente.

### 3. **Use custom_limits para Exceções**

```sql
-- ✅ BOM: Override para cliente específico
UPDATE client_subscriptions SET custom_limits = '{"messages_per_month": 20000}'::jsonb ...

-- ❌ RUIM: Mudar o template inteiro
UPDATE agent_templates SET usage_limits = ... -- Afeta TODOS os clientes
```

### 4. **Metadata é Seu Amigo**

Use campos `metadata` e `*_metadata` para armazenar QUALQUER informação sem precisar de migrations:

```sql
UPDATE agent_templates 
SET metadata = metadata || '{
  "color": "#FF6B6B",
  "icon": "chart-line",
  "recommended_for": ["B2B", "SaaS", "Consultoria"],
  "video_tutorial_url": "https://..."
}'::jsonb
WHERE template_id = 'sdr-pro';
```

---

## 🎓 Casos de Uso Reais

### Cenário 1: Black Friday (50% OFF por 3 meses)

```sql
-- Criar promoção
UPDATE agent_templates 
SET metadata = metadata || '{
  "promo_active": true,
  "promo_name": "Black Friday 2025",
  "promo_discount": 50,
  "promo_duration_months": 3
}'::jsonb
WHERE template_id IN ('sdr-starter', 'sdr-pro');

-- Aplicar desconto nas novas assinaturas
-- (fazer isso no código da aplicação ao criar subscription)
```

### Cenário 2: Migrar Cliente de Plano

```sql
-- Cancelar assinatura antiga
SELECT cancel_subscription(
  (SELECT id FROM client_subscriptions 
   WHERE client_id = 'cliente_001' AND agent_id = 'sdr-1'),
  'Upgrade para SDR Pro'
);

-- Criar nova assinatura (sem trial, direto ativo)
SELECT create_subscription_from_template(
  'cliente_001',
  'sdr-1',
  'sdr-pro',
  0  -- 0 dias de trial = ativa imediatamente
);
```

### Cenário 3: Cliente Corporativo (Negociação Custom)

```sql
-- Criar assinatura com tudo customizado
INSERT INTO client_subscriptions (
  client_id, agent_id, template_id, template_snapshot,
  status, monthly_price, billing_cycle,
  discount_percentage, discount_reason,
  custom_limits, custom_features,
  support_tier, account_manager_id
) VALUES (
  'empresa_grande_001',
  'sdr-enterprise',
  'sdr-pro',
  (SELECT row_to_json(t)::jsonb FROM agent_templates t WHERE template_id = 'sdr-pro'),
  'active',
  3997.00,  -- Preço negociado
  'annual',
  30,  -- 30% de desconto
  'Contrato Enterprise - 3 anos',
  '{"messages_per_month": 50000, "transcription_minutes": 1000}'::jsonb,
  ARRAY['linkedin', 'salesforce', 'hubspot', 'custom_api'],
  'premium',
  'joao.silva'
);
```

---

## 🔗 Próximos Passos

1. **Integração com Stripe/Mercado Pago**: Automatizar billing
2. **Webhooks**: Notificar sistema quando trial expirar
3. **Dashboard Analytics**: Visualizar métricas em tempo real
4. **Automações**: Emails de lembrete de trial, ofertas de upgrade, etc.

---

**Dúvidas?** Consulte `ARCHITECTURE.md` para entender o design do sistema.

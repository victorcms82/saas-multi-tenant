# 📘 GUIA DE EXECUÇÃO DAS MIGRATIONS 011 e 012

## ✅ MÉTODO RECOMENDADO: Supabase Dashboard (SQL Editor)

### **PASSO 1: Abrir SQL Editor**

1. Acessar: https://vnlfgnfaortdvmraoapq.supabase.co
2. Login com suas credenciais
3. Menu lateral → **SQL Editor**
4. Clicar em **"New query"**

---

### **PASSO 2: Executar Migration 011 (Locations)**

**Copiar e colar o conteúdo COMPLETO de:**
```
database/migrations/011_create_locations_table.sql
```

**O que será criado:**
- ✅ Tabela `locations` (localizações físicas)
- ✅ 8 índices para performance
- ✅ Trigger `update_locations_updated_at`
- ✅ Cliente de teste: `estetica_bella_rede`
- ✅ 4 localizações:
  - Bella Barra (5 profissionais)
  - Bella Ipanema (8 profissionais)
  - Bella Copacabana (3 profissionais)
  - Bella Botafogo (6 profissionais)

**Clicar em: RUN (Ctrl+Enter)**

**Validação esperada:**
```sql
-- Query automática ao final do arquivo:
SELECT 
  location_id,
  name,
  city,
  location_type,
  is_active,
  is_primary
FROM locations
WHERE client_id = 'estetica_bella_rede'
ORDER BY is_primary DESC, name;

-- Deve retornar 4 linhas
```

---

### **PASSO 3: Executar Migration 012 (Staff)**

**Copiar e colar o conteúdo COMPLETO de:**
```
database/migrations/012_create_staff_table.sql
```

**O que será criado:**
- ✅ Tabela `staff` (profissionais/equipe)
- ✅ 8 índices + 2 índices GIN (JSONB)
- ✅ Trigger `update_staff_updated_at`
- ✅ 14 profissionais de exemplo:
  - 5 em Bella Barra (Ana, Beatriz, Carlos, Diana, Eduardo)
  - 3 em Bella Ipanema (Fernanda, Gabriel, Helena)
  - 3 em Bella Copacabana (Isabela, João, Kátia)
  - 3 em Bella Botafogo (Laura, Marcos, Natália)

**Clicar em: RUN (Ctrl+Enter)**

**Validação esperada:**
```sql
-- Query automática ao final do arquivo:
SELECT 
  l.name as location_name,
  COUNT(s.staff_id) as total_staff,
  COUNT(s.staff_id) FILTER (WHERE s.is_available_online = TRUE) as available_online,
  COUNT(s.staff_id) FILTER (WHERE s.role = 'aesthetic_specialist') as specialists,
  COUNT(s.staff_id) FILTER (WHERE s.role = 'receptionist') as receptionists
FROM locations l
LEFT JOIN staff s ON s.location_id = l.location_id
WHERE l.client_id = 'estetica_bella_rede'
GROUP BY l.name, l.location_id
ORDER BY l.name;

-- Deve retornar 4 linhas com contagens corretas
```

---

## 🧪 QUERIES DE TESTE

Após executar ambas as migrations, rodar estas queries para validar:

### **Teste 1: Verificar estrutura criada**
```sql
-- Verificar tabelas
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('locations', 'staff');

-- Verificar índices
SELECT indexname 
FROM pg_indexes 
WHERE tablename IN ('locations', 'staff')
ORDER BY tablename, indexname;
```

### **Teste 2: Contagem de dados**
```sql
-- Total de localizações
SELECT COUNT(*) as total_locations FROM locations;
-- Esperado: 4

-- Total de profissionais
SELECT COUNT(*) as total_staff FROM staff;
-- Esperado: 14

-- Profissionais por localização
SELECT 
  l.name,
  COUNT(s.staff_id) as staff_count
FROM locations l
LEFT JOIN staff s ON s.location_id = l.location_id
GROUP BY l.name
ORDER BY l.name;
```

### **Teste 3: Especialidades disponíveis**
```sql
-- Especialidades mais comuns
SELECT 
  specialty,
  COUNT(*) as count
FROM staff
WHERE is_active = TRUE AND is_available_online = TRUE
GROUP BY specialty
ORDER BY count DESC;
```

### **Teste 4: Disponibilidade por dia da semana**
```sql
-- Profissionais disponíveis por dia
SELECT 
  unnest(available_days) as day_of_week,
  COUNT(*) as staff_available
FROM staff
WHERE is_available_online = TRUE
GROUP BY day_of_week
ORDER BY 
  CASE day_of_week
    WHEN 'monday' THEN 1
    WHEN 'tuesday' THEN 2
    WHEN 'wednesday' THEN 3
    WHEN 'thursday' THEN 4
    WHEN 'friday' THEN 5
    WHEN 'saturday' THEN 6
    WHEN 'sunday' THEN 7
  END;
```

### **Teste 5: Localização principal**
```sql
-- Verificar matriz/unidade principal
SELECT 
  name,
  display_name,
  city,
  phone,
  is_primary
FROM locations
WHERE is_primary = TRUE;
-- Esperado: Bella Barra
```

### **Teste 6: Profissionais featured (destaque)**
```sql
-- Profissionais em destaque
SELECT 
  s.name,
  s.specialty,
  l.name as location_name
FROM staff s
JOIN locations l ON l.location_id = s.location_id
WHERE s.is_featured = TRUE
ORDER BY l.name, s.name;
-- Esperado: Ana (Barra), Fernanda (Ipanema), Isabela (Copa), Laura (Botafogo)
```

---

## 🚨 TROUBLESHOOTING

### **Erro: "relation locations does not exist"**
**Solução:** Executar migration 011 antes de 012

### **Erro: "duplicate key value violates unique constraint"**
**Solução:** Dados de exemplo já existem. Comentar INSERTs ou mudar IDs

### **Erro: "permission denied for table"**
**Solução:** Usar service_role key (não anon key) no SQL Editor

### **Erro: "syntax error near 'JSONB'"**
**Solução:** Supabase usa PostgreSQL 15+. JSONB é suportado. Verificar sintaxe.

---

## 📋 CHECKLIST PÓS-MIGRATION

- [ ] Tabela `locations` criada
- [ ] Tabela `staff` criada
- [ ] 4 localizações inseridas
- [ ] 14 profissionais inseridos
- [ ] Índices criados (verificar com query acima)
- [ ] Triggers funcionando (testar UPDATE e verificar updated_at)
- [ ] Foreign keys OK (staff.location_id → locations.location_id)
- [ ] Queries de teste rodando sem erro

---

## 🚀 PRÓXIMOS PASSOS

Após validar as migrations:

1. **Criar RPCs para o workflow:**
   - `get_location_by_inbox(p_inbox_id)` - Detectar localização via Chatwoot inbox
   - `get_staff_by_location(p_location_id, p_service)` - Buscar profissionais

2. **Atualizar workflow n8n:**
   - Adicionar node "Detectar Localização (RPC)"
   - Adicionar node "Buscar Staff da Localização (RPC)"
   - Atualizar "Construir Contexto Completo" com dados de location/staff

3. **Expandir MCP_Calendar:**
   - Suportar array de `calendar_id[]`
   - Retornar disponibilidade agregada
   - Incluir nome do profissional nos slots disponíveis

4. **Testar multi-location:**
   - Criar inbox no Chatwoot para cada localização
   - Atualizar `chatwoot_inbox_id` na tabela `locations`
   - Testar: Mensagem → Detecta localização → Lista profissionais corretos

---

## 📚 REFERÊNCIAS

- **Supabase SQL Editor:** https://supabase.com/docs/guides/database/overview
- **PostgreSQL JSONB:** https://www.postgresql.org/docs/current/datatype-json.html
- **Array Types:** https://www.postgresql.org/docs/current/arrays.html
- **Constraints:** https://www.postgresql.org/docs/current/ddl-constraints.html

---

**✅ Migrations prontas para execução!** 🎉

# 🚨 EXECUTAR TODAS MIGRATIONS URGENTES

## ⚠️ ORDEM DE EXECUÇÃO CRÍTICA

Execute **EXATAMENTE** nesta ordem no Supabase SQL Editor:

---

## 1️⃣ FIX ENCODING + LOCATIONS (URGENTE)

**Arquivo:** `FIX-ENCODING-AND-LOCATIONS.sql`

**O que faz:**
- ✅ Corrige encoding dos prompts (Ã vira ç)
- ✅ Adiciona location da Clínica Sorriso (inbox_id=1)
- ✅ Corrige system_prompt dos 2 clientes

**Executar:**
```sql
-- Copiar TUDO do arquivo FIX-ENCODING-AND-LOCATIONS.sql
-- Colar no Supabase SQL Editor
-- Clicar RUN
```

**Verificação:**
- Deve mostrar 2 linhas em AGENTS (✅ OK)
- Deve mostrar 2 linhas em LOCATIONS (✅ INBOX: 1 e ✅ INBOX: 2)

---

## 2️⃣ MIGRATION 015 - BLINDAGEM MÍDIA

**Arquivo:** `migrations/015_blindagem_total_media.sql`

**O que faz:**
- 🔒 RPC check_media_triggers blindada (filtro duplo client_id)
- 🔒 Constraint de integridade
- 🔒 Trigger preventivo
- 🔒 Row Level Security
- 🔒 Função de auditoria

**Executar:**
```sql
-- Copiar TUDO do arquivo 015_blindagem_total_media.sql
-- Colar no Supabase SQL Editor
-- Clicar RUN
```

**Verificação Esperada:**
```
✅ Teste 1: Cliente COM mídia → Retorna 1 linha (Clínica Sorriso)
✅ Teste 2: Cliente SEM mídia → Retorna 0 linhas (vazio)
✅ Teste 3: Bella SEM mídia → Retorna 0 linhas (NUNCA Clínica Sorriso!)
✅ Integridade OK! Nenhum vazamento cross-tenant detectado.
```

---

## 3️⃣ MIGRATION 016 - ISOLAMENTO TOTAL

**Arquivo:** `migrations/016_isolamento_total_multi_tenant.sql`

**O que faz:**
- 🔒 RLS em TODAS as tabelas (clients, agents, locations, professionals, media, memory)
- 🔒 Policies de isolamento por client_id
- 🔒 Todas as RPCs validam client_id obrigatório
- 🔒 Constraints NOT NULL
- 🔒 Trigger universal de validação
- 🔒 Auditoria total

**Executar:**
```sql
-- Copiar TUDO do arquivo 016_isolamento_total_multi_tenant.sql
-- Colar no Supabase SQL Editor
-- Clicar RUN
```

**Verificação Esperada:**
```
✅ ISOLAMENTO PERFEITO! Nenhum vazamento detectado.
✅ RLS POLICIES → Lista 7+ policies criadas
✅ NOT NULL CONSTRAINTS → client_id obrigatório em 6 tabelas
```

---

## 4️⃣ INSERT BELLA MEDIA (DADOS)

**Arquivo:** `INSERT-BELLA-MEDIA.sql`

**⚠️ IMPORTANTE:** Antes de executar, você precisa:

### 📤 Upload de Arquivos (OBRIGATÓRIO)

**Ir para:** Supabase → Storage → bucket `client-media`

**Criar pasta:** `estetica_bella_rede`

**Upload 5 arquivos:**
1. `bella-recepcao-barra.jpg` (foto da recepção)
2. `bella-sala-tratamento.jpg` (foto da sala)
3. `bella-equipe-completa.jpg` (foto da equipe)
4. `bella-tabela-servicos.pdf` (tabela de preços)
5. `bella-resultados-harmonizacao.jpg` (antes/depois)

**Se não tiver as imagens reais:**
- Opção A: Use imagens temporárias de stock photos
- Opção B: Renomeie imagens da Clínica Sorriso (temporário)
- Opção C: Crie imagem "Em Breve" placeholder

### 📝 Executar SQL

**Depois do upload:**
```sql
-- Copiar TUDO do arquivo INSERT-BELLA-MEDIA.sql
-- Colar no Supabase SQL Editor
-- Clicar RUN
```

**Verificação:**
```sql
-- Deve retornar 5 linhas
SELECT * FROM client_media WHERE client_id = 'estetica_bella_rede';

-- Deve retornar 4 linhas
SELECT * FROM client_media_rules WHERE client_id = 'estetica_bella_rede';
```

---

## 5️⃣ TESTAR NO WHATSAPP 📱

### Teste 1: Clínica Sorriso
**Enviar:** "quero ver a clínica"
**Esperado:** 
- ✅ Imagem: consultorio-recepcao.jpg
- ✅ Texto: "Av. Principal, 123 - Centro"
- ✅ Nome: Dr. João Silva

### Teste 2: Bella Estética
**Enviar:** "quero ver a clínica"
**Esperado:**
- ✅ Imagem: bella-recepcao-barra.jpg
- ✅ Texto: "Av. das Américas, 5000 - Sala 301"
- ✅ Nome: Dra. Ana Paula Silva

### Teste 3: Cross-Tenant (CRÍTICO)
**Bella recebe mensagem da Clínica Sorriso?** ❌ NUNCA
**Clínica recebe dados da Bella?** ❌ NUNCA

---

## 📊 CHECKLIST FINAL

Execute e marque ✅:

- [ ] 1. FIX-ENCODING-AND-LOCATIONS.sql executado
- [ ] 2. Verificação: 2 agents + 2 locations OK
- [ ] 3. Migration 015 executada
- [ ] 4. Verificação: 3 testes de mídia OK
- [ ] 5. Migration 016 executada
- [ ] 6. Verificação: Isolamento perfeito
- [ ] 7. Upload de 5 arquivos Bella no Storage
- [ ] 8. INSERT-BELLA-MEDIA.sql executado
- [ ] 9. Verificação: 5 media + 4 rules OK
- [ ] 10. Teste WhatsApp Clínica Sorriso OK
- [ ] 11. Teste WhatsApp Bella Estética OK
- [ ] 12. Teste cross-tenant: NENHUM vazamento

---

## 🔍 AUDITORIA DE SEGURANÇA

**Após tudo executado, rodar:**

```sql
-- Verificar integridade total
SELECT * FROM validate_tenant_isolation();
```

**Resultado esperado:**
```
(0 rows) ← PERFEITO! Nenhum problema detectado
```

**Se retornar linhas:** Há problemas de isolamento, avisar IMEDIATAMENTE!

---

## ⚡ EXECUÇÃO RÁPIDA (COPIAR/COLAR)

### Supabase SQL Editor → New Query

**Query 1: FIX + 015 + 016 (pode executar junto)**
```sql
-- 1. Copiar TODO conteúdo de FIX-ENCODING-AND-LOCATIONS.sql
-- 2. Adicionar separador
-- ============================================================================

-- 3. Copiar TODO conteúdo de 015_blindagem_total_media.sql
-- 4. Adicionar separador
-- ============================================================================

-- 5. Copiar TODO conteúdo de 016_isolamento_total_multi_tenant.sql

-- 6. Executar TUDO de uma vez (RUN)
```

**Query 2: INSERT BELLA (só depois do upload)**
```sql
-- Copiar TODO conteúdo de INSERT-BELLA-MEDIA.sql
-- Executar (RUN)
```

---

## 🆘 TROUBLESHOOTING

### Erro: "client_id não pode ser vazio"
**Solução:** 🎉 Está funcionando! É a segurança impedindo dados sem client_id

### Erro: "constraint check_client_id_consistency"
**Solução:** Tentou criar regra com mídia de outro cliente (BLOQUEADO!)

### Teste retorna mídia errada
**Solução:** 
1. Executar `SELECT * FROM validate_tenant_isolation();`
2. Verificar problemas retornados
3. Executar FLUSHDB no Redis (limpar cache)

### Bella retorna vazio mas deveria retornar mídia
**Solução:**
1. Verificar se arquivos foram uploaded: `SELECT * FROM client_media WHERE client_id = 'estetica_bella_rede';`
2. Se vazio: Executar INSERT-BELLA-MEDIA.sql novamente
3. Se tem dados: Verificar triggers: `SELECT * FROM client_media_rules WHERE client_id = 'estetica_bella_rede';`

---

## 🎯 RESULTADO FINAL ESPERADO

✅ **Encoding correto** nos system_prompts  
✅ **Locations configuradas** com inbox_id  
✅ **RLS ativo** em 7+ tabelas  
✅ **Constraints** impedindo client_id NULL  
✅ **Triggers** validando integridade  
✅ **Bella Estética** com 5 mídias cadastradas  
✅ **Zero cross-tenant leakage**  
✅ **Testes WhatsApp** funcionando  

---

## 📝 APÓS SUCESSO

**Commitar tudo:**
```powershell
git add database/
git commit -m "feat: blindagem total multi-tenant + fix encoding + bella media"
git push origin main
```

**Documentar:**
- Atualizar STATUS.md
- Marcar GAPS.md como resolvido
- Adicionar nota em CHANGELOG.md

---

## ⏱️ TEMPO ESTIMADO

- **Execução SQL:** 5 minutos
- **Upload Bella:** 10 minutos
- **Testes WhatsApp:** 10 minutos
- **TOTAL:** ~25 minutos

---

## 🔒 GARANTIAS DE SEGURANÇA

Após execução completa:

1. ✅ **Impossível** cliente ver dados de outro
2. ✅ **Impossível** inserir dados sem client_id
3. ✅ **Impossível** criar regra com mídia de outro cliente
4. ✅ **Impossível** RPC retornar dados cruzados
5. ✅ **Auditoria automática** detecta qualquer problema

**Arquitetura Multi-Tenant Nível Enterprise! 🚀**

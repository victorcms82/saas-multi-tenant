# 🚀 EXECUTAR MIGRATIONS MANUALMENTE (MÉTODO MAIS RÁPIDO)

## Por que manual?
A API REST do Supabase não permite executar SQL arbitrário por segurança.
**Mas é super rápido! Leva 2 minutos! ⚡**

---

## 📋 PASSO A PASSO

### 1. Abrir Supabase SQL Editor
🌐 Acesse: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql/new

---

### 2. EXECUTAR MIGRATION 1: FIX ENCODING + LOCATIONS

**Copiar:** Todo conteúdo de `database/FIX-ENCODING-AND-LOCATIONS.sql`

**Colar** no SQL Editor

**Clicar:** RUN (ou Ctrl+Enter)

**Verificar:** Deve mostrar tabela com 4 linhas (2 agents + 2 locations)

✅ **Status esperado:**
```
✅ OK - clinica_sorriso_001 agent
✅ OK - estetica_bella_rede agent  
✅ INBOX: 1 - clinica_sorriso_001 location
✅ INBOX: 2 - estetica_bella_rede location
```

---

### 3. EXECUTAR MIGRATION 2: BLINDAGEM MÍDIA

**Copiar:** Todo conteúdo de `database/migrations/015_blindagem_total_media.sql`

**Colar** no SQL Editor (pode apagar conteúdo anterior)

**Clicar:** RUN

**Verificar:** Deve mostrar:
```
✅ Teste 1: Cliente COM mídia → 1 linha
✅ Teste 2: Cliente SEM mídia → 0 linhas
✅ Teste 3: Bella SEM mídia → 0 linhas
✅ Integridade OK! Nenhum vazamento detectado.
```

---

### 4. EXECUTAR MIGRATION 3: ISOLAMENTO TOTAL

**Copiar:** Todo conteúdo de `database/migrations/016_isolamento_total_multi_tenant.sql`

**Colar** no SQL Editor

**Clicar:** RUN

**Verificar:** Deve mostrar:
```
✅ ISOLAMENTO PERFEITO! Nenhum vazamento detectado.
(tabela com policies criadas)
(tabela com constraints NOT NULL)
```

---

### 5. INSERIR DADOS BELLA (DEPOIS DE UPLOAD)

⚠️ **ANTES:** Upload 5 arquivos no Storage (bella-recepcao-barra.jpg, etc.)

**Copiar:** Todo conteúdo de `database/INSERT-BELLA-MEDIA.sql`

**Colar** no SQL Editor

**Clicar:** RUN

**Verificar:**
```sql
-- Deve retornar 5 linhas
SELECT * FROM client_media WHERE client_id = 'estetica_bella_rede';

-- Deve retornar 4 linhas
SELECT * FROM client_media_rules WHERE client_id = 'estetica_bella_rede';
```

---

## ⏱️ TEMPO TOTAL: ~5 minutos

1. Migration 1: 30s
2. Migration 2: 1min
3. Migration 3: 2min
4. Insert Bella: 30s
5. Verificação: 1min

---

## 🎯 DEPOIS DE TUDO

Testar no WhatsApp:
- Clínica Sorriso: "quero ver a clínica"
- Bella Estética: "quero ver a clínica"

Cada um deve receber suas próprias imagens! 🎉

---

## 🆘 SE DER ERRO

**Erro: "already exists"**
→ Normal! Significa que já rodou antes. Pode ignorar.

**Erro: "does not exist"**  
→ Verificar se migration anterior rodou OK.

**Erro: "permission denied"**
→ Verificar se está usando service_role key.

---

## 💡 DICA PRO

Pode executar TUDO de uma vez:

1. Copiar migration 1
2. Adicionar quebra: `-- =============================`
3. Copiar migration 2
4. Adicionar quebra
5. Copiar migration 3
6. Colar TUDO junto
7. RUN uma vez só!

**Tempo:** 1 minuto! ⚡⚡⚡

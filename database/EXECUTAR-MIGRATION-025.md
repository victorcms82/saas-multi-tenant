# 🔧 EXECUTAR MIGRATION 025 - Fix Dashboard Users RLS Login

## ❌ Problema Identificado

**Erro no login:** "Database error querying schema"

**Causa raiz:**
- Durante login, `auth.uid()` ainda **não existe** (usuário não autenticado)
- Policy antiga: `id = auth.uid()` bloqueava SELECT
- Resultado: Supabase não consegue buscar perfil em `dashboard_users`

---

## ✅ Solução Aplicada

**Nova policy permite SELECT usando:**
1. `auth.email()` - disponível durante login (vem do JWT)
2. `auth.uid()` - disponível após login completo

Ambos vêm do JWT assinado pelo Supabase (seguro, não pode ser falsificado).

---

## 🚀 Método 1: Script PowerShell (RECOMENDADO)

```powershell
# 1. Configurar service role key
$env:SUPABASE_SERVICE_ROLE_KEY = "sua-service-role-key-aqui"

# 2. Executar script
.\run-migration-025.ps1
```

**Onde encontrar a Service Role Key:**
1. Acesse: https://vnlfgnfaortdvmraoapq.supabase.co
2. Settings → API → Project API keys
3. Copie: `service_role` (secret, não compartilhe!)

---

## 🛠️ Método 2: Execução Manual no Supabase (SE SCRIPT FALHAR)

### Passo 1: Acessar SQL Editor
1. Acesse: https://vnlfgnfaortdvmraoapq.supabase.co
2. Clique em: **SQL Editor** (menu lateral esquerdo)
3. Clique em: **New Query**

### Passo 2: Colar SQL da Migration
Copie TODO o conteúdo do arquivo:
```
database/migrations/025_fix_dashboard_users_rls_login.sql
```

### Passo 3: Executar
1. Cole o SQL no editor
2. Clique em: **Run** (ou F5)
3. Aguarde mensagem de sucesso ✅

### Passo 4: Validar Policies
Execute esta query para confirmar:

```sql
SELECT 
  policyname,
  cmd,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'dashboard_users'
ORDER BY policyname;
```

**Resultado esperado:**
| policyname | cmd | using_expression |
|------------|-----|------------------|
| dashboard_users_select_policy | SELECT | ((id = auth.uid()) OR (email = auth.email())) |
| dashboard_users_update_policy | UPDATE | (id = auth.uid()) |
| dashboard_users_insert_policy | INSERT | (id = auth.uid()) |

---

## 🧪 Testar Login Após Migration

### No Lovable Dashboard:

1. **Acesse a página de login**

2. **Credenciais de teste:**
   - Email: `teste@evolutedigital.com.br`
   - Senha: `Teste@2024!`

3. **Resultado esperado:**
   - ✅ Login bem-sucedido
   - ✅ Dashboard carrega
   - ✅ Sem erro "Database error querying schema"

---

## 📋 O Que a Migration Faz

### 1. Remove policies antigas
```sql
DROP POLICY "Users can view own profile" ON dashboard_users;
DROP POLICY "Users can update own profile" ON dashboard_users;
```

### 2. Cria nova policy de SELECT
```sql
CREATE POLICY "dashboard_users_select_policy"
  ON dashboard_users FOR SELECT
  USING (
    id = auth.uid()      -- Após login
    OR
    email = auth.email() -- Durante login
  );
```

### 3. Cria policy de UPDATE (apenas próprio perfil)
```sql
CREATE POLICY "dashboard_users_update_policy"
  ON dashboard_users FOR UPDATE
  USING (id = auth.uid());
```

### 4. Cria policy de INSERT (sign up)
```sql
CREATE POLICY "dashboard_users_insert_policy"
  ON dashboard_users FOR INSERT
  WITH CHECK (id = auth.uid());
```

---

## 💡 Explicação Técnica

### Fluxo de Login

```
1. Usuário envia email/senha
   ↓
2. Supabase Auth valida em auth.users
   ↓
3. Supabase Auth gera JWT com:
   - auth.email() ✅ (disponível DURANTE login)
   - auth.uid() ✅ (disponível APÓS login)
   ↓
4. Frontend tenta buscar perfil em dashboard_users
   ↓
5. RLS permite SELECT usando:
   - auth.email() (durante login) ✅
   - auth.uid() (após login) ✅
   ↓
6. Login completo! ✅
```

### Segurança

- ✅ `auth.email()` vem do JWT assinado pelo Supabase (não pode ser falsificado)
- ✅ `auth.uid()` vem do JWT assinado pelo Supabase (não pode ser falsificado)
- ✅ Usuário só vê seu próprio perfil (email ou id)
- ✅ Não há vazamento entre clientes (multi-tenancy preservado)

---

## 🔍 Troubleshooting

### Erro: "Policy already exists"
**Solução:** A migration é idempotente, dropa policies antes de criar.

### Erro: "Permission denied"
**Solução:** Use a **service_role key**, não a anon key.

### Erro: "exec_sql function not found"
**Solução:** Execute manualmente no SQL Editor (Método 2).

### Login ainda não funciona
**Checklist:**
1. ✅ Migration 025 executada?
2. ✅ Policies criadas? (validar com query acima)
3. ✅ RLS habilitado? `SELECT * FROM pg_tables WHERE tablename = 'dashboard_users';`
4. ✅ Usuário teste existe? `SELECT * FROM auth.users WHERE email = 'teste@evolutedigital.com.br';`

---

## 📞 Suporte

Se o problema persistir:
1. Compartilhe o erro exato do console do navegador (F12)
2. Execute query de validação e compartilhe resultado
3. Verifique logs do Supabase: Settings → Logs → API Logs

---

## ✅ Checklist Final

- [ ] Migration 025 executada com sucesso
- [ ] Policies validadas (3 policies criadas)
- [ ] Login testado com `teste@evolutedigital.com.br`
- [ ] Dashboard carrega sem erros
- [ ] Pronto para Prompt 4 do Lovable! 🚀

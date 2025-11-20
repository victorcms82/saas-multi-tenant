# 🔧 SOLUÇÃO DEFINITIVA - Login Error "Database error querying schema"

## 🎯 Problema Real Identificado

O erro persiste porque o código tenta buscar `dashboard_users`, mas:
1. ❌ Usuário não existe em `dashboard_users` OU
2. ❌ Query falha por outro motivo

---

## ✅ SOLUÇÃO COMPLETA EM 3 PASSOS

### PASSO 1: Verificar se Usuário Existe

Execute no **Supabase SQL Editor**:

```sql
-- Arquivo: database/queries/verify-test-user.sql

SELECT 
  '🔍 AUTH.USERS' as tipo,
  id, email, created_at
FROM auth.users
WHERE email = 'teste@evolutedigital.com.br';

SELECT 
  '🔍 DASHBOARD_USERS' as tipo,
  id, email, full_name, client_id
FROM dashboard_users
WHERE email = 'teste@evolutedigital.com.br';
```

---

### PASSO 2A: Se Usuário NÃO Existe em auth.users

**Criar usuário via Supabase Dashboard:**

1. Acesse: https://vnlfgnfaortdvmraoapq.supabase.co
2. **Authentication → Users → Invite User**
3. Preencha:
   - **Email:** teste@evolutedigital.com.br
   - **Password:** Teste@2024!
   - **Auto Confirm User:** ✅ YES (importante!)
4. Clique em **Invite**

---

### PASSO 2B: Se Usuário Existe em auth.users mas NÃO em dashboard_users

Execute no **Supabase SQL Editor**:

```sql
-- Arquivo: database/queries/create-test-user.sql
-- Cole TODO o conteúdo do arquivo gerado
```

Ou manualmente:

```sql
-- Pegar o ID do usuário
SELECT id FROM auth.users WHERE email = 'teste@evolutedigital.com.br';

-- Inserir em dashboard_users (substitua USER_ID_AQUI pelo ID retornado)
INSERT INTO dashboard_users (
  id,
  client_id,
  full_name,
  email,
  phone,
  role,
  is_active
) VALUES (
  'USER_ID_AQUI',  -- Cole o ID do auth.users aqui
  'clinica_sorriso_001',
  'Usuário Teste',
  'teste@evolutedigital.com.br',
  '+5511999999999',
  'admin',
  true
);
```

---

### PASSO 3: Atualizar Código de Login no Lovable

Cole este prompt **COMPLETO** no Lovable:

```
Atualizar handleLogin para NÃO falhar se dashboard_users não retornar perfil.

O login deve funcionar APENAS com Supabase Auth, sem depender de dashboard_users.

Código correto:

const handleLogin = async (e: React.FormEvent) => {
  e.preventDefault()
  setLoading(true)
  setError('')
  
  try {
    // 1. Autenticar com Supabase Auth (ÚNICO requisito obrigatório)
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    })
    
    if (authError) throw authError
    if (!authData.session) throw new Error('Falha ao criar sessão')
    
    // 2. Tentar buscar perfil (OPCIONAL - não bloqueia login se falhar)
    try {
      const { data: profile, error: profileError } = await supabase
        .from('dashboard_users')
        .select('*')
        .eq('id', authData.user.id)
        .single()
      
      if (profileError) {
        console.warn('Perfil não encontrado em dashboard_users:', profileError.message)
      } else {
        console.log('Perfil carregado:', profile)
        // Opcional: salvar perfil no estado/contexto
      }
    } catch (profileErr) {
      console.warn('Erro ao buscar perfil (não crítico):', profileErr)
    }
    
    // 3. Redirecionar SEMPRE (login bem-sucedido)
    router.push('/')
    
  } catch (err: any) {
    console.error('Erro no login:', err)
    setError(err.message || 'Erro ao fazer login. Verifique suas credenciais.')
  } finally {
    setLoading(false)
  }
}

Importante:
- Login depende APENAS de supabase.auth.signInWithPassword()
- Busca de dashboard_users é OPCIONAL (não bloqueia)
- Redireciona para / se auth bem-sucedido
- Não lançar erro se dashboard_users falhar
```

---

## 🧪 Testar Login Após Correção

### Cenário 1: Usuário Existe em Ambas Tabelas
- ✅ Login bem-sucedido
- ✅ Perfil carregado
- ✅ Redireciona para dashboard

### Cenário 2: Usuário Existe Apenas em auth.users
- ✅ Login bem-sucedido
- ⚠️ Warning no console: "Perfil não encontrado"
- ✅ Redireciona para dashboard
- 📝 Dashboard pode mostrar mensagem: "Complete seu perfil"

### Cenário 3: Usuário Não Existe
- ❌ Erro: "Invalid login credentials"
- 🔧 Solução: Criar usuário (Passo 2A)

---

## 🔍 Troubleshooting

### Erro: "Invalid login credentials"
**Causa:** Usuário não existe em `auth.users`  
**Solução:** Criar via Supabase Dashboard (Passo 2A)

### Erro: "Database error querying schema" (ainda)
**Causa:** RLS bloqueando mesmo com policy correta  
**Solução:** Tornar busca de `dashboard_users` opcional (Passo 3)

### Login funciona mas dashboard vazio
**Causa:** Usuário não existe em `dashboard_users`  
**Solução:** Inserir registro (Passo 2B)

### Email confirmado?
Verifique no Supabase:
```sql
SELECT email, email_confirmed_at 
FROM auth.users 
WHERE email = 'teste@evolutedigital.com.br';
```

Se `email_confirmed_at` é NULL:
```sql
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'teste@evolutedigital.com.br';
```

---

## 📋 Checklist Final

- [ ] Usuário existe em `auth.users` (verificado via SQL)
- [ ] Email confirmado (`email_confirmed_at` não é NULL)
- [ ] Usuário existe em `dashboard_users` (ou login não depende disso)
- [ ] Código de login atualizado no Lovable (busca opcional)
- [ ] Testado login com teste@evolutedigital.com.br
- [ ] Login bem-sucedido e redireciona para dashboard

---

## 💡 Por Que Esta Solução Funciona?

### Antes (código quebrado):
```typescript
// ❌ Login DEPENDIA de dashboard_users
const { data: profile } = await supabase.from('dashboard_users')...
if (!profile) throw new Error('Perfil não encontrado')  // BLOQUEIA login
```

### Agora (código correto):
```typescript
// ✅ Login depende APENAS de auth
const { data: authData } = await supabase.auth.signInWithPassword(...)
if (authError) throw authError  // Único bloqueio

// ✅ Busca perfil é OPCIONAL
try {
  const { data: profile } = await supabase.from('dashboard_users')...
  // Não bloqueia se falhar
} catch { }
```

---

## 🚀 Próximos Passos Após Login Funcionar

1. ✅ Login funcionando
2. ✅ Dashboard carrega
3. ⏭️ Implementar Prompts 2, 3 e 4 do Lovable
4. 🎉 Sistema completo!

---

**Execute os passos 1, 2 e 3 nessa ordem e o login vai funcionar!** 🎯

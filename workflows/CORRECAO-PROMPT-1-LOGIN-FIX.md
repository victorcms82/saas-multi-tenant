# 🔧 CORREÇÃO CRÍTICA - Prompt 1: Fix Login Error

## ❌ Problema Identificado

Erro no login: **"Database error querying schema"**

**Causa:** O código gerado pelo Lovable está tentando buscar dados de `dashboard_users` durante o fluxo de login, mas o Supabase Auth precisa completar primeiro.

---

## ✅ Solução: Adicionar ao Final do Prompt 1

Cole este trecho **NO FINAL** do Prompt 1 (após a seção de Login):

```markdown
---

## ⚠️ CORREÇÃO CRÍTICA: Fluxo de Login

### Problema Identificado
O login pode falhar com erro "Database error querying schema" se tentar buscar `dashboard_users` antes do auth completar.

### Solução: Login em 2 Etapas

**Passo 1:** Autenticar com Supabase Auth
```typescript
const handleLogin = async (e: React.FormEvent) => {
  e.preventDefault()
  setLoading(true)
  setError('')
  
  try {
    // 1. Autenticar usuário (apenas email/senha)
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    })
    
    if (authError) throw authError
    
    // 2. Aguardar sessão ser estabelecida
    if (!authData.session) {
      throw new Error('Sessão não criada')
    }
    
    // 3. Buscar perfil do usuário (APÓS login completar)
    const { data: profile, error: profileError } = await supabase
      .from('dashboard_users')
      .select('*')
      .eq('id', authData.user.id)
      .single()
    
    if (profileError) {
      console.error('Erro ao buscar perfil:', profileError)
      // Não bloquear login se perfil não existir
    }
    
    // 4. Salvar perfil no contexto/estado se necessário
    if (profile) {
      // Opcional: armazenar no localStorage ou contexto
      console.log('Perfil carregado:', profile)
    }
    
    // 5. Redirecionar para dashboard
    router.push('/')
    
  } catch (err: any) {
    console.error('Erro no login:', err)
    setError(err.message || 'Erro ao fazer login. Verifique suas credenciais.')
  } finally {
    setLoading(false)
  }
}
```

### Componente ProtectedRoute (para rotas autenticadas)

Criar componente para proteger rotas que precisam de autenticação:

```typescript
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '@/lib/supabase'

export const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const router = useRouter()
  const [loading, setLoading] = useState(true)
  const [authenticated, setAuthenticated] = useState(false)

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      
      if (!session) {
        router.push('/login')
        return
      }
      
      setAuthenticated(true)
    } catch (error) {
      console.error('Erro ao verificar autenticação:', error)
      router.push('/login')
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    )
  }

  if (!authenticated) {
    return null
  }

  return <>{children}</>
}
```

### Uso no Dashboard

```typescript
// Na página Dashboard (index.tsx)
import { ProtectedRoute } from '@/components/ProtectedRoute'

export default function Dashboard() {
  return (
    <ProtectedRoute>
      <div className="flex h-screen">
        <Sidebar />
        <div className="flex-1">
          <Header />
          {/* Conteúdo do dashboard */}
        </div>
      </div>
    </ProtectedRoute>
  )
}
```

### Checklist de Correção

- [ ] Login faz auth ANTES de buscar dashboard_users
- [ ] Aguarda sessão ser estabelecida (authData.session)
- [ ] Busca perfil APÓS auth completar (usando authData.user.id)
- [ ] Não bloqueia login se perfil não existir (apenas log)
- [ ] ProtectedRoute valida sessão em rotas protegidas
- [ ] Loading state durante verificação de auth

### Credenciais de Teste

- **Email:** teste@evolutedigital.com.br
- **Senha:** Teste@2024!
- **Client ID:** clinica_sorriso_001

### Notas de Segurança

1. ✅ Sempre use `auth.getSession()` para verificar autenticação
2. ✅ Nunca confie apenas no localStorage
3. ✅ RLS do Supabase protege queries em dashboard_users
4. ✅ Policy permite SELECT usando auth.uid() (após login) ou auth.email() (durante login)
```

---

## 🎯 Como Aplicar no Lovable

### Opção A: Adicionar ao Prompt 1 e Re-executar

1. Abra: `LOVABLE-PROMPT-1-AUTH-LAYOUT.md`
2. Cole a seção "CORREÇÃO CRÍTICA" no final
3. No Lovable, cole o Prompt 1 COMPLETO (com correção)
4. Lovable vai atualizar o código de login

### Opção B: Pedir Correção Específica ao Lovable

Cole este prompt no Lovable:

```
Preciso corrigir o fluxo de login. Atualmente está dando erro "Database error querying schema".

O problema é que o código está tentando buscar dashboard_users ANTES do login completar.

Por favor, atualizar o handleLogin para:
1. Fazer signInWithPassword PRIMEIRO
2. Aguardar authData.session ser criada
3. DEPOIS buscar perfil em dashboard_users usando authData.user.id
4. Não bloquear login se perfil não existir (apenas log)

Código correto:

[Cole o código da função handleLogin acima]
```

---

## 🧪 Testar Após Correção

1. Acesse página de login
2. Use: teste@evolutedigital.com.br / Teste@2024!
3. Login deve funcionar ✅
4. Dashboard deve carregar ✅

---

## 💡 Por Que Isso Funciona?

### Fluxo Correto:
```
1. User envia email/senha
   ↓
2. supabase.auth.signInWithPassword() cria JWT
   ↓
3. JWT contém auth.uid() e auth.email()
   ↓
4. Buscar dashboard_users usando auth.uid() (agora disponível)
   ↓
5. RLS permite SELECT (policy usa auth.uid())
   ↓
6. Login completo! ✅
```

### Fluxo Errado (causa o erro):
```
1. User envia email/senha
   ↓
2. Tentar buscar dashboard_users ANTES do auth
   ↓
3. auth.uid() = NULL (ainda não autenticado)
   ↓
4. RLS bloqueia (policy precisa de auth.uid() ou auth.email())
   ↓
5. Erro: "Database error querying schema" ❌
```

---

## 📋 Resumo

- ❌ **Não precisa do Prompt 4** para fazer login
- ✅ **Precisa corrigir o Prompt 1** para login em 2 etapas
- ✅ **Migration 025 já está OK** (policies corretas)
- ✅ **Aplicar correção no Lovable** (re-executar Prompt 1 ou pedir correção)

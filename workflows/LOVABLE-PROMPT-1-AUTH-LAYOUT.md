# Prompt 1: Autenticação e Layout Base - Dashboard Digitai.app

## 🎯 Objetivo
Criar a estrutura base do dashboard com autenticação Supabase, layout responsivo, sidebar, header e página de login.

---

## 📋 Contexto do Projeto

**Database já configurado no Supabase:**
- URL: `https://vnlfgnfaortdvmraoapq.supabase.co`
- Anon Key: [Pegar em: Settings → API → Project API keys → `anon public`]
- Service Role Key: [NÃO usar no frontend]

**Tabela de usuários já existe:**
- `dashboard_users` (id UUID, email, password_hash, full_name, client_id, role)
- Autenticação via Supabase Auth (email/password)
- Usuário de teste: `teste@evolutedigital.com.br` / `Teste@2024!`

**⚠️ IMPORTANTE:** Não criar novas tabelas nem funções RPC neste prompt. Apenas usar Supabase Auth para login.

---

## 🎨 Design System

### Paleta de Cores
```css
/* Primary Colors */
--primary: #667eea           /* Roxo Tech Principal */
--primary-dark: #5568d3      /* Hover states */
--primary-light: #7c8df5     /* Backgrounds claros */

/* Secondary Colors */
--accent: #10b981            /* Verde Sucesso */
--warning: #f59e0b           /* Amarelo Alerta */
--danger: #ef4444            /* Vermelho Erro */

/* Neutral Colors */
--bg-main: #ffffff           /* Fundo principal */
--bg-secondary: #f9fafb      /* Fundo cards */
--bg-sidebar: #1f2937        /* Sidebar escuro */

--text-dark: #1f2937         /* Texto principal */
--text-medium: #6b7280       /* Texto secundário */
--text-light: #9ca3af        /* Texto terciário */
```

### Tipografia
- **Font Family:** Inter (importar via Google Fonts)
- **Font Weights:** 400 (Regular), 500 (Medium), 700 (Bold)
- **Tamanhos:**
  - h1: 24px (1.5rem)
  - h2: 20px (1.25rem)
  - h3: 16px (1rem)
  - body: 14px (0.875rem)
  - small: 12px (0.75rem)

### Ícones
- **Biblioteca:** Lucide React (`lucide-react`)
- **Tamanho padrão:** 20px
- **Ícones principais:** MessageCircle, BarChart3, Settings, HelpCircle, LogOut, User

---

## 🔐 Página de Login (`/login`)

### Layout: Split Screen (50/50 em desktop)

#### Lado Esquerdo - Visual
```tsx
<div className="flex-1 bg-gradient-to-br from-[#667eea] to-[#764ba2] p-12 flex flex-col justify-center">
  {/* Logo */}
  <div className="mb-12">
    <h1 className="text-4xl font-bold text-white">Digitai.app</h1>
  </div>
  
  {/* Hero Content */}
  <div className="max-w-md space-y-6 text-white">
    <h2 className="text-3xl font-bold">
      Seu Assistente IA Trabalhando 24/7
    </h2>
    <p className="text-xl text-white/90">
      Dashboard personalizado para seu negócio
    </p>
    
    {/* Features List */}
    <div className="space-y-4 mt-8">
      <div className="flex items-center gap-3">
        <MessageCircle className="w-6 h-6" />
        <span>Conversas em tempo real</span>
      </div>
      <div className="flex items-center gap-3">
        <BarChart3 className="w-6 h-6" />
        <span>Analytics inteligentes</span>
      </div>
      <div className="flex items-center gap-3">
        <Bot className="w-6 h-6" />
        <span>IA treinada no seu negócio</span>
      </div>
      <div className="flex items-center gap-3">
        <Image className="w-6 h-6" />
        <span>Geração de imagens e documentos</span>
      </div>
    </div>
  </div>
</div>
```

#### Lado Direito - Formulário
```tsx
<div className="flex-1 bg-white p-12 flex items-center justify-center">
  <div className="w-full max-w-md space-y-8">
    {/* Header */}
    <div className="text-center">
      <h2 className="text-2xl font-bold text-gray-900">Área do Cliente</h2>
      <p className="mt-2 text-sm text-gray-600">
        Acesse seu dashboard personalizado
      </p>
    </div>
    
    {/* Form */}
    <form onSubmit={handleLogin} className="space-y-6">
      {/* Email Field */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Email
        </label>
        <div className="relative">
          <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="email"
            required
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="seu@email.com"
          />
        </div>
      </div>
      
      {/* Password Field */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Senha
        </label>
        <div className="relative">
          <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type={showPassword ? 'text' : 'password'}
            required
            className="w-full pl-10 pr-12 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            placeholder="••••••••"
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-3 top-1/2 -translate-y-1/2"
          >
            {showPassword ? <EyeOff className="w-5 h-5 text-gray-400" /> : <Eye className="w-5 h-5 text-gray-400" />}
          </button>
        </div>
      </div>
      
      {/* Remember Me */}
      <div className="flex items-center">
        <input
          type="checkbox"
          id="remember"
          className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
        />
        <label htmlFor="remember" className="ml-2 text-sm text-gray-600">
          Lembrar de mim
        </label>
      </div>
      
      {/* Error Message */}
      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
          {error}
        </div>
      )}
      
      {/* Submit Button */}
      <button
        type="submit"
        disabled={loading}
        className="w-full bg-primary hover:bg-primary-dark text-white py-3 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {loading ? 'Entrando...' : 'Entrar'}
      </button>
      
      {/* Forgot Password */}
      <div className="text-center">
        <a href="#" className="text-sm text-primary hover:text-primary-dark">
          Esqueceu sua senha?
        </a>
      </div>
    </form>
    
    {/* Divider */}
    <div className="relative">
      <div className="absolute inset-0 flex items-center">
        <div className="w-full border-t border-gray-300"></div>
      </div>
      <div className="relative flex justify-center text-sm">
        <span className="px-2 bg-white text-gray-500">ou</span>
      </div>
    </div>
    
    {/* Demo Link */}
    <div className="text-center">
      <p className="text-sm text-gray-600">Precisa de acesso?</p>
      <a
        href="https://evolute.chat"
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-1 text-sm text-primary hover:text-primary-dark font-medium mt-2"
      >
        Solicitar demonstração <ArrowRight className="w-4 h-4" />
      </a>
    </div>
  </div>
</div>
```

### Lógica de Autenticação (Supabase)
```typescript
import { supabase } from '@/lib/supabase'

const handleLogin = async (e: React.FormEvent) => {
  e.preventDefault()
  setLoading(true)
  setError('')
  
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    })
    
    if (error) throw error
    
    // ✅ Login bem-sucedido → redirecionar para dashboard
    router.push('/')
    
  } catch (err: any) {
    setError(err.message || 'Erro ao fazer login')
  } finally {
    setLoading(false)
  }
}
```

### Validações
- Email: formato válido (usar type="email")
- Senha: mínimo 8 caracteres
- Mensagens de erro em vermelho abaixo dos campos
- Loading state no botão (desabilitar e mostrar "Entrando...")

### Responsivo
- **Desktop (lg):** Split 50/50 horizontal
- **Tablet (md):** Split vertical (formulário acima, visual embaixo)
- **Mobile (sm):** Apenas formulário (ocultar visual)

---

## 🏗️ Layout Principal (após login)

### Estrutura
```
┌────────────────────────────────────────────────────────┐
│ Sidebar (240px)    │ Main Content                      │
│                    │ ┌──────────────────────────────┐  │
│ [Logo]             │ │ Header                       │  │
│                    │ ├──────────────────────────────┤  │
│ 💬 Conversas       │ │                              │  │
│ 📊 Resumo          │ │ Page Content                 │  │
│ ⚙️ Configurações   │ │                              │  │
│ ❓ Suporte         │ │                              │  │
│                    │ │                              │  │
│ [User Footer]      │ │                              │  │
└────────────────────────────────────────────────────────┘
```

### Sidebar (Fixa, Esquerda)
```tsx
<aside className="w-64 bg-gray-900 text-white h-screen flex flex-col fixed left-0 top-0">
  {/* Logo */}
  <div className="p-6 border-b border-gray-800">
    <h1 className="text-2xl font-bold">Digitai.app</h1>
  </div>
  
  {/* Navigation */}
  <nav className="flex-1 p-4 space-y-2">
    <NavLink href="/" icon={MessageCircle}>
      Conversas
    </NavLink>
    <NavLink href="/resumo" icon={BarChart3}>
      Resumo
    </NavLink>
    <NavLink href="/configuracoes" icon={Settings}>
      Configurações
    </NavLink>
    <NavLink href="/suporte" icon={HelpCircle}>
      Suporte
    </NavLink>
  </nav>
  
  {/* User Footer */}
  <div className="p-4 border-t border-gray-800">
    <div className="flex items-center gap-3">
      <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center">
        <User className="w-5 h-5" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">{user?.full_name}</p>
        <p className="text-xs text-gray-400 truncate">{user?.email}</p>
      </div>
      <button
        onClick={handleLogout}
        className="p-2 hover:bg-gray-800 rounded-lg transition-colors"
        title="Sair"
      >
        <LogOut className="w-5 h-5" />
      </button>
    </div>
  </div>
</aside>
```

### NavLink Component
```tsx
interface NavLinkProps {
  href: string
  icon: React.ComponentType<{ className?: string }>
  children: React.ReactNode
}

const NavLink = ({ href, icon: Icon, children }: NavLinkProps) => {
  const router = useRouter()
  const isActive = router.pathname === href
  
  return (
    <Link
      href={href}
      className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
        isActive 
          ? 'bg-primary text-white' 
          : 'text-gray-300 hover:bg-gray-800 hover:text-white'
      }`}
    >
      <Icon className="w-5 h-5" />
      <span className="font-medium">{children}</span>
    </Link>
  )
}
```

### Header (Topo, Fixo)
```tsx
<header className="h-16 bg-white border-b border-gray-200 px-6 flex items-center justify-between sticky top-0 z-10">
  {/* Breadcrumb / Title */}
  <div>
    <h1 className="text-xl font-bold text-gray-900">
      {pageTitle}
    </h1>
  </div>
  
  {/* User Menu (Dropdown) */}
  <DropdownMenu>
    <DropdownMenuTrigger asChild>
      <button className="flex items-center gap-2 p-2 rounded-lg hover:bg-gray-100">
        <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
          <User className="w-4 h-4 text-white" />
        </div>
        <span className="text-sm font-medium">{user?.full_name}</span>
        <ChevronDown className="w-4 h-4" />
      </button>
    </DropdownMenuTrigger>
    <DropdownMenuContent align="end">
      <DropdownMenuItem onClick={() => router.push('/perfil')}>
        <User className="w-4 h-4 mr-2" />
        Meu Perfil
      </DropdownMenuItem>
      <DropdownMenuItem onClick={() => router.push('/alterar-senha')}>
        <Key className="w-4 h-4 mr-2" />
        Alterar Senha
      </DropdownMenuItem>
      <DropdownMenuSeparator />
      <DropdownMenuItem onClick={handleLogout} className="text-red-600">
        <LogOut className="w-4 h-4 mr-2" />
        Sair
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
</header>
```

### Content Area
```tsx
<main className="ml-64 min-h-screen bg-gray-50">
  <Header />
  <div className="p-6">
    {children}
  </div>
</main>
```

---

## 🔒 Proteção de Rotas

### ProtectedRoute Component
```typescript
import { useEffect } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '@/lib/supabase'

export const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const router = useRouter()
  const [loading, setLoading] = useState(true)
  const [user, setUser] = useState(null)
  
  useEffect(() => {
    // Verificar sessão ao carregar
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        router.push('/login')
      } else {
        setUser(session.user)
        setLoading(false)
      }
    })
    
    // Listener para mudanças de autenticação
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        router.push('/login')
      }
    })
    
    return () => subscription.unsubscribe()
  }, [])
  
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    )
  }
  
  return <>{children}</>
}
```

### Uso
```tsx
// pages/index.tsx
export default function Home() {
  return (
    <ProtectedRoute>
      <Layout>
        {/* Dashboard content */}
      </Layout>
    </ProtectedRoute>
  )
}
```

---

## 📦 Tech Stack

- **Framework:** React + Next.js (App Router ou Pages Router)
- **Styling:** Tailwind CSS
- **UI Components:** Shadcn/ui (Button, Input, DropdownMenu, etc.)
- **Icons:** Lucide React
- **Auth:** Supabase Auth
- **State:** React hooks (useState, useEffect)
- **Navigation:** Next.js Router

---

## ✅ Checklist de Entrega

- [ ] Página de login com split screen (visual + formulário)
- [ ] Integração Supabase Auth (signInWithPassword)
- [ ] Validações de email e senha
- [ ] Loading states e mensagens de erro
- [ ] Toggle para mostrar/ocultar senha
- [ ] Layout principal com sidebar fixa (240px)
- [ ] Header com dropdown de usuário
- [ ] Navegação entre páginas (NavLink com estado ativo)
- [ ] ProtectedRoute para páginas autenticadas
- [ ] Logout funcional
- [ ] Design responsivo (mobile, tablet, desktop)
- [ ] Paleta de cores e tipografia conforme design system
- [ ] Ícones Lucide React
- [ ] Hover states e transições suaves

---

## 🎨 Notas de Estilo

- Use `transition-colors duration-200` para transições suaves
- Bordas arredondadas: `rounded-lg` (8px)
- Sombras: `shadow-sm` para cards, `shadow-md` para modais
- Focus states: `focus:ring-2 focus:ring-primary focus:border-transparent`
- Espaçamentos: múltiplos de 4px (p-2, p-4, p-6, etc.)

---

## 🚀 Próximos Passos (Prompt 2)

Após concluir este prompt:
- Dashboard principal com métricas
- Lista de conversas com filtro multi-canal
- Integração com RPC functions do Supabase
- Real-time subscriptions

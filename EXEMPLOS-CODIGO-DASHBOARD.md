# Exemplos de Código TypeScript - Dashboard Digitai.app

## 🔌 Setup Supabase Client

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

## 🎣 Custom Hooks

### useAuth - Autenticação
```typescript
// lib/hooks/useAuth.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { User } from '@supabase/supabase-js'

interface DashboardUser {
  id: string
  client_id: string
  full_name: string
  email: string
  role: 'owner' | 'admin' | 'operator' | 'viewer'
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [dashboardUser, setDashboardUser] = useState<DashboardUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Verificar sessão inicial
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      if (session?.user) {
        loadDashboardUser(session.user.id)
      } else {
        setLoading(false)
      }
    })

    // Escutar mudanças de autenticação
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
      if (session?.user) {
        loadDashboardUser(session.user.id)
      } else {
        setDashboardUser(null)
        setLoading(false)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  async function loadDashboardUser(userId: string) {
    const { data, error } = await supabase
      .from('dashboard_users')
      .select('id, client_id, full_name, email, role')
      .eq('id', userId)
      .single()

    if (error) {
      console.error('Erro ao carregar usuário:', error)
    } else {
      setDashboardUser(data)
    }
    setLoading(false)
  }

  const signIn = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })
    return { data, error }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
  }

  return {
    user,
    dashboardUser,
    loading,
    signIn,
    signOut
  }
}
```

### useConversations - Lista de Conversas
```typescript
// lib/hooks/useConversations.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface Conversation {
  id: string
  chatwoot_conversation_id: number
  customer_name: string
  customer_phone: string
  status: 'active' | 'needs_human' | 'human_takeover' | 'resolved' | 'archived'
  unread_count: number
  last_message_content: string
  last_message_timestamp: string
  last_message_sender: string
  assigned_to_name: string | null
  created_at: string
  updated_at: string
}

export function useConversations(clientId: string, statusFilter?: string) {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    loadConversations()

    // Real-time subscription
    const channel = supabase
      .channel('conversations')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'conversations',
          filter: `client_id=eq.${clientId}`
        },
        () => {
          loadConversations()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [clientId, statusFilter])

  async function loadConversations() {
    try {
      setLoading(true)
      const { data, error } = await supabase.rpc('get_conversations_list', {
        p_client_id: clientId,
        p_status_filter: statusFilter || null,
        p_limit: 50,
        p_offset: 0
      })

      if (error) throw error
      setConversations(data || [])
    } catch (err) {
      setError(err as Error)
    } finally {
      setLoading(false)
    }
  }

  return { conversations, loading, error, refresh: loadConversations }
}
```

### useConversationDetail - Detalhes + Mensagens
```typescript
// lib/hooks/useConversationDetail.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface Message {
  id: string
  role: 'user' | 'assistant' | 'agent_human' | 'system'
  content: string
  timestamp: string
  sender_name: string
  has_attachments: boolean
  attachments: Array<{ url: string; type: string }>
}

interface ConversationDetail {
  conversation: any
  messages: Message[]
}

export function useConversationDetail(conversationId: string) {
  const [data, setData] = useState<ConversationDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    loadDetail()

    // Real-time subscription para novas mensagens
    const channel = supabase
      .channel(`conversation-${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'conversation_memory',
          filter: `conversation_uuid=eq.${conversationId}`
        },
        (payload) => {
          // Adicionar nova mensagem
          setData(prev => {
            if (!prev) return prev
            return {
              ...prev,
              messages: [...prev.messages, payload.new as Message]
            }
          })
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [conversationId])

  async function loadDetail() {
    try {
      setLoading(true)
      const { data: result, error } = await supabase.rpc('get_conversation_detail', {
        p_conversation_uuid: conversationId
      })

      if (error) throw error
      setData(result)
    } catch (err) {
      setError(err as Error)
    } finally {
      setLoading(false)
    }
  }

  return { data, loading, error, refresh: loadDetail }
}
```

### useStats - Métricas do Dashboard
```typescript
// lib/hooks/useStats.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface DashboardStats {
  today: {
    total_conversations: number
    active_now: number
    needs_human: number
    resolved_by_ai: number
    human_handled: number
    ai_success_rate: number
  }
  last_7_days: Array<{
    date: string
    conversations: number
  }>
}

export function useStats(clientId: string) {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    loadStats()

    // Atualizar a cada 30 segundos
    const interval = setInterval(loadStats, 30000)
    return () => clearInterval(interval)
  }, [clientId])

  async function loadStats() {
    try {
      const today = new Date().toISOString().split('T')[0]
      const { data, error } = await supabase.rpc('get_dashboard_stats', {
        p_client_id: clientId,
        p_date: today
      })

      if (error) throw error
      setStats(data)
    } catch (err) {
      setError(err as Error)
    } finally {
      setLoading(false)
    }
  }

  return { stats, loading, error, refresh: loadStats }
}
```

## 🎬 Actions - Takeover/Release/Send

```typescript
// lib/actions/conversations.ts
import { supabase } from '@/lib/supabase'

export async function takeoverConversation(
  conversationId: string,
  userName: string
) {
  const { data, error } = await supabase.rpc('takeover_conversation', {
    p_conversation_uuid: conversationId,
    p_user_name: userName
  })

  if (error) throw error
  return data
}

export async function releaseConversation(conversationId: string) {
  const { data, error } = await supabase.rpc('release_conversation', {
    p_conversation_uuid: conversationId
  })

  if (error) throw error
  return data
}

export async function sendHumanMessage(
  conversationId: string,
  content: string,
  mediaUrl?: string
) {
  const { data, error } = await supabase.rpc('send_human_message', {
    p_conversation_uuid: conversationId,
    p_message_content: content,
    p_media_url: mediaUrl || null
  })

  if (error) throw error
  return data
}
```

## 📄 Exemplo de Página: ConversationList

```typescript
// pages/Conversations.tsx
import { useAuth } from '@/lib/hooks/useAuth'
import { useConversations } from '@/lib/hooks/useConversations'
import { ConversationItem } from '@/components/conversations/ConversationItem'
import { Button } from '@/components/ui/button'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { useState } from 'react'

export function ConversationsPage() {
  const { dashboardUser } = useAuth()
  const [statusFilter, setStatusFilter] = useState<string | undefined>()
  
  const { conversations, loading, error } = useConversations(
    dashboardUser?.client_id || '',
    statusFilter
  )

  if (loading) return <div>Carregando...</div>
  if (error) return <div>Erro: {error.message}</div>

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Conversas</h1>
        <Button onClick={() => window.location.reload()}>
          Atualizar
        </Button>
      </div>

      <Tabs value={statusFilter || 'all'} onValueChange={(v) => setStatusFilter(v === 'all' ? undefined : v)}>
        <TabsList>
          <TabsTrigger value="all">Todas</TabsTrigger>
          <TabsTrigger value="needs_human">Precisam Atenção</TabsTrigger>
          <TabsTrigger value="active">Ativas</TabsTrigger>
          <TabsTrigger value="human_takeover">Em Atendimento</TabsTrigger>
          <TabsTrigger value="resolved">Resolvidas</TabsTrigger>
        </TabsList>
      </Tabs>

      <div className="mt-6 space-y-4">
        {conversations.map((conv) => (
          <ConversationItem
            key={conv.id}
            conversation={conv}
            onClick={() => navigate(`/conversations/${conv.id}`)}
          />
        ))}

        {conversations.length === 0 && (
          <div className="text-center text-gray-500 py-12">
            Nenhuma conversa encontrada
          </div>
        )}
      </div>
    </div>
  )
}
```

## 🗨️ Exemplo de Componente: MessageBubble

```typescript
// components/conversations/MessageBubble.tsx
import { cn } from '@/lib/utils'
import { format } from 'date-fns'
import { ptBR } from 'date-fns/locale'

interface MessageBubbleProps {
  role: 'user' | 'assistant' | 'agent_human' | 'system'
  content: string
  timestamp: string
  senderName?: string
  attachments?: Array<{ url: string; type: string }>
}

export function MessageBubble({
  role,
  content,
  timestamp,
  senderName,
  attachments
}: MessageBubbleProps) {
  const isCustomer = role === 'user'
  const isSystem = role === 'system'

  if (isSystem) {
    return (
      <div className="flex justify-center my-4">
        <div className="bg-yellow-100 text-yellow-800 px-4 py-2 rounded-full text-sm">
          {content}
        </div>
      </div>
    )
  }

  return (
    <div className={cn(
      "flex gap-3 mb-4",
      !isCustomer && "flex-row-reverse"
    )}>
      <div className={cn(
        "max-w-[70%] rounded-2xl px-4 py-2",
        isCustomer ? "bg-white" : "bg-purple-600 text-white"
      )}>
        {senderName && (
          <div className="text-xs opacity-70 mb-1">{senderName}</div>
        )}
        <div className="text-sm whitespace-pre-wrap">{content}</div>
        
        {attachments && attachments.length > 0 && (
          <div className="mt-2 space-y-2">
            {attachments.map((att, i) => (
              <a
                key={i}
                href={att.url}
                target="_blank"
                rel="noopener noreferrer"
                className="block text-sm underline"
              >
                📎 Anexo {i + 1}
              </a>
            ))}
          </div>
        )}
        
        <div className="text-xs opacity-70 mt-1">
          {format(new Date(timestamp), 'HH:mm', { locale: ptBR })}
        </div>
      </div>
    </div>
  )
}
```

## 🎯 Exemplo: Botão Takeover

```typescript
// components/conversations/TakeoverButton.tsx
import { Button } from '@/components/ui/button'
import { takeoverConversation } from '@/lib/actions/conversations'
import { useAuth } from '@/lib/hooks/useAuth'
import { useState } from 'react'
import { toast } from 'sonner'

interface TakeoverButtonProps {
  conversationId: string
  onSuccess?: () => void
}

export function TakeoverButton({ conversationId, onSuccess }: TakeoverButtonProps) {
  const { dashboardUser } = useAuth()
  const [loading, setLoading] = useState(false)

  async function handleTakeover() {
    if (!dashboardUser) return

    try {
      setLoading(true)
      await takeoverConversation(conversationId, dashboardUser.full_name)
      toast.success('Você assumiu o atendimento!')
      onSuccess?.()
    } catch (error) {
      console.error('Erro ao assumir:', error)
      toast.error('Erro ao assumir conversa')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Button
      onClick={handleTakeover}
      disabled={loading}
      className="bg-purple-600 hover:bg-purple-700"
    >
      {loading ? 'Assumindo...' : '🙋 Assumir Atendimento'}
    </Button>
  )
}
```

## 🔔 Notificações Browser

```typescript
// lib/utils/notifications.ts
export function requestNotificationPermission() {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission()
  }
}

export function showNotification(title: string, body: string) {
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, {
      body,
      icon: '/logo.png',
      badge: '/logo.png',
      tag: 'digitai-notification'
    })

    // Som de alerta
    const audio = new Audio('/notification.mp3')
    audio.play().catch(console.error)
  }
}

// Usar no hook de conversas
useEffect(() => {
  const channel = supabase
    .channel('new-needs-human')
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'conversations',
        filter: `status=eq.needs_human`
      },
      (payload) => {
        showNotification(
          '🚨 Atenção Necessária',
          `${payload.new.customer_name} precisa de ajuda humana`
        )
      }
    )
    .subscribe()

  return () => supabase.removeChannel(channel)
}, [])
```

---

**✅ Com estes exemplos, o Lovable consegue gerar o dashboard completo!**

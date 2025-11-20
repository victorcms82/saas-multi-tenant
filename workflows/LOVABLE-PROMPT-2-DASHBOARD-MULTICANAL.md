# Prompt 2: Dashboard Principal e Lista Multi-Canal - Digitai.app

## 🎯 Objetivo
Criar o dashboard principal com métricas, lista de conversas com suporte multi-canal (WhatsApp, Instagram, WebChat, Email) e integração com funções RPC do Supabase.

---

## ⚠️ PRÉ-REQUISITOS (já implementados no Prompt 1)

✅ Layout base com sidebar e header
✅ Autenticação Supabase funcionando
✅ ProtectedRoute para páginas autenticadas
✅ Design system (cores, tipografia, ícones)

---

## 📊 Dashboard Principal (`/` ou `/dashboard`)

### Layout: Cards + Lista

```
┌─────────────────────────────────────────────────────────────┐
│ Header: "💬 Dashboard - Conversas em Tempo Real"            │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│ │ Hoje    │  │ IA      │  │ Ativas  │  │ Taxa    │        │
│ │ 42      │  │ 38 (90%)│  │ 4       │  │ 95%     │        │
│ └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
├─────────────────────────────────────────────────────────────┤
│ 💬 Conversas em Tempo Real                                  │
│                                                             │
│ [Todos] [📱 WhatsApp] [📷 Instagram] [💬 WebChat] [📧 Email]│
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐│
│ │ 📱 Maria Silva • 11 98765-4321 • há 2 min               ││
│ │ Preciso remarcar minha consulta...           🟢  [Ver]  ││
│ └─────────────────────────────────────────────────────────┘│
│ ┌─────────────────────────────────────────────────────────┐│
│ │ 📷 @joao.santos • Instagram • há 5 min                  ││
│ │ Quanto custa uma avaliação?               🟡  [Assumir] ││
│ └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 📈 Cards de Métricas (Topo)

### Integração com RPC `get_dashboard_stats`

```typescript
// Buscar métricas do Supabase
const fetchStats = async () => {
  const user = await supabase.auth.getUser()
  
  // Buscar client_id do usuário
  const { data: userData } = await supabase
    .from('dashboard_users')
    .select('client_id')
    .eq('id', user.data.user?.id)
    .single()
  
  // Buscar estatísticas via RPC
  const { data: stats } = await supabase
    .rpc('get_dashboard_stats', {
      p_client_id: userData.client_id
    })
  
  setStats(stats)
}

// Retorno esperado de get_dashboard_stats():
// {
//   total_conversations_today: 42,
//   conversations_handled_by_ai: 38,
//   ai_resolution_rate: 0.90,
//   active_conversations: 4,
//   conversations_needing_human: 3,
//   avg_response_time_seconds: 2.3
// }
```

### Grid de Cards
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
  <MetricCard
    title="Conversas Hoje"
    value={stats?.total_conversations_today || 0}
    icon={MessageCircle}
    iconColor="text-blue-500"
    bgColor="bg-blue-50"
  />
  <MetricCard
    title="Resolvidas pela IA"
    value={stats?.conversations_handled_by_ai || 0}
    subtitle={`${Math.round((stats?.ai_resolution_rate || 0) * 100)}%`}
    icon={Bot}
    iconColor="text-green-500"
    bgColor="bg-green-50"
  />
  <MetricCard
    title="Ativas Agora"
    value={stats?.active_conversations || 0}
    icon={Activity}
    iconColor="text-yellow-500"
    bgColor="bg-yellow-50"
  />
  <MetricCard
    title="Taxa Sucesso IA"
    value={`${Math.round((stats?.ai_resolution_rate || 0) * 100)}%`}
    icon={TrendingUp}
    iconColor="text-purple-500"
    bgColor="bg-purple-50"
  />
</div>
```

### Componente MetricCard
```tsx
interface MetricCardProps {
  title: string
  value: number | string
  subtitle?: string
  icon: React.ComponentType<{ className?: string }>
  iconColor: string
  bgColor: string
}

const MetricCard = ({ title, value, subtitle, icon: Icon, iconColor, bgColor }: MetricCardProps) => {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <div className="mt-2 flex items-baseline">
            <p className="text-3xl font-bold text-gray-900">{value}</p>
            {subtitle && (
              <span className="ml-2 text-sm font-medium text-gray-500">
                {subtitle}
              </span>
            )}
          </div>
        </div>
        <div className={`${bgColor} ${iconColor} p-3 rounded-lg`}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
    </div>
  )
}
```

---

## 🗂️ Lista de Conversas Multi-Canal

### Tabs de Filtro por Canal

```tsx
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'

type ChannelType = 'whatsapp' | 'instagram' | 'webchat' | 'email' | null

const [activeChannel, setActiveChannel] = useState<ChannelType>(null)

<Tabs defaultValue="all" onValueChange={(v) => setActiveChannel(v === 'all' ? null : v as ChannelType)}>
  <TabsList className="grid grid-cols-5 w-full max-w-2xl">
    <TabsTrigger value="all">
      Todos
    </TabsTrigger>
    <TabsTrigger value="whatsapp">
      <MessageCircle className="w-4 h-4 mr-2" />
      WhatsApp
    </TabsTrigger>
    <TabsTrigger value="instagram">
      <Instagram className="w-4 h-4 mr-2" />
      Instagram
    </TabsTrigger>
    <TabsTrigger value="webchat">
      <Globe className="w-4 h-4 mr-2" />
      WebChat
    </TabsTrigger>
    <TabsTrigger value="email">
      <Mail className="w-4 h-4 mr-2" />
      Email
    </TabsTrigger>
  </TabsList>
</Tabs>
```

### Integração com RPC `get_conversations_list`

```typescript
// 🆕 Migration 023: Agora suporta filtro por canal!
const fetchConversations = async () => {
  const user = await supabase.auth.getUser()
  
  // Buscar client_id
  const { data: userData } = await supabase
    .from('dashboard_users')
    .select('client_id')
    .eq('id', user.data.user?.id)
    .single()
  
  // Buscar conversas com filtro de canal
  const { data: conversations } = await supabase
    .rpc('get_conversations_list', {
      p_client_id: userData.client_id,
      p_status_filter: null, // ou 'active', 'needs_human', etc
      p_channel_filter: activeChannel, // 🆕 'whatsapp' | 'instagram' | 'webchat' | 'email' | null
      p_limit: 50,
      p_offset: 0
    })
  
  setConversations(conversations || [])
}

// Recarregar quando o canal mudar
useEffect(() => {
  fetchConversations()
}, [activeChannel])

// Retorno esperado:
// [
//   {
//     id: UUID,
//     chatwoot_conversation_id: number,
//     customer_name: string,
//     customer_phone: string | null,
//     channel_type: 'whatsapp' | 'instagram' | 'webchat' | 'email', // 🆕
//     channel_specific_data: JSONB, // 🆕 { customer_phone, instagram_username, etc }
//     status: string,
//     unread_count: number,
//     last_message_content: string,
//     last_message_timestamp: timestamp,
//     last_message_sender: string,
//     assigned_to_name: string | null,
//     taken_over_at: timestamp | null,
//     created_at: timestamp,
//     updated_at: timestamp
//   }
// ]
```

### TypeScript Interfaces

```typescript
type ChannelType = 'whatsapp' | 'instagram' | 'webchat' | 'email'

interface ChannelSpecificData {
  customer_phone?: string // WhatsApp
  instagram_username?: string // Instagram
  instagram_id?: string // Instagram
  session_id?: string // WebChat
  visitor_name?: string // WebChat
  visitor_email?: string // WebChat
  email_address?: string // Email
  email_subject?: string // Email
  email_name?: string // Email
}

interface Conversation {
  id: string
  chatwoot_conversation_id: number
  customer_name: string
  customer_phone: string | null
  channel_type: ChannelType // 🆕
  channel_specific_data: ChannelSpecificData // 🆕
  status: 'active' | 'needs_human' | 'human_takeover' | 'resolved' | 'escalated'
  unread_count: number
  last_message_content: string | null
  last_message_timestamp: string | null
  last_message_sender: string | null
  assigned_to_name: string | null
  taken_over_at: string | null
  created_at: string
  updated_at: string
}
```

### Lista de Conversas

```tsx
<div className="space-y-2">
  {conversations.length === 0 ? (
    <div className="text-center py-12 text-gray-500">
      <MessageCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
      <p>Nenhuma conversa encontrada</p>
    </div>
  ) : (
    conversations.map((conversation) => (
      <ConversationCard
        key={conversation.id}
        conversation={conversation}
        onClick={() => router.push(`/conversations/${conversation.id}`)}
      />
    ))
  )}
</div>
```

---

## 💬 Componente ConversationCard

```tsx
interface ConversationCardProps {
  conversation: Conversation
  onClick: () => void
}

const ConversationCard = ({ conversation, onClick }: ConversationCardProps) => {
  const channelIcons = {
    whatsapp: <MessageCircle className="w-5 h-5 text-green-500" />,
    instagram: <Instagram className="w-5 h-5 text-pink-500" />,
    webchat: <Globe className="w-5 h-5 text-blue-500" />,
    email: <Mail className="w-5 h-5 text-gray-500" />
  }
  
  const statusColors = {
    active: 'text-green-500',
    needs_human: 'text-yellow-500',
    human_takeover: 'text-red-500',
    resolved: 'text-gray-400'
  }
  
  // 🆕 Extrair identificador correto por canal
  const getCustomerIdentifier = () => {
    const { channel_type, channel_specific_data } = conversation
    
    switch(channel_type) {
      case 'whatsapp':
        return channel_specific_data.customer_phone
      case 'instagram':
        return channel_specific_data.instagram_username
      case 'webchat':
        return channel_specific_data.visitor_name
      case 'email':
        return channel_specific_data.email_address
      default:
        return 'Desconhecido'
    }
  }
  
  const formatTimestamp = (timestamp: string | null) => {
    if (!timestamp) return ''
    
    const date = new Date(timestamp)
    const now = new Date()
    const diffMinutes = Math.floor((now.getTime() - date.getTime()) / 60000)
    
    if (diffMinutes < 1) return 'agora'
    if (diffMinutes < 60) return `há ${diffMinutes} min`
    if (diffMinutes < 1440) return `há ${Math.floor(diffMinutes / 60)} h`
    return `há ${Math.floor(diffMinutes / 1440)} dias`
  }
  
  return (
    <div
      onClick={onClick}
      className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
    >
      <div className="flex items-start gap-3">
        {/* Channel Icon */}
        <div className="mt-1">
          {channelIcons[conversation.channel_type]}
        </div>
        
        {/* Content */}
        <div className="flex-1 min-w-0">
          {/* Header */}
          <div className="flex items-center justify-between mb-1">
            <div className="flex items-center gap-2">
              <h3 className="font-semibold text-gray-900 truncate">
                {conversation.customer_name}
              </h3>
              <ChannelBadge channel={conversation.channel_type} />
            </div>
            <span className="text-xs text-gray-500">
              {formatTimestamp(conversation.last_message_timestamp)}
            </span>
          </div>
          
          {/* Identifier */}
          <p className="text-sm text-gray-600 mb-2">
            {getCustomerIdentifier()}
          </p>
          
          {/* Last Message */}
          <p className="text-sm text-gray-700 truncate">
            {conversation.last_message_content || 'Sem mensagens'}
          </p>
          
          {/* Footer */}
          <div className="flex items-center justify-between mt-3">
            <div className="flex items-center gap-2">
              {/* Status Indicator */}
              <div className="flex items-center gap-1">
                <div className={`w-2 h-2 rounded-full ${statusColors[conversation.status]}`} />
                <span className="text-xs text-gray-600">
                  {conversation.status === 'active' && 'IA Atendendo'}
                  {conversation.status === 'needs_human' && 'Precisa Atenção'}
                  {conversation.status === 'human_takeover' && 'Você Atendendo'}
                  {conversation.status === 'resolved' && 'Finalizada'}
                </span>
              </div>
              
              {/* Unread Count */}
              {conversation.unread_count > 0 && (
                <span className="px-2 py-0.5 bg-primary text-white text-xs rounded-full">
                  {conversation.unread_count}
                </span>
              )}
            </div>
            
            {/* Action Button */}
            {conversation.status === 'needs_human' && (
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  // Assumir conversa
                }}
                className="px-3 py-1 bg-primary hover:bg-primary-dark text-white text-sm rounded-lg transition-colors"
              >
                Assumir
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
```

---

## 🏷️ Componente ChannelBadge

```tsx
const ChannelBadge = ({ channel }: { channel: ChannelType }) => {
  const styles = {
    whatsapp: 'bg-green-100 text-green-800',
    instagram: 'bg-pink-100 text-pink-800',
    webchat: 'bg-blue-100 text-blue-800',
    email: 'bg-gray-100 text-gray-800'
  }
  
  const labels = {
    whatsapp: 'WhatsApp',
    instagram: 'Instagram',
    webchat: 'WebChat',
    email: 'Email'
  }
  
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${styles[channel]}`}>
      {labels[channel]}
    </span>
  )
}
```

---

## 🔄 Real-time (Preparação)

### Subscription para Novas Conversas
```typescript
useEffect(() => {
  // Subscribe to new conversations
  const subscription = supabase
    .channel('conversations-changes')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'conversations',
        filter: `client_id=eq.${clientId}`
      },
      (payload) => {
        console.log('Conversation changed:', payload)
        // Atualizar lista
        fetchConversations()
      }
    )
    .subscribe()
  
  return () => {
    subscription.unsubscribe()
  }
}, [clientId])
```

---

## 🎨 Filtros Adicionais (Opcional)

### Barra de Busca
```tsx
<div className="relative mb-4">
  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
  <input
    type="text"
    placeholder="Buscar por nome ou identificador..."
    value={searchQuery}
    onChange={(e) => setSearchQuery(e.target.value)}
    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
  />
</div>
```

### Filtro por Status
```tsx
<Select value={statusFilter} onValueChange={setStatusFilter}>
  <SelectTrigger className="w-48">
    <SelectValue placeholder="Filtrar por status" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="all">Todas</SelectItem>
    <SelectItem value="active">IA Atendendo</SelectItem>
    <SelectItem value="needs_human">Precisa Atenção</SelectItem>
    <SelectItem value="human_takeover">Você Atendendo</SelectItem>
    <SelectItem value="resolved">Finalizadas</SelectItem>
  </SelectContent>
</Select>
```

---

## ✅ Checklist de Entrega

- [ ] Grid de 4 cards de métricas (integração com `get_dashboard_stats`)
- [ ] Tabs de filtro por canal (Todos, WhatsApp, Instagram, WebChat, Email)
- [ ] Lista de conversas (integração com `get_conversations_list` + `p_channel_filter`)
- [ ] ConversationCard com ícone, badge e identificador por canal
- [ ] Extração correta de identificador (phone, @username, email, visitor_name)
- [ ] Status visual (verde, amarelo, vermelho, cinza)
- [ ] Unread count badge
- [ ] Botão "Assumir" para conversas `needs_human`
- [ ] Formatação de timestamp relativo (há X min/horas/dias)
- [ ] Loading states (skeleton ou spinner)
- [ ] Empty state quando sem conversas
- [ ] Busca por nome/identificador (opcional)
- [ ] Real-time subscription para updates (preparação)
- [ ] Responsivo (mobile, tablet, desktop)

---

## 🚀 Próximos Passos (Prompt 3)

Após concluir este prompt:
- Página de conversa individual (`/conversations/:id`)
- Chat interface estilo WhatsApp
- Takeover/Release funcional
- Envio de mensagens como humano
- Real-time para mensagens

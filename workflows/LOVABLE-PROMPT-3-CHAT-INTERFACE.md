# Prompt 3: Chat Interface e Real-time

## ✅ Pré-requisitos
- **Prompt 1 completo:** Layout, sidebar, autenticação
- **Prompt 2 completo:** Dashboard, métricas, lista de conversas com filtro multi-canal

## 🎯 Objetivo
Criar a interface de chat individual com suporte a takeover/release, envio de mensagens humanas, e atualizações em tempo real via Supabase subscriptions.

---

## 📋 Contexto Técnico

### Banco de Dados
- **Supabase URL:** `https://vnlfgnfaortdvmraoapq.supabase.co`
- **Anon Key:** [Obter em: Settings → API → Project API keys → `anon public`]

### RPCs Disponíveis
```typescript
// 1. Buscar detalhes da conversa
supabase.rpc('get_conversation_detail', {
  p_conversation_uuid: 'uuid-da-conversa'
})
// Retorna: { conversation: {...}, messages: [...] }

// 2. Assumir controle (takeover)
supabase.rpc('takeover_conversation', {
  p_conversation_uuid: 'uuid-da-conversa',
  p_user_name: 'Nome do Agente'
})
// Retorna: { success: true, status: 'human_takeover', ... }

// 3. Liberar controle (release)
supabase.rpc('release_conversation', {
  p_conversation_uuid: 'uuid-da-conversa'
})
// Retorna: { success: true, status: 'active', ... }

// 4. Enviar mensagem humana
supabase.rpc('send_human_message', {
  p_conversation_uuid: 'uuid-da-conversa',
  p_message_content: 'Texto da mensagem',
  p_media_url: null // ou URL da mídia
})
// Retorna: { success: true, message_id: uuid, ... }
```

### Interfaces TypeScript
```typescript
type ChannelType = 'whatsapp' | 'instagram' | 'webchat' | 'email'

interface ChannelSpecificData {
  // WhatsApp
  customer_phone?: string
  // Instagram
  instagram_username?: string
  instagram_id?: string
  // WebChat
  session_id?: string
  visitor_name?: string
  visitor_email?: string
  // Email
  email_address?: string
  email_subject?: string
  email_name?: string
}

interface Conversation {
  id: string
  chatwoot_conversation_id: number
  customer_name: string
  customer_phone: string
  channel_type: ChannelType
  channel_specific_data: ChannelSpecificData
  status: 'active' | 'resolved' | 'pending' | 'human_takeover' | 'snoozed'
  assigned_to: string | null
  assigned_to_name: string | null
  taken_over_at: string | null
  taken_over_by_name: string | null
  ai_paused: boolean
  unread_count: number
  created_at: string
  updated_at: string
}

interface Message {
  id: string
  role: 'customer' | 'assistant' | 'agent' | 'agent_human' | 'system'
  content: string
  sender_name: string | null
  timestamp: string
  has_attachments: boolean
  attachments: {
    file_type: string
    external_url: string
    data_url?: string
  }[] | null
}
```

---

## 🎨 Design System (Herdado)
- **Cores:**
  - Primary: `#667eea` (Roxo)
  - Accent: `#10b981` (Verde)
  - Background: `#f3f4f6`
  - Surface: `#ffffff`
- **Tipografia:** Inter (Google Fonts)
- **Ícones:** Lucide React
- **Estilos:** Tailwind CSS

---

## 📱 Página: Chat Individual

### Rota
- **Path:** `/conversations/:id`
- **Parâmetro:** `id` = UUID da conversa

### Layout da Página
```
┌────────────────────────────────────────────────────┐
│  ← Voltar | [Cliente] | 📱 WhatsApp | [Takeover] │ ← Header
├────────────────────────────────────────────────────┤
│                                                    │
│  [Mensagens do chat - scroll automático]          │ ← Body
│                                                    │
│  Cliente: Olá, preciso de ajuda                   │
│  IA: Olá! Como posso ajudar?                      │
│  Você: Posso ajudá-lo agora                       │
│                                                    │
├────────────────────────────────────────────────────┤
│  [Anexo] [Input de texto...] [Enviar]            │ ← Footer
└────────────────────────────────────────────────────┘
```

### Header do Chat
```tsx
// Componentes no header:
// 1. Botão "Voltar" (seta esquerda)
// 2. Nome do cliente (customer_name)
// 3. Identificador do canal (getCustomerIdentifier)
// 4. Badge do canal (ChannelBadge)
// 5. Status badge (active, resolved, human_takeover, etc.)
// 6. Botão Takeover / Release (condicional)

const ChatHeader = ({ conversation }: { conversation: Conversation }) => {
  const customerIdentifier = getCustomerIdentifier(conversation)
  const canTakeover = conversation.status === 'active' && !conversation.ai_paused
  const isOnTakeover = conversation.status === 'human_takeover'

  return (
    <div className="flex items-center justify-between p-4 border-b bg-white">
      <div className="flex items-center gap-4">
        <button onClick={() => router.push('/')} className="text-gray-600 hover:text-gray-900">
          <ArrowLeft size={24} />
        </button>
        
        <div>
          <h2 className="font-semibold text-lg">{conversation.customer_name}</h2>
          <p className="text-sm text-gray-600">{customerIdentifier}</p>
        </div>
        
        <ChannelBadge channel={conversation.channel_type} />
        <StatusBadge status={conversation.status} />
      </div>

      <div className="flex items-center gap-2">
        {canTakeover && (
          <button onClick={handleTakeover} className="px-4 py-2 bg-purple-600 text-white rounded-lg">
            Assumir Conversa
          </button>
        )}
        {isOnTakeover && (
          <button onClick={handleRelease} className="px-4 py-2 bg-green-600 text-white rounded-lg">
            Liberar para IA
          </button>
        )}
      </div>
    </div>
  )
}
```

### Body do Chat (Mensagens)
```tsx
// Estilo inspirado em WhatsApp Web
// - Mensagens do cliente: alinhadas à esquerda, fundo cinza claro
// - Mensagens da IA: alinhadas à esquerda, fundo azul claro
// - Mensagens do agente: alinhadas à direita, fundo verde
// - Mensagens do sistema: centralizadas, fundo amarelo claro

const ChatMessages = ({ messages }: { messages: Message[] }) => {
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // Scroll automático ao receber nova mensagem
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
      {messages.map((msg) => (
        <MessageBubble key={msg.id} message={msg} />
      ))}
      <div ref={messagesEndRef} />
    </div>
  )
}

const MessageBubble = ({ message }: { message: Message }) => {
  const isCustomer = message.role === 'customer'
  const isAgent = message.role === 'agent' || message.role === 'agent_human'
  const isSystem = message.role === 'system'
  const isAI = message.role === 'assistant'

  const bubbleStyles: Record<string, string> = {
    customer: 'bg-gray-200 text-gray-900 self-start',
    assistant: 'bg-blue-100 text-blue-900 self-start',
    agent: 'bg-green-500 text-white self-end',
    agent_human: 'bg-green-500 text-white self-end',
    system: 'bg-yellow-100 text-yellow-900 self-center text-center'
  }

  return (
    <div className={`flex ${isAgent ? 'justify-end' : isSystem ? 'justify-center' : 'justify-start'}`}>
      <div className={`max-w-[70%] rounded-lg px-4 py-2 ${bubbleStyles[message.role]}`}>
        {!isCustomer && message.sender_name && (
          <p className="text-xs font-semibold mb-1">{message.sender_name}</p>
        )}
        
        {/* Anexos */}
        {message.has_attachments && message.attachments && (
          <div className="mb-2 space-y-2">
            {message.attachments.map((att, idx) => (
              <AttachmentPreview key={idx} attachment={att} />
            ))}
          </div>
        )}

        {/* Conteúdo da mensagem */}
        <p className="whitespace-pre-wrap break-words">{message.content}</p>
        
        {/* Timestamp */}
        <p className="text-xs opacity-70 mt-1">
          {new Date(message.timestamp).toLocaleTimeString('pt-BR', {
            hour: '2-digit',
            minute: '2-digit'
          })}
        </p>
      </div>
    </div>
  )
}
```

### Footer do Chat (Input de Mensagem)
```tsx
// Input de mensagem com:
// - Botão de anexo (se canal suporta)
// - Campo de texto
// - Botão enviar
// - Tooltip para canais que não suportam certos recursos

const ChatInput = ({ conversation }: { conversation: Conversation }) => {
  const [message, setMessage] = useState('')
  const [isUploading, setIsUploading] = useState(false)
  
  const mediaSupport = getChannelMediaSupport(conversation.channel_type)
  const canSendMessage = conversation.status === 'human_takeover'

  const handleSend = async () => {
    if (!message.trim() || !canSendMessage) return

    const { data, error } = await supabase.rpc('send_human_message', {
      p_conversation_uuid: conversation.id,
      p_message_content: message,
      p_media_url: null
    })

    if (error) {
      toast.error('Erro ao enviar mensagem')
      return
    }

    // Chamar webhook para enviar via n8n
    await fetch('https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chatwoot_conversation_id: conversation.chatwoot_conversation_id,
        channel_type: conversation.channel_type,
        channel_specific_data: conversation.channel_specific_data,
        message: message,
        media_url: null
      })
    })

    setMessage('')
    toast.success('Mensagem enviada!')
  }

  return (
    <div className="border-t bg-white p-4">
      {!canSendMessage && (
        <div className="mb-2 text-sm text-yellow-700 bg-yellow-50 p-2 rounded">
          ⚠️ Você precisa assumir a conversa para enviar mensagens
        </div>
      )}

      <div className="flex items-center gap-2">
        {/* Botão de anexo */}
        {mediaSupport.images && (
          <button
            disabled={!canSendMessage}
            className="p-2 text-gray-600 hover:text-gray-900 disabled:opacity-50"
            title="Anexar mídia"
          >
            <Paperclip size={20} />
          </button>
        )}

        {/* Input de texto */}
        <input
          type="text"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          disabled={!canSendMessage}
          placeholder={canSendMessage ? "Digite sua mensagem..." : "Assuma a conversa para enviar"}
          className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:bg-gray-100"
        />

        {/* Botão enviar */}
        <button
          onClick={handleSend}
          disabled={!message.trim() || !canSendMessage}
          className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Send size={20} />
        </button>
      </div>

      {/* Aviso de restrições do canal */}
      {conversation.channel_type === 'instagram' && (
        <p className="text-xs text-gray-500 mt-2">
          ℹ️ Instagram não suporta áudio. Limite: {mediaSupport.maxFileSize}
        </p>
      )}
      {conversation.channel_type === 'email' && (
        <p className="text-xs text-gray-500 mt-2">
          ℹ️ Email não tem atualizações em tempo real. Atualize a página manualmente.
        </p>
      )}
    </div>
  )
}
```

---

## ⚡ Real-time com Supabase

### Subscription para Mensagens
```tsx
// Escutar novas mensagens na tabela conversation_memory
const ConversationPage = ({ conversationId }: { conversationId: string }) => {
  const [messages, setMessages] = useState<Message[]>([])
  const [conversation, setConversation] = useState<Conversation | null>(null)

  // Buscar dados iniciais
  useEffect(() => {
    loadConversation()
  }, [conversationId])

  // Real-time subscription
  useEffect(() => {
    const channel = supabase
      .channel(`conversation:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'conversation_memory',
          filter: `conversation_uuid=eq.${conversationId}`
        },
        (payload) => {
          const newMessage = payload.new as Message
          setMessages((prev) => [...prev, newMessage])
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'conversations',
          filter: `id=eq.${conversationId}`
        },
        (payload) => {
          const updatedConv = payload.new as Conversation
          setConversation(updatedConv)
          
          // Se status mudou para human_takeover, mostrar notificação
          if (updatedConv.status === 'human_takeover') {
            toast.success('Você assumiu o controle da conversa!')
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [conversationId])

  const loadConversation = async () => {
    const { data } = await supabase.rpc('get_conversation_detail', {
      p_conversation_uuid: conversationId
    })
    
    if (data) {
      setConversation(data.conversation)
      setMessages(data.messages || [])
    }
  }

  return (
    <div className="flex flex-col h-screen">
      <ChatHeader conversation={conversation} />
      <ChatMessages messages={messages} />
      <ChatInput conversation={conversation} />
    </div>
  )
}
```

---

## 🎨 Componentes Auxiliares

### StatusBadge Component
```tsx
const StatusBadge = ({ status }: { status: string }) => {
  const styles: Record<string, string> = {
    active: 'bg-green-100 text-green-800',
    needs_human: 'bg-yellow-100 text-yellow-800',
    human_takeover: 'bg-red-100 text-red-800',
    resolved: 'bg-gray-100 text-gray-800',
    pending: 'bg-blue-100 text-blue-800',
    snoozed: 'bg-purple-100 text-purple-800'
  }
  
  const labels: Record<string, string> = {
    active: 'IA Ativa',
    needs_human: 'Precisa Atenção',
    human_takeover: 'Em Atendimento',
    resolved: 'Finalizada',
    pending: 'Pendente',
    snoozed: 'Adiada'
  }
  
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status] || styles.active}`}>
      {labels[status] || status}
    </span>
  )
}
```

### AttachmentPreview Component
```tsx
const AttachmentPreview = ({ attachment }: { attachment: any }) => {
  const isImage = attachment.file_type?.startsWith('image')
  const isPdf = attachment.file_type === 'application/pdf'
  const isAudio = attachment.file_type?.startsWith('audio')
  const isVideo = attachment.file_type?.startsWith('video')
  
  if (isImage) {
    return (
      <img
        src={attachment.external_url}
        alt="Anexo"
        className="max-w-sm rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
        onClick={() => window.open(attachment.external_url, '_blank')}
      />
    )
  }
  
  if (isAudio) {
    return (
      <audio controls className="max-w-sm">
        <source src={attachment.external_url} type={attachment.file_type} />
      </audio>
    )
  }
  
  if (isVideo) {
    return (
      <video controls className="max-w-sm rounded-lg">
        <source src={attachment.external_url} type={attachment.file_type} />
      </video>
    )
  }
  
  return (
    <a
      href={attachment.external_url}
      target="_blank"
      rel="noopener noreferrer"
      className="flex items-center gap-2 px-3 py-2 bg-white rounded border hover:bg-gray-50 transition-colors"
    >
      <FileText size={16} />
      <span className="text-sm">{isPdf ? 'PDF' : 'Documento'}</span>
      <ExternalLink size={14} className="ml-auto" />
    </a>
  )
}
```

---

## 🔧 Funções Helper

### Identificador do Cliente por Canal
```typescript
const getCustomerIdentifier = (conversation: Conversation): string => {
  const { channel_type, channel_specific_data } = conversation
  
  switch (channel_type) {
    case 'whatsapp':
      return channel_specific_data.customer_phone || 'Sem telefone'
    case 'instagram':
      return channel_specific_data.instagram_username || 'Sem username'
    case 'webchat':
      return channel_specific_data.visitor_name || 'Visitante'
    case 'email':
      return channel_specific_data.email_address || 'Sem email'
    default:
      return 'Desconhecido'
  }
}
```

### Suporte de Mídia por Canal
```typescript
const getChannelMediaSupport = (channel: ChannelType) => {
  const support = {
    whatsapp: {
      images: true,
      audio: true,
      video: true,
      documents: true,
      maxFileSize: '16MB'
    },
    instagram: {
      images: true,
      audio: false, // ❌ Instagram não suporta áudio
      video: true,
      documents: false,
      maxFileSize: '8MB'
    },
    webchat: {
      images: true,
      audio: false,
      video: false,
      documents: true,
      maxFileSize: '10MB'
    },
    email: {
      images: true,
      audio: true,
      video: true,
      documents: true,
      maxFileSize: '25MB'
    }
  }
  
  return support[channel]
}
```

### Verificar se Canal Suporta Real-time
```typescript
const supportsRealtime = (channel: ChannelType): boolean => {
  return channel !== 'email' // Email é assíncrono
}
```

---

## 🎯 Fluxo de Takeover/Release

### 1. Takeover (Assumir Controle)
```typescript
const handleTakeover = async () => {
  const { data: userData } = await supabase
    .from('dashboard_users')
    .select('full_name')
    .eq('id', user.id)
    .single()

  const { data, error } = await supabase.rpc('takeover_conversation', {
    p_conversation_uuid: conversation.id,
    p_user_name: userData.full_name
  })

  if (error) {
    toast.error('Erro ao assumir conversa')
    return
  }

  toast.success('Você assumiu o controle!')
  // O real-time vai atualizar o status automaticamente
}
```

### 2. Release (Liberar para IA)
```typescript
const handleRelease = async () => {
  const { data, error } = await supabase.rpc('release_conversation', {
    p_conversation_uuid: conversation.id
  })

  if (error) {
    toast.error('Erro ao liberar conversa')
    return
  }

  toast.success('Conversa liberada para IA!')
  // O real-time vai atualizar o status automaticamente
}
```

---

## ✅ Checklist de Implementação

### Página de Conversa
- [ ] Rota `/conversations/:id` funcionando
- [ ] Header com nome do cliente, identificador do canal, badges
- [ ] Botão "Voltar" navegando para dashboard
- [ ] Botão "Takeover" visível apenas se status = 'active'
- [ ] Botão "Release" visível apenas se status = 'human_takeover'

### Mensagens
- [ ] Listagem de mensagens carregada via `get_conversation_detail()`
- [ ] MessageBubble com estilos diferentes para customer/assistant/agent/system
- [ ] Scroll automático para última mensagem
- [ ] Exibição de anexos (imagens, documentos)
- [ ] Timestamp formatado (HH:mm)

### Input de Mensagem
- [ ] Campo de texto desabilitado se status ≠ 'human_takeover'
- [ ] Botão enviar chama `send_human_message()`
- [ ] Após enviar, chama webhook n8n (WF2-send-from-dashboard)
- [ ] Botão de anexo visível apenas se canal suporta mídia
- [ ] Tooltip mostrando restrições do canal (Instagram sem áudio, etc.)

### Real-time
- [ ] Subscription em `conversation_memory` (INSERT) para novas mensagens
- [ ] Subscription em `conversations` (UPDATE) para mudanças de status
- [ ] Notificação toast quando takeover bem-sucedido
- [ ] Notificação toast quando release bem-sucedido
- [ ] Cleanup do canal ao desmontar componente

### Takeover/Release
- [ ] `takeover_conversation()` muda status para 'human_takeover'
- [ ] `release_conversation()` muda status para 'active'
- [ ] UI atualiza automaticamente via real-time
- [ ] Nome do agente salvo em `taken_over_by_name`

### UI Adaptativa por Canal
- [ ] Instagram: botão de áudio desabilitado com tooltip
- [ ] Email: aviso de não ter real-time (recarregar manualmente)
- [ ] WebChat: restrições de mídia aplicadas
- [ ] WhatsApp: todos os recursos disponíveis

---

## 🚀 Próximos Passos

Após concluir este prompt, você estará pronto para o **Prompt 4** que inclui:
- Envio de mídia (upload para Supabase Storage)
- Preview de anexos (imagens, PDFs)
- Export de conversa para PDF
- Analytics avançados
- Filtros por data e busca de mensagens
- Integração completa com webhook n8n

---

## 📝 Notas Importantes

1. **Segurança:** O RPC `send_human_message()` já valida permissões via `auth.uid()`
2. **Real-time:** Apenas canais WhatsApp, Instagram e WebChat têm atualizações instantâneas
3. **Webhook:** Sempre enviar `channel_type` e `channel_specific_data` para n8n processar corretamente
4. **Status:** Após takeover, status muda para 'human_takeover' e IA para de responder
5. **Release:** Após release, status volta para 'active' e IA volta a responder

---

**Testado com:**
- Email: teste@evolutedigital.com.br
- Senha: Teste@2024!
- Client ID: clinica_sorriso_001

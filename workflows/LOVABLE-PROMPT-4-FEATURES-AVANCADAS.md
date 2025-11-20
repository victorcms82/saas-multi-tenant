# Prompt 4: Features Avançadas e Webhook Integration

## ✅ Pré-requisitos
- **Prompt 1 completo:** Layout, sidebar, autenticação
- **Prompt 2 completo:** Dashboard, métricas, lista de conversas
- **Prompt 3 completo:** Chat interface, takeover/release, mensagens

## 🎯 Objetivo
Adicionar funcionalidades avançadas: envio de mídia por canal, upload para Supabase Storage, integração completa com webhook n8n, export de conversas, analytics detalhados, e UI adaptativa para restrições de cada canal.

---

## 📦 Dependências Necessárias

**Instalar via npm:**

```bash
npm install jspdf recharts sonner
```

- **jspdf:** Geração de PDFs
- **recharts:** Gráficos de analytics
- **sonner:** Notificações toast

**Importações necessárias:**

```typescript
import jsPDF from 'jspdf'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { toast } from 'sonner'
```

---

## 📋 Contexto Técnico

### ⚠️ PRÉ-REQUISITO: Criar Bucket no Supabase

**IMPORTANTE:** Antes de implementar upload, criar o bucket manualmente:

1. Acessar Supabase Dashboard → Storage
2. Clicar em "New bucket"
3. Nome: `conversation-attachments`
4. Public bucket: ✅ Marcar (para permitir leitura pública)
5. Aplicar políticas SQL:

```sql
-- Política 1: Leitura pública
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'conversation-attachments');

-- Política 2: Upload apenas authenticated
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'conversation-attachments' 
  AND auth.role() = 'authenticated'
);

-- Política 3: Delete apenas próprios arquivos
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'conversation-attachments' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Supabase Storage
- **Bucket:** `conversation-attachments`
- **Política:** Public read, authenticated write
- **Upload:** Via `supabase.storage.from('conversation-attachments').upload()`

### Webhook n8n
- **URL:** `https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard`
- **Método:** POST
- **Headers:** `{ 'Content-Type': 'application/json' }`
- **Payload:**
```typescript
{
  chatwoot_conversation_id: number,
  channel_type: ChannelType,
  channel_specific_data: ChannelSpecificData,
  message: string,
  media_url?: string,
  media_type?: string // 'image' | 'audio' | 'video' | 'document'
}
```

### RPCs Adicionais
```typescript
// Obter estatísticas detalhadas
supabase.rpc('get_dashboard_stats', {
  p_client_id: 'clinica_sorriso_001'
})
// Retorna: total_conversations_today, conversations_handled_by_ai, 
//          ai_resolution_rate, average_response_time, etc.
```

---

## 📤 Upload de Mídia

### Componente MediaUploader
```tsx
const MediaUploader = ({ 
  conversation, 
  onUploadSuccess 
}: { 
  conversation: Conversation
  onUploadSuccess: (url: string, type: string) => void 
}) => {
  const [isUploading, setIsUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  
  const mediaSupport = getChannelMediaSupport(conversation.channel_type)

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    // Validar tipo de arquivo
    const fileType = file.type.split('/')[0] // 'image', 'audio', 'video', 'application'
    
    if (fileType === 'image' && !mediaSupport.images) {
      toast.error('Este canal não suporta imagens')
      return
    }
    if (fileType === 'audio' && !mediaSupport.audio) {
      toast.error(`${conversation.channel_type.toUpperCase()} não suporta áudio`)
      return
    }
    if (fileType === 'video' && !mediaSupport.video) {
      toast.error('Este canal não suporta vídeos')
      return
    }

    // Validar tamanho
    const maxSize = parseFileSize(mediaSupport.maxFileSize)
    if (file.size > maxSize) {
      toast.error(`Arquivo maior que ${mediaSupport.maxFileSize}`)
      return
    }

    setIsUploading(true)

    try {
      // Upload para Supabase Storage
      const fileName = `${conversation.id}/${Date.now()}_${file.name}`
      const { data, error } = await supabase.storage
        .from('conversation-attachments')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (error) throw error

      // Obter URL pública
      const { data: urlData } = supabase.storage
        .from('conversation-attachments')
        .getPublicUrl(fileName)

      onUploadSuccess(urlData.publicUrl, fileType)
      toast.success('Arquivo enviado com sucesso!')

    } catch (error) {
      console.error('Erro no upload:', error)
      toast.error('Erro ao enviar arquivo')
    } finally {
      setIsUploading(false)
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  return (
    <>
      <input
        ref={fileInputRef}
        type="file"
        className="hidden"
        onChange={handleFileSelect}
        accept={getAcceptedFileTypes(mediaSupport)}
        disabled={isUploading}
      />
      
      <button
        onClick={() => fileInputRef.current?.click()}
        disabled={isUploading || !mediaSupport.images}
        className="p-2 text-gray-600 hover:text-gray-900 disabled:opacity-50"
        title={!mediaSupport.images ? 'Canal não suporta mídia' : 'Anexar arquivo'}
      >
        {isUploading ? (
          <Loader2 size={20} className="animate-spin" />
        ) : (
          <Paperclip size={20} />
        )}
      </button>
    </>
  )
}

// Helper: Converter string de tamanho para bytes
const parseFileSize = (size: string): number => {
  const units: Record<string, number> = {
    'KB': 1024,
    'MB': 1024 * 1024,
    'GB': 1024 * 1024 * 1024
  }
  
  const match = size.match(/^(\d+)(KB|MB|GB)$/i)
  if (!match) return 0
  
  const [, value, unit] = match
  return parseInt(value) * units[unit.toUpperCase()]
}

// Helper: Tipos de arquivo aceitos
const getAcceptedFileTypes = (mediaSupport: ReturnType<typeof getChannelMediaSupport>): string => {
  const types: string[] = []
  
  if (mediaSupport.images) types.push('image/*')
  if (mediaSupport.audio) types.push('audio/*')
  if (mediaSupport.video) types.push('video/*')
  if (mediaSupport.documents) types.push('.pdf,.doc,.docx,.txt,.csv,.xlsx')
  
  return types.join(',')
}
```

### Atualizar ChatInput com Upload
```tsx
const ChatInput = ({ conversation }: { conversation: Conversation }) => {
  const [message, setMessage] = useState('')
  const [mediaUrl, setMediaUrl] = useState<string | null>(null)
  const [mediaType, setMediaType] = useState<string | null>(null)
  
  const canSendMessage = conversation.status === 'human_takeover'

  const handleMediaUpload = (url: string, type: string) => {
    setMediaUrl(url)
    setMediaType(type)
  }

  const handleSend = async () => {
    if ((!message.trim() && !mediaUrl) || !canSendMessage) return

    // 1. Salvar mensagem no banco via RPC
    const { data, error } = await supabase.rpc('send_human_message', {
      p_conversation_uuid: conversation.id,
      p_message_content: message || '📎 Anexo enviado',
      p_media_url: mediaUrl
    })

    if (error) {
      toast.error('Erro ao enviar mensagem')
      return
    }

    // 2. Enviar via webhook n8n para Chatwoot
    try {
      const response = await fetch('https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chatwoot_conversation_id: conversation.chatwoot_conversation_id,
          channel_type: conversation.channel_type,
          channel_specific_data: conversation.channel_specific_data,
          message: message || '📎 Anexo enviado',
          media_url: mediaUrl,
          media_type: mediaType
        })
      })

      if (!response.ok) throw new Error('Webhook failed')
      
      toast.success('Mensagem enviada!')
    } catch (error) {
      console.error('Erro no webhook:', error)
      toast.error('Erro ao enviar para o canal')
    }

    // Limpar campos
    setMessage('')
    setMediaUrl(null)
    setMediaType(null)
  }

  return (
    <div className="border-t bg-white p-4">
      {!canSendMessage && (
        <div className="mb-2 text-sm text-yellow-700 bg-yellow-50 p-2 rounded">
          ⚠️ Você precisa assumir a conversa para enviar mensagens
        </div>
      )}

      {/* Preview de mídia anexada */}
      {mediaUrl && (
        <div className="mb-2 p-2 bg-gray-100 rounded flex items-center justify-between">
          <div className="flex items-center gap-2">
            {mediaType === 'image' && <ImageIcon size={16} />}
            {mediaType === 'audio' && <Music size={16} />}
            {mediaType === 'video' && <Video size={16} />}
            {mediaType === 'application' && <FileText size={16} />}
            <span className="text-sm text-gray-700">Arquivo anexado</span>
          </div>
          <button onClick={() => setMediaUrl(null)} className="text-red-600 hover:text-red-800">
            <X size={16} />
          </button>
        </div>
      )}

      <div className="flex items-center gap-2">
        {/* Botão de anexo */}
        <MediaUploader 
          conversation={conversation} 
          onUploadSuccess={handleMediaUpload}
        />

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
          disabled={(!message.trim() && !mediaUrl) || !canSendMessage}
          className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50"
        >
          <Send size={20} />
        </button>
      </div>

      {/* Avisos de restrições */}
      {conversation.channel_type === 'instagram' && (
        <p className="text-xs text-gray-500 mt-2">
          ℹ️ Instagram: Apenas imagens e vídeos. Máx: 8MB
        </p>
      )}
      {conversation.channel_type === 'webchat' && (
        <p className="text-xs text-gray-500 mt-2">
          ℹ️ WebChat: Imagens e documentos. Máx: 10MB
        </p>
      )}
    </div>
  )
}
```

---

## 📊 Analytics Avançados

### Página de Analytics
```tsx
// Nova rota: /analytics
const AnalyticsPage = () => {
  const [stats, setStats] = useState<any>(null)
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 dias atrás
    end: new Date()
  })

  useEffect(() => {
    loadStats()
  }, [dateRange])

  const loadStats = async () => {
    const { data: userData } = await supabase
      .from('dashboard_users')
      .select('client_id')
      .eq('id', user.id)
      .single()

    const { data } = await supabase.rpc('get_dashboard_stats', {
      p_client_id: userData.client_id
    })

    setStats(data)
  }

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-2xl font-bold">Analytics</h1>

      {/* Date Range Picker */}
      <div className="flex gap-4">
        <input
          type="date"
          value={dateRange.start.toISOString().split('T')[0]}
          onChange={(e) => setDateRange({ ...dateRange, start: new Date(e.target.value) })}
          className="px-4 py-2 border rounded-lg"
        />
        <span className="self-center">até</span>
        <input
          type="date"
          value={dateRange.end.toISOString().split('T')[0]}
          onChange={(e) => setDateRange({ ...dateRange, end: new Date(e.target.value) })}
          className="px-4 py-2 border rounded-lg"
        />
      </div>

      {/* Métricas Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <MetricCard
          title="Conversas Totais"
          value={stats?.total_conversations_today || 0}
          icon={<MessageSquare />}
          color="blue"
        />
        <MetricCard
          title="Resolvidas por IA"
          value={stats?.conversations_handled_by_ai || 0}
          icon={<Bot />}
          color="green"
        />
        <MetricCard
          title="Taxa de Resolução IA"
          value={`${stats?.ai_resolution_rate || 0}%`}
          icon={<TrendingUp />}
          color="purple"
        />
        <MetricCard
          title="Tempo Médio Resposta"
          value={`${stats?.average_response_time || 0}s`}
          icon={<Clock />}
          color="orange"
        />
      </div>

      {/* Gráfico de conversas por canal */}
      <div className="bg-white p-6 rounded-lg shadow">
        <h2 className="text-lg font-semibold mb-4">Conversas por Canal</h2>
        <ChannelDistributionChart data={stats} />
      </div>
    </div>
  )
}

// 📊 Componente: ChannelDistributionChart
const ChannelDistributionChart = ({ data }: { data: any }) => {
  const chartData = [
    { channel: 'WhatsApp', count: data?.whatsapp_count || 0, fill: '#10b981' },
    { channel: 'Instagram', count: data?.instagram_count || 0, fill: '#ec4899' },
    { channel: 'WebChat', count: data?.webchat_count || 0, fill: '#3b82f6' },
    { channel: 'Email', count: data?.email_count || 0, fill: '#6b7280' }
  ]
  
  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="channel" />
        <YAxis />
        <Tooltip />
        <Bar dataKey="count" fill="#667eea" />
      </BarChart>
    </ResponsiveContainer>
  )
}
    </div>
  )
}
```

---

## 📥 Export de Conversa para PDF

### Botão Export no Header do Chat
```tsx
const ChatHeader = ({ conversation }: { conversation: Conversation }) => {
  const handleExportPDF = async () => {
    toast.info('Gerando PDF...')

    // Buscar todas as mensagens
    const { data } = await supabase.rpc('get_conversation_detail', {
      p_conversation_uuid: conversation.id
    })

    if (!data) return

    // Gerar PDF (pode usar biblioteca como jsPDF ou react-pdf)
    const pdf = generateConversationPDF(data.conversation, data.messages)
    pdf.save(`conversa_${conversation.customer_name}_${Date.now()}.pdf`)

    toast.success('PDF gerado com sucesso!')
  }

  return (
    <div className="flex items-center justify-between p-4 border-b bg-white">
      {/* ... resto do header ... */}

      <div className="flex items-center gap-2">
        {/* Botão Export */}
        <button
          onClick={handleExportPDF}
          className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
          title="Exportar conversa para PDF"
        >
          <Download size={20} />
        </button>

        {/* ... botões takeover/release ... */}
      </div>
    </div>
  )
}

// Função para gerar PDF (exemplo simplificado)
const generateConversationPDF = (conversation: Conversation, messages: Message[]) => {
  // Implementar usando jsPDF ou react-pdf
  // Incluir:
  // - Cabeçalho com logo e info do cliente
  // - Dados da conversa (cliente, canal, status, datas)
  // - Timeline de mensagens
  // - Rodapé com data de geração
  
  // Exemplo básico:
  const doc = new jsPDF()
  
  doc.setFontSize(16)
  doc.text('Histórico de Conversa', 10, 10)
  
  doc.setFontSize(12)
  doc.text(`Cliente: ${conversation.customer_name}`, 10, 20)
  doc.text(`Canal: ${conversation.channel_type.toUpperCase()}`, 10, 30)
  doc.text(`Status: ${conversation.status}`, 10, 40)
  
  let y = 60
  messages.forEach((msg, idx) => {
    doc.setFontSize(10)
    doc.text(`[${msg.timestamp}] ${msg.sender_name || msg.role}: ${msg.content}`, 10, y)
    y += 10
    
    if (y > 280) { // Nova página
      doc.addPage()
      y = 10
    }
  })
  
  return doc
}
```

---

## 🔍 Busca Avançada de Conversas

### Adicionar Campo de Busca no Dashboard
```tsx
const Dashboard = () => {
  const [searchTerm, setSearchTerm] = useState('')
  const [conversations, setConversations] = useState<Conversation[]>([])

  const handleSearch = async () => {
    if (!searchTerm.trim()) {
      loadConversations() // Recarregar lista completa
      return
    }

    // Buscar no banco (pode criar RPC específico ou filtrar no frontend)
    const filtered = conversations.filter(conv =>
      conv.customer_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      conv.customer_phone.includes(searchTerm) ||
      getCustomerIdentifier(conv).toLowerCase().includes(searchTerm.toLowerCase())
    )

    setConversations(filtered)
  }

  return (
    <div className="p-6">
      {/* Campo de busca */}
      <div className="mb-6 flex gap-2">
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          placeholder="Buscar por nome, telefone, email..."
          className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
        <button
          onClick={handleSearch}
          className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
        >
          <Search size={20} />
        </button>
      </div>

      {/* ... resto do dashboard ... */}
    </div>
  )
}
```

---

## 🎨 UI Adaptativa - Tooltips e Restrições

### Componente ChannelRestrictionTooltip
```tsx
const ChannelRestrictionTooltip = ({ 
  channel, 
  featureType 
}: { 
  channel: ChannelType
  featureType: 'audio' | 'video' | 'document' | 'realtime'
}) => {
  const restrictions: Record<ChannelType, Record<string, string | null>> = {
    whatsapp: {
      audio: null, // Sem restrição
      video: null,
      document: null,
      realtime: null
    },
    instagram: {
      audio: '❌ Instagram não suporta mensagens de áudio',
      video: null,
      document: '❌ Instagram não suporta documentos',
      realtime: null
    },
    webchat: {
      audio: '❌ WebChat não suporta áudio',
      video: '❌ WebChat não suporta vídeos',
      document: null,
      realtime: null
    },
    email: {
      audio: null,
      video: null,
      document: null,
      realtime: '⚠️ Email não tem atualizações em tempo real. Recarregue a página.'
    }
  }

  const message = restrictions[channel][featureType]
  
  if (!message) return null

  return (
    <div className="absolute -top-12 left-0 bg-gray-800 text-white text-xs px-3 py-2 rounded shadow-lg whitespace-nowrap z-10">
      {message}
    </div>
  )
}
```

### Aplicar no ChatInput
```tsx
<div className="relative">
  <button
    disabled={!mediaSupport.audio}
    className="p-2 text-gray-600 hover:text-gray-900 disabled:opacity-50 disabled:cursor-not-allowed"
    title="Enviar áudio"
  >
    <Mic size={20} />
  </button>
  
  {!mediaSupport.audio && (
    <ChannelRestrictionTooltip channel={conversation.channel_type} featureType="audio" />
  )}
</div>
```

---

## 🔔 Notificações Toast

### Setup com Sonner
```tsx
// Em _app.tsx ou layout principal
import { Toaster } from 'sonner'

export default function App() {
  return (
    <>
      <Toaster position="top-right" richColors />
      {/* ... resto da aplicação ... */}
    </>
  )
}

// Uso nos componentes:
import { toast } from 'sonner'

toast.success('Mensagem enviada!')
toast.error('Erro ao enviar mensagem')
toast.info('Processando...')
toast.warning('Atenção: Canal não suporta este tipo de arquivo')
```

---

## ✅ Checklist de Implementação

### Upload de Mídia
- [ ] MediaUploader component funcionando
- [ ] Upload para Supabase Storage (bucket: conversation-attachments)
- [ ] Validação de tipo de arquivo por canal
- [ ] Validação de tamanho máximo por canal
- [ ] Preview de arquivo anexado antes de enviar
- [ ] Loader durante upload
- [ ] Error handling com toast

### Webhook Integration
- [ ] Envio para n8n após `send_human_message()`
- [ ] Payload incluindo `channel_type` e `channel_specific_data`
- [ ] Envio de `media_url` e `media_type` quando houver anexo
- [ ] Retry logic em caso de falha do webhook
- [ ] Toast de sucesso/erro após webhook

### Analytics
- [ ] Página `/analytics` com métricas detalhadas
- [ ] Date range picker funcional
- [ ] Gráfico de conversas por canal
- [ ] Gráfico de taxa de resolução ao longo do tempo
- [ ] Integração com `get_dashboard_stats()`

### Export PDF
- [ ] Botão "Export" no header do chat
- [ ] Geração de PDF com jsPDF ou react-pdf
- [ ] PDF inclui: cabeçalho, dados da conversa, timeline de mensagens
- [ ] Download automático após geração
- [ ] Toast de feedback

### Busca Avançada
- [ ] Campo de busca no dashboard
- [ ] Buscar por: nome, telefone, email, username do Instagram
- [ ] Enter para buscar
- [ ] Botão limpar busca
- [ ] Feedback visual (sem resultados)

### UI Adaptativa
- [ ] Tooltips mostrando restrições por canal
- [ ] Botões desabilitados para recursos não suportados
- [ ] Aviso de email não ter real-time
- [ ] Aviso de Instagram não ter áudio
- [ ] Cores e ícones distintos por canal

### Notificações
- [ ] Toast de sucesso ao enviar mensagem
- [ ] Toast de erro ao falhar upload
- [ ] Toast de aviso ao violar restrição de canal
- [ ] Toast de info durante processamento
- [ ] Posição: top-right, cores: richColors

---

## 🚀 Deploy e Próximos Passos

### Validação Final
1. Testar envio de mensagem em todos os 4 canais
2. Validar upload de cada tipo de mídia
3. Confirmar webhook recebe dados corretos no n8n
4. Verificar real-time funcionando (exceto email)
5. Testar export PDF com conversa longa
6. Validar analytics com dados reais
7. Testar busca com diferentes termos
8. Confirmar tooltips aparecem corretamente

### Otimizações Futuras
- [ ] Cache de conversas no frontend (React Query)
- [ ] Pagination para conversas antigas
- [ ] Compressão de imagens antes do upload
- [ ] Preview de PDFs e documentos inline
- [ ] Suporte a emojis e GIFs
- [ ] Templates de mensagens rápidas
- [ ] Atalhos de teclado (Ctrl+Enter para enviar)
- [ ] Dark mode

---

## 📝 Notas Finais

### Limitações Conhecidas
- **Instagram:** Não suporta áudio nem documentos (limitação da API do Meta)
- **Email:** Não tem real-time (protocolo SMTP/IMAP é assíncrono)
- **WebChat:** Limitações dependem da implementação do widget

### Segurança
- RLS habilitado em todas as tabelas
- Validação de `auth.uid()` em todas as RPCs
- Storage bucket com política public-read, authenticated-write
- Webhook n8n validando origem das requests

### Performance
- Índices criados em `channel_type` e `client_id`
- GIN index em `channel_specific_data` para queries JSON
- Real-time subscriptions otimizadas por conversa

### Suporte
- Docs: https://docs.lovable.dev/
- Supabase: https://supabase.com/docs
- n8n: https://docs.n8n.io/

---

**Testado com:**
- Email: teste@evolutedigital.com.br
- Senha: Teste@2024!
- Client ID: clinica_sorriso_001
- Bucket: conversation-attachments
- Webhook: https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard

---

## 🎉 Conclusão

Após implementar este Prompt 4, você terá um dashboard completo e funcional com:
- ✅ Autenticação e layout profissional
- ✅ Dashboard com métricas em tempo real
- ✅ Lista de conversas com filtro multi-canal
- ✅ Chat interface estilo WhatsApp Web
- ✅ Takeover/release de conversas
- ✅ Envio de mensagens e mídias
- ✅ Real-time via Supabase subscriptions
- ✅ Integração completa com webhook n8n
- ✅ Analytics detalhados
- ✅ Export para PDF
- ✅ Busca avançada
- ✅ UI adaptativa por canal

**Pronto para produção! 🚀**

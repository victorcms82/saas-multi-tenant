# Prompt para Lovable - Dashboard Digitai.app

## ⚠️ INFORMAÇÕES CRÍTICAS - LEIA PRIMEIRO

**DATABASE JÁ CONFIGURADO:**
- ✅ Migration 022 executada no Supabase (baseline)
- ✅ Migration 023 executada (🆕 Multi-Channel Support)
- ✅ Migration 024 executada (🆕 Security Definer Search Path Fix)
- ✅ Tabelas criadas: `conversations`, `dashboard_users`, `conversation_memory`
- ✅ 7 funções RPC prontas para uso (assinaturas atualizadas!)
- ✅ RLS configurado e ativo
- ✅ Usuário de teste criado: `teste@evolutedigital.com.br` / `Teste@2024!`

**USAR APENAS FUNÇÕES RPC (NÃO queries diretas):**
- `get_conversations_list(p_client_id, p_status_filter, p_channel_filter, p_limit, p_offset)` - Listar conversas 🆕 com filtro por canal
- `get_conversation_detail(p_conversation_uuid)` - Detalhes + mensagens 🆕 retorna channel_type e channel_specific_data
- `takeover_conversation(p_conversation_uuid, p_user_name)` - Assumir conversa
- `release_conversation(p_conversation_uuid)` - Devolver para IA
- `send_human_message(p_conversation_uuid, p_message_content, p_media_url)` - Enviar mensagem como humano
- `get_dashboard_stats(p_client_id)` - Métricas
- `sync_conversation_from_chatwoot(...)` - Sync (usado pelo n8n) 🆕 com 2 params opcionais

**⚠️ EXCEÇÃO RPC:** Tabela `dashboard_users` pode usar query SELECT direta (tabela auxiliar, não sensível).

**🆕 MULTI-CANAL SUPORTADO (Migration 023):**
- 📱 WhatsApp (channel_type: 'whatsapp')
- 📷 Instagram DM (channel_type: 'instagram')
- 💬 WebChat (channel_type: 'webchat')
- 📧 Email (channel_type: 'email')

**🆕 CAMPOS ADICIONADOS (Migration 023):**
- `conversations.channel_type` - ENUM NOT NULL (whatsapp, instagram, webchat, email)
- `conversations.channel_specific_data` - JSONB NOT NULL (dados específicos do canal)
- 3 índices criados para performance (B-tree, Composite, GIN)

**WEBHOOK PARA ENVIO:**
- URL: `https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard`
- Usar APÓS `send_human_message()` RPC para enviar via Evolution API

**CREDENCIAIS SUPABASE:**
- URL: `https://vnlfgnfaortdvmraoapq.supabase.co`
- Anon Key: (pegar do Supabase Dashboard → Settings → API)

---

## 🎯 Visão Geral do Projeto

Criar um dashboard web para clientes monitorarem conversas de chatbot IA no WhatsApp. O cliente visualiza conversas em tempo real, pode assumir o atendimento quando necessário, e vê métricas básicas de performance.

---

## 🎨 Design e Identidade Visual

### Paleta de Cores
```
Primary (Roxo Tech): #667eea
Primary Dark: #5568d3
Primary Light: #7c8df5

Accent (Verde Sucesso): #10b981
Warning (Amarelo): #f59e0b
Danger (Vermelho): #ef4444

Backgrounds:
- Main: #ffffff
- Secondary: #f9fafb
- Sidebar: #1f2937

Text:
- Dark: #1f2937
- Medium: #6b7280
- Light: #9ca3af
```

### Tipografia
- Headings: **Inter Bold** (700)
- Body: **Inter Regular** (400, 500)
- Tamanhos: 12px, 14px, 16px, 20px, 24px

### Ícones
Usar **Lucide React** para todos os ícones

---

## 📱 Estrutura de Páginas

### 1. Página de Login (`/login`)

**Layout: Split Screen (50/50)**

#### Lado Esquerdo (Visual)
- Fundo: Gradiente linear `from-[#667eea] to-[#764ba2]`
- Logo "Digitai.app" (branco, topo esquerdo)
- Título: "Seu Assistente IA Trabalhando 24/7"
- Subtítulo: "Dashboard personalizado para seu negócio"
- Lista de features com ícones:
  - 💬 Conversas em tempo real
  - 📊 Analytics inteligentes
  - 🤖 IA treinada no seu negócio
  - 📸 Geração de imagens e documentos
- Imagem/Screenshot do dashboard (mock ou placeholder)

#### Lado Direito (Formulário)
- Fundo branco
- Título: "Área do Cliente"
- Formulário:
  - Campo Email (com ícone 📧)
  - Campo Senha (com ícone 🔒 e toggle para mostrar/ocultar)
  - Checkbox "Lembrar de mim"
  - Botão "Entrar" (roxo, fullwidth)
  - Link "Esqueceu sua senha?" (centralizado, abaixo)
- Divider com texto "ou"
- Texto: "Precisa de acesso?"
- Link: "Solicitar demonstração →" (redireciona para evolute.chat)

**Validações:**
- Email: formato válido
- Senha: mínimo 8 caracteres
- Mensagens de erro em vermelho abaixo dos campos
- Loading state no botão ao submeter

**Responsivo:**
- Desktop: Split 50/50
- Tablet/Mobile: Stacked (formulário acima, visual embaixo ou oculto)

---

### 2. Dashboard Principal (`/`)

**Layout: Sidebar + Content**

#### Sidebar (fixa, esquerda)
```
┌─────────────────┐
│  [Logo]         │
├─────────────────┤
│  💬 Conversas   │ ← ativo
│  📊 Resumo      │
│  ⚙️ Configurações│
│  ❓ Suporte     │
├─────────────────┤
│  👤 [Nome]      │
│  🚪 Sair        │
└─────────────────┘
```

**Largura:** 240px
**Fundo:** #1f2937 (cinza escuro)
**Texto:** Branco/cinza claro
**Item ativo:** Fundo #667eea

#### Header (topo, fixo)
- Logo do cliente (se tiver) ou nome
- Breadcrumb/Título da página
- Avatar + Nome do usuário logado (dropdown)
  - Meu perfil
  - Alterar senha
  - Sair

#### Content Area

**Cards de Resumo (topo, grid 4 colunas)**
```jsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
  <MetricCard
    title="Conversas Hoje"
    value="42"
    icon={MessageCircle}
    color="blue"
  />
  <MetricCard
    title="Resolvidas pela IA"
    value="38"
    subtitle="90%"
    icon={Bot}
    color="green"
  />
  <MetricCard
    title="Ativas Agora"
    value="4"
    icon={Activity}
    color="yellow"
  />
  <MetricCard
    title="Taxa Sucesso IA"
    value="95%"
    icon={TrendingUp}
    color="purple"
  />
</div>
```

**Lista de Conversas (abaixo dos cards)**

Título: "💬 Conversas em Tempo Real"

**Filtros Multi-Canal (Tabs):**
```jsx
<Tabs defaultValue="all" className="mb-4">
  <TabsList>
    <TabsTrigger value="all">Todos</TabsTrigger>
    <TabsTrigger value="whatsapp">📱 WhatsApp</TabsTrigger>
    <TabsTrigger value="instagram">📷 Instagram</TabsTrigger>
    <TabsTrigger value="webchat">💬 WebChat</TabsTrigger>
    <TabsTrigger value="email">📧 Email</TabsTrigger>
  </TabsList>
</Tabs>
```

Tabela/Cards de conversas:
```jsx
<ConversationItem
  channelType="whatsapp"  // 🆕 whatsapp, instagram, webchat, email
  channelIcon={<MessageCircle />}  // Ícone dinâmico por canal
  channelBadge={<ChannelBadge channel="whatsapp" />}  // 🆕 Badge visual do canal
  status="active"      // active, needs_human, resolved
  customerName="Maria Silva"
  customerIdentifier="11 98765-4321"  // 🆕 phone, @username, email, visitor_name
  lastMessage="Preciso remarcar consulta"
  timestamp="há 2 min"
  unreadCount={1}
  actions={
    <div>
      <Button variant="outline" size="sm">Ver conversa</Button>
      <Button variant="default" size="sm">Assumir</Button>
    </div>
  }
/>
```

**🆕 Exemplo Completo de ConversationList com Multi-Canal:**
```tsx
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { MessageCircle, Instagram, Globe, Mail } from 'lucide-react'

type ChannelType = 'whatsapp' | 'instagram' | 'webchat' | 'email'

const ConversationList = ({ clientId }: { clientId: string }) => {
  const [conversations, setConversations] = useState([])
  const [activeChannel, setActiveChannel] = useState<ChannelType | null>(null)
  
  const fetchConversations = async (channelFilter: ChannelType | null) => {
    const { data } = await supabase.rpc('get_conversations_list', {
      p_client_id: clientId,
      p_status_filter: null,
      p_channel_filter: channelFilter, // 🆕 Filtro por canal
      p_limit: 50,
      p_offset: 0
    })
    setConversations(data || [])
  }
  
  useEffect(() => {
    fetchConversations(activeChannel)
  }, [activeChannel])
  
  const channelIcons = {
    whatsapp: <MessageCircle className="w-4 h-4 text-green-500" />,
    instagram: <Instagram className="w-4 h-4 text-pink-500" />,
    webchat: <Globe className="w-4 h-4 text-blue-500" />,
    email: <Mail className="w-4 h-4 text-gray-500" />
  }
  
  return (
    <div className="space-y-4">
      <Tabs defaultValue="all" onValueChange={(v) => setActiveChannel(v === 'all' ? null : v as ChannelType)}>
        <TabsList>
          <TabsTrigger value="all">Todos</TabsTrigger>
          <TabsTrigger value="whatsapp">📱 WhatsApp</TabsTrigger>
          <TabsTrigger value="instagram">📷 Instagram</TabsTrigger>
          <TabsTrigger value="webchat">💬 WebChat</TabsTrigger>
          <TabsTrigger value="email">📧 Email</TabsTrigger>
        </TabsList>
      </Tabs>
      
      <div className="space-y-2">
        {conversations.map((conv) => (
          <ConversationCard 
            key={conv.id} 
            conversation={conv}
            icon={channelIcons[conv.channel_type]}
          />
        ))}
      </div>
    </div>
  )
}
```

**Ícones por Canal:**
```typescript
const channelIcons = {
  whatsapp: <MessageCircle className="text-green-500" />,
  instagram: <Instagram className="text-pink-500" />,
  webchat: <Globe className="text-blue-500" />,
  email: <Mail className="text-gray-500" />
}

const channelLabels = {
  whatsapp: 'WhatsApp',
  instagram: 'Instagram DM',
  webchat: 'Chat do Site',
  email: 'Email'
}
```

**Status Visual:**
- 🟢 Verde: IA atendendo normalmente
- 🟡 Amarelo: Precisa atenção humana (badge "Aguardando você")
- 🔴 Vermelho: Humano atendendo
- ⚪ Cinza: Finalizada

**Filtros (acima da lista):**
- Tabs: Todas | Ativas | Precisa Humano | Finalizadas
- Search: Buscar por nome/telefone
- Date picker: Filtrar por data

**Paginação ou Scroll Infinito**

---

### 3. Página de Conversa Individual (`/conversations/:id`)

**Layout: Chat estilo WhatsApp Web**

#### Header da Conversa
```
┌────────────────────────────────────────────────────────┐
│ ← Voltar    📱 WhatsApp • Maria Silva • 11 98765-4321 │
│ Status: 🟢 IA Atendendo                                │
└────────────────────────────────────────────────────────┘
```

**Indicador de Canal (Badge):**
```jsx
<Badge variant={channelType === 'whatsapp' ? 'success' : 'default'}>
  {channelIcons[channelType]} {channelLabels[channelType]}
</Badge>
```

#### Área de Mensagens (scrollable, flex-grow)
```jsx
<MessageBubble
  type="customer"           // customer | agent_ai | agent_human
  content="Olá, preciso remarcar"
  timestamp="14:30"
  status="read"             // sent, delivered, read
  avatar={customerAvatar}
/>

<MessageBubble
  type="agent_ai"
  content="Claro! Qual o melhor dia para você?"
  timestamp="14:30"
  avatar={<Bot />}
  agentName="IA Recepcionista"
/>

<MessageBubble
  type="agent_human"
  content="Vou verificar isso para você"
  timestamp="14:35"
  avatar={humanAvatar}
  agentName="Dr. João"
/>
```

**Tipos de Mensagem:**
- Texto simples
- Imagem (thumbnail clicável)
- Áudio (player inline)
- Documento (link download)
- Mensagem do sistema (centralizada, estilo: "🚨 IA acionou humano - Cliente pediu atendente")

#### Alert Box (quando precisa humano)
```jsx
<Alert variant="warning" className="mb-4">
  <AlertCircle className="h-4 w-4" />
  <AlertTitle>Cliente precisa de atendimento humano</AlertTitle>
  <AlertDescription>
    A IA pausou o atendimento. Clique em "Assumir" para continuar.
  </AlertDescription>
  <div className="flex gap-2 mt-2">
    <Button onClick={handleTakeOver}>Assumir Agora</Button>
    <Button variant="outline" onClick={handleLetAIContinue}>
      IA Continuar
    </Button>
  </div>
</Alert>
```

#### Input de Mensagem (footer, fixo)
```jsx
// ⚠️ Recursos variam por canal
const channelCapabilities = {
  whatsapp: {
    text: true,
    image: true,
    audio: true,
    video: true,
    document: true,
    realtime: true
  },
  instagram: {
    text: true,
    image: true,
    audio: false, // ❌ Instagram não suporta áudio
    video: true,
    document: false, // ❌ Instagram não suporta documentos
    realtime: true
  },
  webchat: {
    text: true,
    image: true,
    audio: false,
    video: false,
    document: true,
    realtime: true
  },
  email: {
    text: true,
    image: true,
    audio: false,
    video: false,
    document: true,
    realtime: false // ⚠️ Email não tem atualização em tempo real
  }
}

const capabilities = channelCapabilities[channelType]

<div className="border-t p-4 flex items-center gap-2">
  {capabilities.image && (
    <Button variant="ghost" size="icon" title="Enviar imagem">
      <ImageIcon />
    </Button>
  )}
  {capabilities.audio && (
    <Button variant="ghost" size="icon" title="Enviar áudio">
      <Mic />
    </Button>
  )}
  {capabilities.document && (
    <Button variant="ghost" size="icon" title="Enviar documento">
      <Paperclip />
    </Button>
  )}
  
  <Input
    placeholder={
      !isHumanTakeover
        ? "IA está atendendo. Clique em Assumir para responder."
        : channelType === 'email'
        ? "Digite sua resposta (não há tempo real no email)..."
        : "Digite sua mensagem..."
    }
    disabled={!isHumanTakeover}
    className="flex-1"
  />
  
  <Button disabled={!isHumanTakeover}>
    <Send />
  </Button>
</div>

{/* Aviso para canais sem tempo real */}
{channelType === 'email' && (
  <Alert className="mt-2">
    <Info className="h-4 w-4" />
    <AlertDescription>
      Email não atualiza em tempo real. Recarregue a página para ver novas mensagens.
    </AlertDescription>
  </Alert>
)}
```

**Estado de Assumir Conversa:**
- Badge no topo: "🔴 VOCÊ ESTÁ ATENDENDO"
- Input habilitado
- Botão "Devolver para IA" visível

---

### 4. Página de Resumo/Analytics (`/resumo`)

**Cards de Métricas (período selecionável)**

```jsx
<DateRangePicker defaultValue="last_7_days" />

<StatsGrid>
  <StatCard
    title="Total de Conversas"
    value="287"
    change="+23%"
    trend="up"
  />
  <StatCard
    title="Resolvidas pela IA"
    value="259"
    percentage="90%"
  />
  <StatCard
    title="Você atendeu"
    value="28"
    percentage="10%"
  />
  <StatCard
    title="Tempo Médio Resposta"
    value="2.3 seg"
  />
  <StatCard
    title="Agendamentos Feitos"
    value="87"
  />
  <StatCard
    title="Taxa de Satisfação"
    value="4.8/5.0"
    icon={Star}
  />
</StatsGrid>
```

**Gráficos:**
```jsx
<div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
  <Card>
    <CardHeader>Conversas por Dia</CardHeader>
    <CardContent>
      <LineChart data={conversationsPerDay} />
    </CardContent>
  </Card>

  <Card>
    <CardHeader>IA vs Humano</CardHeader>
    <CardContent>
      <PieChart data={aiVsHuman} />
    </CardContent>
  </Card>

  <Card>
    <CardHeader>Horários de Pico</CardHeader>
    <CardContent>
      <BarChart data={hourlyDistribution} />
    </CardContent>
  </Card>

  <Card>
    <CardHeader>Top Tópicos</CardHeader>
    <CardContent>
      <List>
        <ListItem>Agendamento (45%)</ListItem>
        <ListItem>Preços (23%)</ListItem>
        <ListItem>Localização (15%)</ListItem>
      </List>
    </CardContent>
  </Card>
</div>
```

Usar **Recharts** ou **Chart.js** para gráficos.

---

### 5. Página de Configurações (`/configuracoes`)

**Tabs:**

#### Perfil
```jsx
<Form>
  <FormField label="Nome Completo">
    <Input defaultValue="Dr. João Silva" />
  </FormField>
  <FormField label="Email">
    <Input type="email" defaultValue="joao@clinica.com" disabled />
  </FormField>
  <FormField label="Telefone">
    <Input defaultValue="11 99999-9999" />
  </FormField>
  <Button>Salvar Alterações</Button>
</Form>
```

#### Segurança
```jsx
<Form>
  <FormField label="Senha Atual">
    <Input type="password" />
  </FormField>
  <FormField label="Nova Senha">
    <Input type="password" />
  </FormField>
  <FormField label="Confirmar Nova Senha">
    <Input type="password" />
  </FormField>
  <Button>Alterar Senha</Button>
</Form>
```

#### Notificações
```jsx
<div className="space-y-4">
  <SwitchField
    label="Notificações do navegador"
    description="Receba alertas quando cliente precisar de você"
    defaultChecked={true}
  />
  <SwitchField
    label="Som de alerta"
    description="Tocar som quando houver nova conversa urgente"
    defaultChecked={true}
  />
  <SwitchField
    label="Notificações por WhatsApp"
    description="Receber mensagens no seu WhatsApp pessoal"
    defaultChecked={false}
  />
  <SwitchField
    label="Resumo diário por email"
    description="Receber relatório das conversas do dia"
    defaultChecked={true}
  />
</div>
```

---

### 6. Página de Suporte (`/suporte`)

**Contact Cards:**
```jsx
<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
  <ContactCard
    icon={MessageCircle}
    title="WhatsApp"
    description="Suporte em tempo real"
    action="Abrir WhatsApp"
    link="https://wa.me/5511999999999"
  />
  
  <ContactCard
    icon={Mail}
    title="Email"
    description="Resposta em até 24h"
    action="Enviar Email"
    link="mailto:suporte@evolutedigital.com.br"
  />
  
  <ContactCard
    icon={FileText}
    title="Documentação"
    description="Guias e tutoriais"
    action="Ver Docs"
    link="/docs"
  />
  
  <ContactCard
    icon={Video}
    title="Vídeo Tutorial"
    description="Aprenda a usar o sistema"
    action="Assistir"
    link="https://youtube.com/..."
  />
</div>
```

**FAQ (Accordion):**
```jsx
<Accordion>
  <AccordionItem value="1">
    <AccordionTrigger>
      Como assumir uma conversa?
    </AccordionTrigger>
    <AccordionContent>
      Clique no botão "Assumir" na lista de conversas...
    </AccordionContent>
  </AccordionItem>
  
  <AccordionItem value="2">
    <AccordionTrigger>
      Como devolver conversa para IA?
    </AccordionTrigger>
    <AccordionContent>
      Dentro da conversa, clique em "Devolver para IA"...
    </AccordionContent>
  </AccordionItem>
  
  {/* Mais 3-5 perguntas frequentes */}
</Accordion>
```

---

## 🔌 Integração com Backend (Supabase)

### Autenticação
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
)

// Login
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
})

// Logout
await supabase.auth.signOut()

// Verificar sessão
const { data: { session } } = await supabase.auth.getSession()
```

### ⚠️ ESTRUTURA REAL DO BANCO DE DADOS

**IMPORTANTE:** Use estas estruturas exatas. Migration 022 já executada.

#### Tabelas Principais:

**1. `dashboard_users`** - Usuários do dashboard
```sql
id UUID (FK auth.users)
client_id TEXT
full_name TEXT
email TEXT
role TEXT ('owner' | 'admin' | 'operator' | 'viewer')
preferences JSONB
is_active BOOLEAN
created_at TIMESTAMPTZ
```

**2. `conversations`** - Metadados das conversas
```sql
id UUID
client_id TEXT
agent_id TEXT
chatwoot_conversation_id INTEGER
customer_name TEXT
customer_phone TEXT
channel_type TEXT ('whatsapp' | 'instagram' | 'webchat' | 'email') ⚠️ NOVO
channel_specific_data JSONB ⚠️ NOVO (ex: instagram_username, email_subject)
status TEXT ('active' | 'needs_human' | 'human_takeover' | 'resolved' | 'archived')
assigned_to UUID (FK auth.users)
taken_over_at TIMESTAMPTZ
taken_over_by_name TEXT
ai_paused BOOLEAN
unread_count INTEGER
last_message_content TEXT
last_message_timestamp TIMESTAMPTZ
last_message_sender TEXT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

**3. `conversation_memory`** - Mensagens
```sql
id UUID
client_id TEXT
conversation_id INTEGER (Chatwoot ID)
conversation_uuid UUID (FK conversations.id) ⚠️ NOVO
message_role TEXT ('user' | 'assistant' | 'system' | 'agent_human')
message_content TEXT
sender_name TEXT ⚠️ NOVO
has_attachments BOOLEAN
attachments JSONB -- ⚠️ SCHEMA ABAIXO
message_timestamp TIMESTAMPTZ
```

**Schema do campo `attachments` (JSONB):**
```json
[
  {
    "type": "image",
    "url": "https://storage.url/file.jpg",
    "filename": "foto.jpg",
    "mime_type": "image/jpeg",
    "size": 245678
  },
  {
    "type": "audio",
    "url": "https://storage.url/audio.ogg",
    "filename": "audio.ogg",
    "mime_type": "audio/ogg",
    "duration": 15
  },
  {
    "type": "video",
    "url": "https://storage.url/video.mp4",
    "filename": "video.mp4",
    "mime_type": "video/mp4",
    "size": 1024000
  },
  {
    "type": "document",
    "url": "https://storage.url/doc.pdf",
    "filename": "documento.pdf",
    "mime_type": "application/pdf",
    "size": 512000
  }
]
```

**⚠️ Tipos de anexo suportados:** `image`, `audio`, `video`, `document`

### Queries Principais (CORRETAS)

#### Buscar Conversas do Cliente (USAR RPC)
```typescript
// ✅ USAR FUNÇÃO RPC (mais performática e segura)
// 🆕 Migration 023: Agora suporta filtro por canal!
const { data: conversations } = await supabase
  .rpc('get_conversations_list', {
    p_client_id: 'clinica_sorriso_001', // Pegar do dashboard_users
    p_status_filter: null, // ou 'active', 'needs_human', etc
    p_channel_filter: null, // 🆕 'whatsapp' | 'instagram' | 'webchat' | 'email' | null (todos)
    p_limit: 50,
    p_offset: 0
  })

// Retorna:
// {
//   id: UUID,
//   chatwoot_conversation_id: number,
//   customer_name: string,
//   customer_phone: string,
//   channel_type: 'whatsapp' | 'instagram' | 'webchat' | 'email', // 🆕
//   channel_specific_data: JSONB, // 🆕 Dados específicos do canal
//   status: string,
//   unread_count: number,
//   last_message_content: string,
//   last_message_timestamp: timestamp,
//   last_message_sender: string,
//   assigned_to_name: string | null,
//   taken_over_at: timestamp | null,
//   created_at: timestamp,
//   updated_at: timestamp
// }
```

#### Buscar Mensagens de uma Conversa (USAR RPC)
```typescript
// ✅ USAR FUNÇÃO RPC
const { data } = await supabase
  .rpc('get_conversation_detail', {
    p_conversation_uuid: conversationId // UUID da conversa
  })

// Retorna JSON:
// {
//   conversation: { 
//     id: UUID,
//     chatwoot_conversation_id: number,
//     customer_name: string,
//     customer_phone: string,
//     channel_type: 'whatsapp' | 'instagram' | 'webchat' | 'email', // 🆕
//     channel_specific_data: JSONB, // 🆕 Dados específicos do canal
//     status: string,
//     assigned_to: UUID | null,
//     assigned_to_name: string | null,
//     taken_over_at: timestamp | null,
//     taken_over_by_name: string | null,
//     ai_paused: boolean,
//     unread_count: number,
//     created_at: timestamp,
//     updated_at: timestamp
//   },
//   messages: [
//     {
//       id: UUID,
//       role: 'user' | 'assistant' | 'agent_human' | 'system',
//       content: string,
//       timestamp: timestamp,
//       sender_name: string,
//       has_attachments: boolean,
//       attachments: array
//     }
//   ]
// }
```

#### Assumir Conversa (Takeover) - USAR RPC
```typescript
// ✅ USAR FUNÇÃO RPC
const { data, error } = await supabase
  .rpc('takeover_conversation', {
    p_conversation_uuid: conversationUUID, // UUID da conversa
    p_user_name: 'João Silva' // Nome do usuário logado
  })

// Retorna:
// {
//   success: true,
//   conversation_id: UUID,
//   status: 'human_takeover'
// }

// ⚠️ A função já:
// - Atualiza status para 'human_takeover'
// - Define assigned_to = auth.uid()
// - Pausa IA (ai_paused = true)
// - Adiciona mensagem do sistema no histórico
```

#### Enviar Mensagem (Como Humano) - USAR RPC
```typescript
// ✅ USAR FUNÇÃO RPC
const { data, error } = await supabase
  .rpc('send_human_message', {
    p_conversation_uuid: conversationUUID,
    p_message_content: messageText,
    p_media_url: mediaUrl || null // opcional
  })

// Retorna:
// {
//   success: true,
//   message_id: UUID,
//   conversation_id: UUID,
//   chatwoot_conversation_id: number
// }

// ⚠️ A função valida:
// - Conversa está em 'human_takeover'
// - Usuário logado é o assigned_to
// - Salva mensagem com role 'agent_human'
// - Atualiza last_message da conversa

// ⚠️⚠️⚠️ CRÍTICO: SEMPRE chamar webhook n8n após RPC ⚠️⚠️⚠️
// A função RPC NÃO envia a mensagem automaticamente!
// Dashboard DEVE fazer chamada explícita ao webhook:

await fetch('https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    chatwoot_conversation_id: data.chatwoot_conversation_id,
    channel_type: conversation.channel_type, // 'whatsapp', 'instagram', etc
    message: messageText,
    media_url: mediaUrl || null,
    customer_phone: conversation.customer_phone // ou instagram_username, email, etc
  })
})

// Fluxo completo:
// 1. Dashboard chama send_human_message() RPC → Salva no Supabase
// 2. Dashboard chama webhook n8n → Envia via Evolution API → WhatsApp/Instagram
// 3. Cliente recebe mensagem no canal original
```

#### Devolver para IA - USAR RPC
```typescript
// ✅ USAR FUNÇÃO RPC
const { data, error } = await supabase
  .rpc('release_conversation', {
    p_conversation_uuid: conversationUUID
  })

// Retorna:
// {
//   success: true,
//   conversation_id: UUID,
//   status: 'active'
// }

// ⚠️ A função já:
// - Muda status de volta para 'active'
// - Remove assigned_to
// - Reativa IA (ai_paused = false)
// - Adiciona mensagem do sistema
```

#### Buscar Métricas - USAR RPC
```typescript
// ✅ USAR FUNÇÃO RPC (já existe)
const { data: stats } = await supabase
  .rpc('get_dashboard_stats', {
    p_client_id: 'clinica_sorriso_001',
    p_date: '2025-11-17' // YYYY-MM-DD ou omitir (usa hoje)
  })

// Retorna JSON:
// {
//   today: {
//     total_conversations: 42,
//     active_now: 4,
//     needs_human: 2,
//     resolved_by_ai: 38,
//     human_handled: 4,
//     ai_success_rate: 95.0  // percentual
//   },
//   last_7_days: [
//     { date: '2025-11-17', conversations: 42 },
//     { date: '2025-11-16', conversations: 38 },
//     ...
//   ]
// }

// ⚠️ Usar estes dados para os MetricCards no dashboard

// ✅ Dados REAIS retornados pela função:
// - today.total_conversations
// - today.active_now
// - today.needs_human
// - today.resolved_by_ai
// - today.human_handled
// - today.ai_success_rate
// - last_7_days[].{date, conversations}

// ⚠️ Dados MOCK (implementar no futuro):
// - Top Tópicos (requer análise NLP do message_content)
// - Horários de Pico (adicionar group by hora no RPC)
// - Taxa de Satisfação (requer sistema de avaliação)
// - Tempo Médio Resposta (adicionar campo response_time)

// Por enquanto, usar placeholders para features futuras
```

#### Pegar client_id do Usuário Logado
```typescript
// ✅ BUSCAR client_id do dashboard_users
const { data: { user } } = await supabase.auth.getUser()

const { data: dashboardUser } = await supabase
  .from('dashboard_users')
  .select('client_id, full_name, role')
  .eq('id', user.id)
  .single()

// dashboardUser.client_id = 'clinica_sorriso_001'
// Usar este client_id em todas as queries RPC
```

### ⚠️ REGRA: RPC vs Query Direta

**SEMPRE usar RPC Functions EXCETO:**
- ✅ `dashboard_users`: Pode usar `.from('dashboard_users').select()` (tabela auxiliar, não tem dados sensíveis de conversas)

**NUNCA fazer query direta em:**
- ❌ `conversations` → Usar `get_conversations_list()` ou `get_conversation_detail()`
- ❌ `conversation_memory` → Usar `get_conversation_detail()`

**Por quê?** As funções RPC já incluem:
- Validação de client_id (multi-tenancy)
- Joins otimizados
- Contagem de unread_count
- Performance (índices corretos)
- Segurança RLS

---

## 🔔 Real-Time com Supabase

### Inscrever em Novas Mensagens
```typescript
// ⚠️ CORRETO: Usar tabela 'conversation_memory' (não 'messages')
// ⚠️ CORRETO: Filtrar por 'conversation_uuid' (não 'conversation_id')

const channel = supabase
  .channel(`conversation-${conversationUUID}`)
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'conversation_memory', // ✅ Nome correto da tabela
      filter: `conversation_uuid=eq.${conversationUUID}` // ✅ UUID, não integer ID
    },
    (payload) => {
      const newMessage = payload.new
      
      // Adicionar nova mensagem na UI
      setMessages(prev => [...prev, {
        id: newMessage.id,
        role: newMessage.message_role,
        content: newMessage.message_content,
        timestamp: newMessage.message_timestamp,
        sender_name: newMessage.sender_name,
        has_attachments: newMessage.has_attachments,
        attachments: newMessage.attachments
      }])
      
      // Scroll para o final
      scrollToBottom()
      
      // Tocar som se mensagem do cliente
      if (newMessage.message_role === 'user') {
        playNotificationSound()
      }
    }
  )
  .subscribe()

// Cleanup
return () => {
  supabase.removeChannel(channel)
}
```

### Monitorar Mudanças de Status
```typescript
supabase
  .channel('conversation-status')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'conversations',
      filter: `status=eq.needs_human`
    },
    (payload) => {
      // Mostrar notificação
      showNotification({
        title: 'Cliente precisa de você!',
        message: `${payload.new.customer_name} aguarda atendimento`,
        type: 'warning'
      })
      
      // Tocar som
      playAlertSound()
      
      // Atualizar lista de conversas
      refetchConversations()
    }
  )
  .subscribe()
```

---

## 🎨 Componentes UI (Shadcn/ui)

**Instalar shadcn/ui components:**
```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card input label select avatar badge alert tabs accordion
```

**Theme Configuration (tailwind.config.js):**
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#667eea',
          dark: '#5568d3',
          light: '#7c8df5'
        },
        accent: '#10b981',
        warning: '#f59e0b',
        danger: '#ef4444'
      }
    }
  }
}
```

---

## 🚀 Features Adicionais

### 1. Notificações do Navegador
```typescript
// Pedir permissão
const requestNotificationPermission = async () => {
  if ('Notification' in window && Notification.permission === 'default') {
    await Notification.requestPermission()
  }
}

// Enviar notificação
const sendBrowserNotification = (title: string, body: string) => {
  if (Notification.permission === 'granted') {
    new Notification(title, {
      body,
      icon: '/icon.png',
      badge: '/badge.png',
      tag: 'conversation-alert',
      requireInteraction: true // Fica visível até clicar
    })
  }
}
```

### 2. Som de Alerta
```typescript
const playAlertSound = () => {
  const audio = new Audio('/sounds/notification.mp3')
  audio.volume = 0.5
  audio.play().catch(err => console.log('Audio play failed:', err))
}
```

### 3. Badge de Status de Mensagem
```typescript
// ⚠️ IMPORTANTE: Chatwoot NÃO fornece status "lida" ou "entregue"
// Apenas mostrar timestamp de envio

<div className="flex items-center gap-1 text-xs text-gray-500">
  <Clock className="h-3 w-3" />
  <span>{formatTimestamp(message.timestamp)}</span>
</div>

// ❌ NÃO IMPLEMENTAR: Indicadores "✓✓" (entregue/lido)
// ❌ NÃO IMPLEMENTAR: "Cliente digitando..." (Chatwoot não tem esse evento)
```

### 4. Preview de Imagem/Vídeo
```typescript
<Dialog>
  <DialogTrigger>
    <img src={thumbnailUrl} className="max-w-xs rounded cursor-pointer" />
  </DialogTrigger>
  <DialogContent className="max-w-3xl">
    <img src={fullSizeUrl} className="w-full" />
  </DialogContent>
</Dialog>
```

### 5. Export Conversa (PDF)
```typescript
import { jsPDF } from 'jspdf'

const exportConversationToPDF = (messages: Message[]) => {
  const doc = new jsPDF()
  
  doc.text('Histórico da Conversa', 10, 10)
  
  messages.forEach((msg, i) => {
    doc.text(`${msg.sender_name}: ${msg.content}`, 10, 20 + (i * 10))
  })
  
  doc.save(`conversa-${conversationId}.pdf`)
}
```

---

## 🔄 Fluxos de Dados Multi-Canal

### Fluxo de Entrada (Cliente → Dashboard)

**WhatsApp:**
```
WhatsApp → Evolution API → Chatwoot → n8n (WF0) 
→ sync_conversation_from_chatwoot(
    p_client_id, p_agent_id, p_chatwoot_conversation_id,
    p_customer_name, p_customer_phone, p_chatwoot_contact_id,
    p_channel_type: 'whatsapp', // 🆕
    p_channel_specific_data: {customer_phone: "5511987654321"} // 🆕
  )
→ Supabase (conversations + conversation_memory)
→ Real-time subscription → Dashboard atualiza
```

**Instagram DM:**
```
Instagram → Chatwoot (Meta Business Integration) → n8n (WF0)
→ sync_conversation_from_chatwoot(
    ...,
    p_channel_type: 'instagram', // 🆕
    p_channel_specific_data: {instagram_username: "@usuario", instagram_id: "123"} // 🆕
  )
→ Supabase → Dashboard
```

**WebChat:**
```
Widget no site → Chatwoot → n8n (WF0)
→ sync_conversation_from_chatwoot(
    ...,
    p_channel_type: 'webchat', // 🆕
    p_channel_specific_data: {session_id: "abc", visitor_name: "Nome"} // 🆕
  )
→ Supabase → Dashboard
```

**Email:**
```
Email recebido → Chatwoot (IMAP) → n8n (WF0)
→ sync_conversation_from_chatwoot(
    ...,
    p_channel_type: 'email', // 🆕
    p_channel_specific_data: {email_address: "user@email.com", email_subject: "Assunto"} // 🆕
  )
→ Supabase → Dashboard (⚠️ sem real-time)
```

### Fluxo de Saída (Dashboard → Cliente)

**1. Dashboard salva mensagem:**
```typescript
const { data } = await supabase.rpc('send_human_message', {
  p_conversation_uuid: uuid,
  p_message_content: text,
  p_media_url: mediaUrl
})
```

**2. Dashboard chama webhook n8n:**
```typescript
// 🆕 Migration 023: webhook agora recebe channel_type e channel_specific_data
await fetch('https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    chatwoot_conversation_id: data.chatwoot_conversation_id,
    channel_type: conversation.channel_type, // 'whatsapp' | 'instagram' | 'webchat' | 'email'
    channel_specific_data: conversation.channel_specific_data, // 🆕 Dados do canal
    message: text,
    media_url: mediaUrl
  })
})
```

**3. n8n roteia para canal correto:**
- WhatsApp → Evolution API → WhatsApp (usa `customer_phone` do channel_specific_data)
- Instagram → Chatwoot API → Instagram (usa `instagram_username` do channel_specific_data)
- WebChat → Chatwoot API → Widget no site (usa `session_id` do channel_specific_data)
- Email → SMTP → Email do cliente (usa `email_address` do channel_specific_data)

---

## 🗂️ Estruturas de Dados Multi-Canal (Migration 023)

### Tipos TypeScript

```typescript
// Enum de canais
type ChannelType = 'whatsapp' | 'instagram' | 'webchat' | 'email'

// Dados específicos por canal (JSONB)
type ChannelSpecificData = 
  | WhatsAppData 
  | InstagramData 
  | WebChatData 
  | EmailData

interface WhatsAppData {
  customer_phone: string // "5511987654321"
}

interface InstagramData {
  instagram_username: string // "@maria.silva"
  instagram_id?: string // ID numérico do Meta (opcional)
}

interface WebChatData {
  session_id: string // ID da sessão do widget
  visitor_name: string // Nome do visitante
  visitor_email?: string // Email opcional
}

interface EmailData {
  email_address: string // "cliente@email.com"
  email_subject?: string // Assunto do email (opcional)
  email_name?: string // Nome do remetente (opcional)
}

// Interface de Conversa Completa
interface Conversation {
  id: string // UUID
  chatwoot_conversation_id: number
  customer_name: string
  customer_phone: string | null
  channel_type: ChannelType // 🆕 Migration 023
  channel_specific_data: ChannelSpecificData // 🆕 Migration 023 (JSONB)
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

### Exemplos de Uso por Canal

#### Filtrar Conversas por Canal
```typescript
// Buscar apenas conversas do WhatsApp
const { data } = await supabase.rpc('get_conversations_list', {
  p_client_id: 'clinica_sorriso_001',
  p_status_filter: null,
  p_channel_filter: 'whatsapp', // 🆕 Filtro por canal
  p_limit: 50,
  p_offset: 0
})

// Buscar apenas conversas do Instagram
const { data: instagramConvos } = await supabase.rpc('get_conversations_list', {
  p_client_id: 'clinica_sorriso_001',
  p_status_filter: null,
  p_channel_filter: 'instagram', // 🆕
  p_limit: 50,
  p_offset: 0
})
```

#### Renderizar Ícone por Canal
```tsx
const ChannelIcon = ({ channel }: { channel: ChannelType }) => {
  const icons = {
    whatsapp: <MessageCircle className="text-green-500" />,
    instagram: <Instagram className="text-pink-500" />,
    webchat: <Globe className="text-blue-500" />,
    email: <Mail className="text-gray-500" />
  }
  return icons[channel] || <MessageCircle />
}
```

#### Exibir Identificador do Cliente
```tsx
const getCustomerIdentifier = (conv: Conversation): string => {
  const { channel_type, channel_specific_data } = conv
  
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
```

#### Badges de Canal
```tsx
const ChannelBadge = ({ channel }: { channel: ChannelType }) => {
  const styles = {
    whatsapp: 'bg-green-100 text-green-800',
    instagram: 'bg-pink-100 text-pink-800',
    webchat: 'bg-blue-100 text-blue-800',
    email: 'bg-gray-100 text-gray-800'
  }
  
  const labels = {
    whatsapp: '📱 WhatsApp',
    instagram: '📷 Instagram',
    webchat: '💬 WebChat',
    email: '📧 Email'
  }
  
  return (
    <span className={`px-2 py-1 rounded-full text-xs ${styles[channel]}`}>
      {labels[channel]}
    </span>
  )
}
```

### ⚠️ Restrições por Canal

#### Limitações de Mídia
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
      documents: false, // ❌ Instagram não suporta documentos
      maxFileSize: '8MB'
    },
    webchat: {
      images: true,
      audio: false, // ❌ Depende da implementação
      video: false, // ❌ Depende da implementação
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

// Validar antes de enviar
const canSendMedia = (channel: ChannelType, mediaType: 'image' | 'audio' | 'video' | 'document') => {
  const support = getChannelMediaSupport(channel)
  return support[mediaType + 's'] // Ex: support['images']
}
```

#### Comportamento de Tempo Real
```typescript
const getChannelRealtimeSupport = (channel: ChannelType) => {
  return {
    whatsapp: true, // ✅ Real-time total
    instagram: true, // ✅ Real-time via Chatwoot webhooks
    webchat: true, // ✅ Real-time via websockets
    email: false // ❌ Email é assíncrono, sem real-time
  }[channel]
}
```

#### UI: Desabilitar recursos não suportados
```tsx
const MessageInput = ({ conversation }: { conversation: Conversation }) => {
  const mediaSupport = getChannelMediaSupport(conversation.channel_type)
  
  return (
    <div className="flex gap-2">
      <Button 
        disabled={!mediaSupport.images}
        title={!mediaSupport.images ? "Imagens não suportadas neste canal" : "Enviar imagem"}
      >
        <ImageIcon />
      </Button>
      
      <Button 
        disabled={!mediaSupport.audio}
        title={!mediaSupport.audio ? "Áudio não suportado neste canal" : "Enviar áudio"}
      >
        <Mic />
      </Button>
      
      <Button 
        disabled={!mediaSupport.documents}
        title={!mediaSupport.documents ? "Documentos não suportados neste canal" : "Enviar documento"}
      >
        <Paperclip />
      </Button>
    </div>
  )
}
```

---

## 📦 Estrutura de Pastas

```
src/
├── components/
│   ├── ui/              # Shadcn components
│   ├── layout/
│   │   ├── Sidebar.tsx
│   │   ├── Header.tsx
│   │   └── Layout.tsx
│   ├── conversations/
│   │   ├── ConversationList.tsx
│   │   ├── ConversationItem.tsx
│   │   ├── ConversationDetail.tsx
│   │   ├── MessageBubble.tsx
│   │   └── MessageInput.tsx
│   ├── dashboard/
│   │   ├── MetricCard.tsx
│   │   └── StatsGrid.tsx
│   └── auth/
│       ├── LoginForm.tsx
│       └── ProtectedRoute.tsx
├── pages/
│   ├── Login.tsx
│   ├── Dashboard.tsx
│   ├── Conversations.tsx
│   ├── ConversationDetail.tsx
│   ├── Analytics.tsx
│   ├── Settings.tsx
│   └── Support.tsx
├── lib/
│   ├── supabase.ts
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useConversations.ts
│   │   ├── useMessages.ts
│   │   └── useNotifications.ts
│   └── utils/
│       ├── date.ts
│       ├── format.ts
│       └── notifications.ts
├── types/
│   ├── conversation.ts
│   ├── message.ts
│   ├── channel.ts      # ⚠️ NOVO: tipos de canal
│   └── user.ts
├── App.tsx
└── main.tsx
```

---

## 📘 TypeScript Types (Multi-Canal)

**types/channel.ts:**
```typescript
export type ChannelType = 'whatsapp' | 'instagram' | 'webchat' | 'email'

export interface ChannelCapabilities {
  text: boolean
  image: boolean
  audio: boolean
  video: boolean
  document: boolean
  realtime: boolean
}

export interface WhatsAppData {
  customer_phone: string
}

export interface InstagramData {
  instagram_username: string
  instagram_id: string
}

export interface WebChatData {
  session_id: string
  visitor_name: string
  ip_address?: string
}

export interface EmailData {
  email_address: string
  email_name: string
  email_subject?: string
}

export type ChannelSpecificData = 
  | WhatsAppData 
  | InstagramData 
  | WebChatData 
  | EmailData

export interface ChannelConfig {
  type: ChannelType
  label: string
  icon: React.ReactNode
  color: string
  capabilities: ChannelCapabilities
}
```

**types/conversation.ts:**
```typescript
import { ChannelType, ChannelSpecificData } from './channel'

export interface Conversation {
  id: string
  client_id: string
  chatwoot_conversation_id: number
  customer_name: string
  customer_phone: string | null
  channel_type: ChannelType // ⚠️ NOVO
  channel_specific_data: ChannelSpecificData // ⚠️ NOVO
  status: 'active' | 'needs_human' | 'human_takeover' | 'resolved' | 'archived'
  assigned_to: string | null
  taken_over_at: string | null
  taken_over_by_name: string | null
  ai_paused: boolean
  unread_count: number
  last_message_content: string | null
  last_message_timestamp: string | null
  last_message_sender: string | null
  created_at: string
  updated_at: string
}
```

**types/message.ts:**
```typescript
export type MessageRole = 'user' | 'assistant' | 'system' | 'agent_human'

export interface MessageAttachment {
  type: 'image' | 'audio' | 'video' | 'document'
  url: string
  filename: string
  mime_type: string
  size?: number
  duration?: number // para áudio/vídeo
}

export interface Message {
  id: string
  role: MessageRole
  content: string
  timestamp: string
  sender_name: string
  has_attachments: boolean
  attachments: MessageAttachment[] | null
}
```

---

## 🔒 Segurança (RLS - Row Level Security)

**✅ RLS JÁ CONFIGURADO NO BANCO (Migration 022)**

As políticas já estão ativas no Supabase:

```sql
-- ✅ Conversations: usuário vê apenas do seu cliente
CREATE POLICY "Users can view conversations of their client"
ON conversations FOR SELECT
USING (
  client_id IN (
    SELECT client_id FROM dashboard_users WHERE id = auth.uid()
  )
);

-- ✅ Conversations: usuário pode atualizar conversas do seu cliente
CREATE POLICY "Users can update conversations of their client"
ON conversations FOR UPDATE
USING (
  client_id IN (
    SELECT client_id FROM dashboard_users WHERE id = auth.uid()
  )
);

-- ✅ Dashboard Users: usuário vê apenas próprio perfil
CREATE POLICY "Users can view own profile"
ON dashboard_users FOR SELECT
USING (id = auth.uid());

-- ✅ Conversation Memory: usuário vê mensagens do seu cliente
CREATE POLICY "Users can view messages of their client conversations"
ON conversation_memory FOR SELECT
USING (
  client_id IN (
    SELECT client_id FROM dashboard_users WHERE id = auth.uid()
  )
);
```

**⚠️ IMPORTANTE:** Todas as queries devem usar `auth.uid()` do Supabase Auth.

---

## ⚙️ Variáveis de Ambiente

Criar arquivo `.env`:
```bash
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
VITE_N8N_WEBHOOK_BASE_URL=https://n8n.yourdomain.com
VITE_APP_NAME="Digitai.app"
```

---

## 🚀 Deploy

### Vercel (Recomendado)
```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel --prod

# Configurar domínio
vercel domains add app.digitai.app
```

### Configuração DNS (Cloudflare)
```
Tipo: CNAME
Nome: app
Conteúdo: cname.vercel-dns.com
Proxy: Ativado (laranja)
```

---

## 📝 Checklist de Implementação

```
[ ] Configurar projeto Vite + React + TypeScript
[ ] Instalar Tailwind + Shadcn/ui
[ ] Criar páginas de autenticação (Login)
[ ] Integrar Supabase Auth
[ ] Criar layout (Sidebar + Header)
[ ] Criar tipos TypeScript (channel.ts, conversation.ts, message.ts)
[ ] Implementar página Dashboard (métricas + lista conversas)
[ ] Adicionar filtros multi-canal (Tabs: All/WhatsApp/Instagram/WebChat/Email)
[ ] Mostrar ícones de canal em cada conversa
[ ] Implementar página Conversa Individual (chat)
[ ] Adicionar header com indicador de canal
[ ] Implementar restrições de input por canal (ex: Instagram sem áudio)
[ ] Adicionar real-time (Supabase subscriptions em conversation_memory)
[ ] Implementar takeover (assumir conversa)
[ ] Implementar envio de mensagem (RPC + webhook n8n)
[ ] Criar página Analytics (usar dados reais do get_dashboard_stats)
[ ] Marcar métricas mock (Top Tópicos, etc) como "Em breve"
[ ] Criar página Configurações
[ ] Adicionar notificações browser
[ ] Adicionar som de alerta
[ ] Implementar filtros e busca
[ ] Responsividade mobile
[ ] Testar com usuário teste@evolutedigital.com.br / Teste@2024!
[ ] Testar conversas em diferentes canais
[ ] Validar webhook n8n funcionando
[ ] Testes finais
[ ] Deploy Vercel
[ ] Configurar DNS (app.digitai.app)
```

---

## 🎯 Resultado Esperado

Um dashboard **clean, rápido e intuitivo** onde o cliente:

1. ✅ Faz login com email/senha
2. ✅ Vê métricas resumidas (conversas, taxa IA, etc)
3. ✅ Lista todas as conversas em tempo real
4. ✅ Clica para ver histórico completo
5. ✅ Recebe alerta quando IA aciona humano
6. ✅ Assume conversa com 1 clique
7. ✅ Responde direto no dashboard (como WhatsApp Web)
8. ✅ Devolve para IA quando terminar
9. ✅ Vê analytics simples (gráficos, métricas)
10. ✅ Configura notificações e senha

**Tempo estimado com Lovable:** 4-6 horas

---

## 💡 Prompt Resumido para Copiar no Lovable

```
Criar dashboard React + TypeScript + Tailwind + Shadcn/ui para monitoramento de conversas de chatbot IA multi-canal.

PÁGINAS:
1. Login (split-screen: visual roxo + form branco)
2. Dashboard (sidebar + cards métricas + lista conversas real-time)
3. Conversa Individual (interface chat com takeover)
4. Analytics (gráficos + métricas período)
5. Configurações (perfil + senha + notificações)
6. Suporte (contatos + FAQ)

FEATURES PRINCIPAIS:
- Auth com Supabase (teste: teste@evolutedigital.com.br / Teste@2024!)
- MULTI-CANAL: WhatsApp, Instagram DM, WebChat, Email
- Filtros por canal (tabs com ícones)
- Real-time subscriptions em 'conversation_memory' (não 'messages')
- Takeover: cliente assume conversa com 1 clique, IA pausa
- Envio de mensagem: RPC send_human_message() + webhook n8n explícito
- Notificações browser + som quando IA aciona humano
- Status visual: 🟢 IA | 🟡 Precisa humano | 🔴 Humano atendendo | ⚪ Finalizada
- Restrições por canal (Instagram sem áudio, Email sem real-time)
- Responsivo mobile

DESIGN:
- Cores: Primary #667eea, Accent #10b981, backgrounds white/gray
- Tipografia: Inter
- Ícones: Lucide React (MessageCircle, Instagram, Globe, Mail)
- Components: Shadcn/ui

BACKEND (JÁ CONFIGURADO):
- Supabase Migration 022 executada
- Tabelas: conversations (com channel_type), conversation_memory, dashboard_users
- 7 RPC Functions (get_conversations_list, get_conversation_detail, takeover_conversation, etc)
- RLS habilitado (EXCETO dashboard_users que permite SELECT direto)
- Webhook n8n: https://n8n.evolutedigital.com.br/webhook/WF2-send-from-dashboard

CRÍTICO:
- Usar APENAS RPCs (não queries diretas, exceto dashboard_users)
- Real-time: filtrar por conversation_uuid (UUID), não conversation_id (integer)
- Anexos: JSONB array com type, url, filename, mime_type
- Analytics: get_dashboard_stats() retorna dados reais, "Top Tópicos" é mock
- NÃO implementar: status lida/entregue, indicador "digitando" (Chatwoot não fornece)

Deploy: Vercel (app.digitai.app)
```

---

Pronto! Copie este arquivo inteiro ou o "Prompt Resumido" e cole no Lovable para gerar o dashboard. 🚀

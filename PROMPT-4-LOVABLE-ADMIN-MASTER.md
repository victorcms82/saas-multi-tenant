# PROMPT 4 - PAINEL DE ADMINISTRADOR MASTER

Criar sistema completo de administração com rota /admin para super_admins gerenciarem todo o multi-tenant.

## 🎯 ROTA PRINCIPAL

Criar `/admin` protegida por verificação `await supabase.rpc('is_super_admin')`. Se não for super_admin, redirecionar para /dashboard.

## 📱 LAYOUT E NAVEGAÇÃO

Sidebar exclusiva com:
- Logo e título "Admin Master"
- Menu: 📊 Overview, 👥 Clientes, 🤖 Agentes, 💬 Conversas, 📈 Analytics, 📝 Logs
- Botão "Voltar para Dashboard" (se usuário também for agent)
- User menu com nome e logout
- Design diferente do dashboard de agentes (azul escuro, mais profissional)

## 📄 PÁGINAS

### 1. OVERVIEW (/admin)
Cards de métricas:
- Total Clientes Ativos
- Total Agentes  
- Total Conversas (hoje/semana/mês)
- Total Mensagens

Seções:
- Gráfico de conversas por cliente (últimos 7 dias)
- Lista "Conversas Recentes" (últimas 10 com cliente, contato, status)
- Lista "Clientes Mais Ativos" (top 5 por conversas)

### 2. CLIENTES (/admin/clients)
DataTable com:
- Colunas: Nome, Client ID, Status, Data Criação, # Conversas, # Mensagens, # Agentes
- Filtros: Ativo/Inativo
- Busca por nome ou ID
- Paginação (20 itens)
- Botão "Adicionar Cliente" (modal com formulário)
- Ações: Ver detalhes, Editar, Ativar/Desativar

Usar RPC: `await supabase.rpc('get_all_clients')`

### 3. AGENTES (/admin/agents)
DataTable com:
- Colunas: Nome Agente, Cliente, Status, Data Criação, # Conversas, Modelo LLM
- Filtros: Cliente (dropdown), Status
- Busca por nome
- Paginação (20 itens)
- Botão "Adicionar Agente" (modal)
- Ações: Ver detalhes, Editar, Ativar/Desativar

Usar RPC: `await supabase.rpc('get_all_agents')`

### 4. CONVERSAS (/admin/conversations)
DataTable com TODAS conversas do sistema:
- Colunas: Cliente, Contato, Canal (WhatsApp/Instagram/etc), Status, Última Mensagem, Data
- Filtros: Cliente (dropdown), Status (dropdown), Canal, Período
- Busca por contato/telefone
- Paginação (50 itens)
- Ações: Ver conversa (abrir chat completo), Assumir, Exportar

Usar RPC: 
```typescript
await supabase.rpc('get_global_conversations', {
  p_limit: 50,
  p_offset: page * 50,
  p_client_id: clientFilter || null,
  p_status_id: statusFilter || null
})
```

### 5. ANALYTICS (/admin/analytics)
Seletor de período: Hoje, 7 dias, 30 dias, Período customizado

Métricas por cliente (tabela):
- Nome, Conversas Iniciadas, Taxa Resolução IA, Tempo Médio Resposta, Mensagens

Gráficos:
- Conversas por dia (linha)
- Conversas por canal (pizza)
- Status conversas (barras)
- Top 5 clientes (barras horizontais)

Botão "Exportar Relatório" (CSV)

### 6. LOGS (/admin/logs)
DataTable de auditoria:
- Colunas: Data/Hora, Usuário, Ação, Cliente, Detalhes
- Filtros: Usuário, Tipo de Ação, Cliente, Data
- Busca por descrição
- Paginação (100 itens)

Tipos de ação rastreados:
- takeover_conversation
- return_to_ai
- send_message
- update_client
- update_agent

## 🧩 COMPONENTES REUTILIZÁVEIS

Criar:
- `AdminLayout.tsx` - Layout wrapper com sidebar
- `AdminSidebar.tsx` - Menu lateral do admin
- `DataTable.tsx` - Tabela com sort, filtros, paginação genérica
- `MetricCard.tsx` - Card de métrica (número grande + label)
- `ClientModal.tsx` - Criar/editar cliente
- `AgentModal.tsx` - Criar/editar agente

## 🔒 SEGURANÇA

Em TODAS as páginas de /admin, adicionar verificação:

```typescript
useEffect(() => {
  const checkAdmin = async () => {
    const { data, error } = await supabase.rpc('is_super_admin');
    if (error || !data) {
      toast.error('Acesso negado');
      navigate('/dashboard');
    }
  };
  checkAdmin();
}, []);
```

## 🎨 DESIGN

- Usar shadcn/ui components
- Sidebar azul escuro (#1e293b ou similar)
- Cards com shadow suave
- Tabelas com hover states
- Loading skeletons durante carregamento
- Toasts para feedback de ações
- Responsive (mobile-friendly)
- Cores diferentes do dashboard de agentes

## 🔄 NAVEGAÇÃO INTELIGENTE

Se usuário for super_admin E agent:
- Mostrar botão "Admin Master" no /dashboard
- Mostrar botão "Meu Dashboard" no /admin

Se usuário for APENAS super_admin:
- Após login, redirecionar direto para /admin

## ✅ IMPORTANTE

- SEMPRE usar try/catch em RPCs
- Loading states em todas requisições
- Error handling com mensagens claras
- Atualizar listas após criar/editar/deletar
- Cache quando possível (React Query recomendado)
- Acessibilidade (labels, aria-*)

## 📊 RPCs DISPONÍVEIS

Já criados no backend:
- `is_super_admin()` - Verifica se usuário é admin
- `get_all_clients()` - Lista todos clientes
- `get_all_agents()` - Lista todos agentes
- `get_global_conversations(p_limit, p_offset, p_client_id, p_status_id)` - Conversas globais

Implementar primeiro Overview + Clientes + Agentes. Depois Analytics + Logs.

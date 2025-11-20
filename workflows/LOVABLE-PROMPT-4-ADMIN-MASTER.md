# 🎯 PROMPT 4 - PAINEL ADMIN MASTER

Cole este prompt no Lovable APÓS executar a Migration 027:

---

```
Criar Painel de Administrador Master (Admin Dashboard):

REQUISITOS:

1. NOVA ROTA: /admin
   - Protegida: apenas usuários com role = 'super_admin'
   - Verificar com: await supabase.rpc('is_super_admin')
   - Se não for super_admin, redirecionar para /dashboard
   - Layout diferente do dashboard de agentes

2. SIDEBAR DO ADMIN:
   - Logo/Nome do sistema
   - Menu items:
     * 📊 Overview (página inicial)
     * 👥 Clientes
     * 🤖 Agentes
     * 💬 Conversas (todas)
     * 📈 Analytics
     * 📝 Logs
   - Botão "Voltar para Dashboard" (se for agent também)
   - User menu com logout

3. PÁGINA: OVERVIEW (/admin)
   - Cards com métricas gerais:
     * Total de Clientes Ativos
     * Total de Agentes
     * Total de Conversas (hoje/semana/mês)
     * Total de Mensagens
   - Gráfico de conversas por cliente (últimos 7 dias)
   - Lista de "Conversas Recentes" (últimas 10)
   - Lista de "Clientes Mais Ativos"

4. PÁGINA: CLIENTES (/admin/clients)
   - Tabela com todos os clientes:
     * Colunas: Nome, ID, Status, Criado em, Conversas, Mensagens, Agentes
     * Filtros: Ativo/Inativo
     * Busca por nome/ID
     * Paginação (20 por página)
   - Botão "Adicionar Cliente" (abrir modal)
   - Ações por linha:
     * Ver detalhes (modal)
     * Editar
     * Ativar/Desativar
   - Usar RPC: await supabase.rpc('get_all_clients')

5. PÁGINA: AGENTES (/admin/agents)
   - Tabela com todos os agentes:
     * Colunas: Nome, Email, Cliente, Status, Criado em, Conversas
     * Filtros: Cliente, Status
     * Busca por nome/email
     * Paginação (20 por página)
   - Botão "Adicionar Agente" (modal)
   - Ações por linha:
     * Ver detalhes
     * Editar
     * Ativar/Desativar
   - Usar RPC: await supabase.rpc('get_all_agents')

6. PÁGINA: CONVERSAS (/admin/conversations)
   - Tabela com TODAS as conversas:
     * Colunas: Cliente, Contato, Canal, Status, Última msg, Data
     * Filtros: Cliente, Status, Canal, Data
     * Busca por contato/telefone
     * Paginação (50 por página)
   - Ações por linha:
     * Ver conversa completa (abrir chat)
     * Assumir conversa
     * Exportar histórico
   - Usar RPC: await supabase.rpc('get_global_conversations', { 
       p_limit: 50, 
       p_offset: 0,
       p_client_id: filtroCliente,
       p_status_id: filtroStatus
     })

7. PÁGINA: ANALYTICS (/admin/analytics)
   - Período selecionável: Hoje, 7 dias, 30 dias, Custom
   - Métricas por cliente:
     * Conversas iniciadas
     * Taxa de resolução da IA
     * Tempo médio de resposta
     * Mensagens enviadas
   - Gráficos:
     * Conversas por dia (linha)
     * Conversas por canal (pizza)
     * Status das conversas (barras)
     * Top 5 clientes (barras horizontais)
   - Exportar relatório (CSV/PDF)

8. PÁGINA: LOGS (/admin/logs)
   - Tabela de auditoria:
     * Colunas: Data/Hora, Usuário, Ação, Cliente, Detalhes
     * Filtros: Usuário, Ação, Cliente, Data
     * Busca por descrição
     * Paginação (100 por página)
   - Tipos de ação:
     * takeover_conversation
     * return_to_ai
     * send_message
     * update_client
     * update_agent
   - Usar query direta na tabela audit_logs (se existir)

9. COMPONENTES COMUNS:
   - DataTable reutilizável (com sort, filtros, paginação)
   - Modal de detalhes (genérico)
   - Modal de formulário (criar/editar)
   - Cards de métricas
   - Gráficos (usar biblioteca recharts ou similar)

10. ESTILO:
   - Cores diferentes do dashboard de agentes (ex: sidebar azul escuro)
   - Mais clean e profissional
   - Usar shadcn/ui components
   - Responsive (mobile friendly)

IMPORTANTE:
- SEMPRE verificar is_super_admin() antes de exibir páginas
- Usar toast para feedback de ações
- Loading states em todas as requisições
- Error handling em todas as RPCs
- Cache de dados quando possível
- Atualizar dados automaticamente após ações

NAVEGAÇÃO:
- Se usuário for super_admin E agent:
  * Mostrar botão "Ir para Admin" no /dashboard
  * Mostrar botão "Ir para Dashboard" no /admin
- Se usuário for APENAS super_admin:
  * Redirecionar direto para /admin após login
```

---

## 📝 ESTRUTURA DE PASTAS (SUGESTÃO):

```
src/
  pages/
    admin/
      index.tsx          (Overview)
      clients.tsx        (Gestão de clientes)
      agents.tsx         (Gestão de agentes)
      conversations.tsx  (Todas conversas)
      analytics.tsx      (Analytics global)
      logs.tsx           (Logs de auditoria)
  components/
    admin/
      AdminLayout.tsx    (Layout do admin)
      AdminSidebar.tsx   (Sidebar do admin)
      DataTable.tsx      (Tabela reutilizável)
      MetricCard.tsx     (Card de métrica)
      ClientModal.tsx    (Modal de cliente)
      AgentModal.tsx     (Modal de agente)
```

---

## ✅ CHECKLIST PÓS-IMPLEMENTAÇÃO:

- [ ] Login como super_admin redireciona para /admin
- [ ] Sidebar do admin aparece corretamente
- [ ] Overview carrega métricas globais
- [ ] Página Clientes lista todos os clientes
- [ ] Página Agentes lista todos os agentes
- [ ] Página Conversas mostra conversas de todos os clientes
- [ ] Filtros funcionam em todas as páginas
- [ ] Botão "Voltar para Dashboard" funciona
- [ ] Analytics exibe gráficos corretos
- [ ] Logs mostra auditoria de ações

---

## 🔐 SEGURANÇA:

Adicionar em TODAS as páginas de admin:

```typescript
useEffect(() => {
  const checkAdmin = async () => {
    const { data, error } = await supabase.rpc('is_super_admin');
    
    if (error || !data) {
      toast.error('Acesso negado: você não é administrador');
      navigate('/dashboard');
    }
  };
  
  checkAdmin();
}, []);
```

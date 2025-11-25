# CORREÇÃO URGENTE - Admin Master: RPCs e Botões

## 🐛 PROBLEMAS IDENTIFICADOS

1. ❌ "Erro ao carregar clientes" - RPC `get_all_clients()` falhando
2. ❌ "Erro ao carregar agentes" - RPC `get_all_agents()` falhando  
3. ❌ Botão "Adicionar Cliente" não funciona
4. ❌ Botão "Adicionar Agente" não funciona
5. ❌ "Erro ao carregar conversas" - RPC `get_global_conversations()` falhando

## 🔧 CORREÇÕES NECESSÁRIAS

### 1. CORRIGIR PÁGINA DE CLIENTES

**Problema:** RPC falhando e botão não funciona

**Solução:** Atualizar `src/pages/admin/Clients.tsx`:

```typescript
// SUBSTITUIR A FUNÇÃO loadClients POR:
const loadClients = async () => {
  setLoading(true);
  try {
    const { data, error } = await supabase.rpc('get_all_clients');
    
    if (error) {
      console.error('Erro RPC get_all_clients:', error);
      // Se RPC não existir, buscar direto da tabela
      const { data: clientsData, error: directError } = await supabase
        .from('clients')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (directError) throw directError;
      setClients(clientsData || []);
    } else {
      setClients(data || []);
    }
  } catch (error: any) {
    console.error('Erro ao carregar clientes:', error);
    toast({ 
      title: "Erro ao carregar clientes", 
      description: error.message,
      variant: "destructive" 
    });
  } finally {
    setLoading(false);
  }
};

// ADICIONAR MODAL DE CRIAR CLIENTE (se não existir):
const [showCreateModal, setShowCreateModal] = useState(false);
const [newClient, setNewClient] = useState({
  client_id: '',
  client_name: '',
  contact_email: '',
  contact_phone: ''
});

const handleCreateClient = async () => {
  try {
    const { data, error } = await supabase.rpc('create_new_client', {
      p_client_id: newClient.client_id,
      p_client_name: newClient.client_name,
      p_contact_email: newClient.contact_email,
      p_contact_phone: newClient.contact_phone
    });

    if (error) throw error;
    
    if (data?.success) {
      toast({ title: "Cliente criado com sucesso!" });
      setShowCreateModal(false);
      setNewClient({ client_id: '', client_name: '', contact_email: '', contact_phone: '' });
      loadClients();
    } else {
      throw new Error(data?.error || 'Erro ao criar cliente');
    }
  } catch (error: any) {
    toast({ 
      title: "Erro ao criar cliente", 
      description: error.message,
      variant: "destructive" 
    });
  }
};

// NO BOTÃO "Adicionar Cliente", trocar por:
<Button onClick={() => setShowCreateModal(true)}>
  <Plus className="mr-2 h-4 w-4" />
  Adicionar Cliente
</Button>

// ADICIONAR MODAL (antes do </AdminLayout>):
<Dialog open={showCreateModal} onOpenChange={setShowCreateModal}>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Criar Novo Cliente</DialogTitle>
    </DialogHeader>
    <div className="space-y-4">
      <div>
        <Label>Client ID</Label>
        <Input 
          value={newClient.client_id}
          onChange={(e) => setNewClient({...newClient, client_id: e.target.value})}
          placeholder="cliente_001"
        />
      </div>
      <div>
        <Label>Nome do Cliente</Label>
        <Input 
          value={newClient.client_name}
          onChange={(e) => setNewClient({...newClient, client_name: e.target.value})}
          placeholder="Nome da Empresa"
        />
      </div>
      <div>
        <Label>Email de Contato</Label>
        <Input 
          type="email"
          value={newClient.contact_email}
          onChange={(e) => setNewClient({...newClient, contact_email: e.target.value})}
          placeholder="contato@empresa.com"
        />
      </div>
      <div>
        <Label>Telefone</Label>
        <Input 
          value={newClient.contact_phone}
          onChange={(e) => setNewClient({...newClient, contact_phone: e.target.value})}
          placeholder="+55 11 99999-9999"
        />
      </div>
    </div>
    <DialogFooter>
      <Button variant="outline" onClick={() => setShowCreateModal(false)}>Cancelar</Button>
      <Button onClick={handleCreateClient}>Criar Cliente</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>

// ADICIONAR IMPORTS:
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Plus } from "lucide-react";
```

### 2. CORRIGIR PÁGINA DE AGENTES

**Problema:** RPC falhando e botão não funciona

**Solução:** Atualizar `src/pages/admin/Agents.tsx`:

```typescript
// SUBSTITUIR A FUNÇÃO loadAgents POR:
const loadAgents = async () => {
  setLoading(true);
  try {
    const { data, error } = await supabase.rpc('get_all_agents');
    
    if (error) {
      console.error('Erro RPC get_all_agents:', error);
      // Se RPC não existir, buscar direto da tabela
      const { data: agentsData, error: directError } = await supabase
        .from('agents')
        .select(`
          *,
          clients(client_name)
        `)
        .order('created_at', { ascending: false });
      
      if (directError) throw directError;
      setAgents(agentsData || []);
    } else {
      setAgents(data || []);
    }
  } catch (error: any) {
    console.error('Erro ao carregar agentes:', error);
    toast({ 
      title: "Erro ao carregar agentes", 
      description: error.message,
      variant: "destructive" 
    });
  } finally {
    setLoading(false);
  }
};

// ADICIONAR MODAL DE CRIAR AGENTE:
const [showCreateModal, setShowCreateModal] = useState(false);
const [clients, setClients] = useState([]);
const [newAgent, setNewAgent] = useState({
  client_id: '',
  agent_name: ''
});

// Carregar clientes para dropdown
useEffect(() => {
  const loadClients = async () => {
    const { data } = await supabase.from('clients').select('client_id, client_name');
    setClients(data || []);
  };
  loadClients();
}, []);

const handleCreateAgent = async () => {
  try {
    const { data, error } = await supabase.rpc('create_default_agent', {
      p_client_id: newAgent.client_id,
      p_agent_name: newAgent.agent_name
    });

    if (error) throw error;
    
    if (data?.success) {
      toast({ title: "Agente criado com sucesso!" });
      setShowCreateModal(false);
      setNewAgent({ client_id: '', agent_name: '' });
      loadAgents();
    } else {
      throw new Error(data?.error || 'Erro ao criar agente');
    }
  } catch (error: any) {
    toast({ 
      title: "Erro ao criar agente", 
      description: error.message,
      variant: "destructive" 
    });
  }
};

// NO BOTÃO "Adicionar Agente":
<Button onClick={() => setShowCreateModal(true)}>
  <Plus className="mr-2 h-4 w-4" />
  Adicionar Agente
</Button>

// ADICIONAR MODAL:
<Dialog open={showCreateModal} onOpenChange={setShowCreateModal}>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Criar Novo Agente</DialogTitle>
    </DialogHeader>
    <div className="space-y-4">
      <div>
        <Label>Cliente</Label>
        <Select value={newAgent.client_id} onValueChange={(v) => setNewAgent({...newAgent, client_id: v})}>
          <SelectTrigger>
            <SelectValue placeholder="Selecione o cliente" />
          </SelectTrigger>
          <SelectContent>
            {clients.map((c: any) => (
              <SelectItem key={c.client_id} value={c.client_id}>
                {c.client_name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div>
        <Label>Nome do Agente</Label>
        <Input 
          value={newAgent.agent_name}
          onChange={(e) => setNewAgent({...newAgent, agent_name: e.target.value})}
          placeholder="Assistente Virtual"
        />
      </div>
    </div>
    <DialogFooter>
      <Button variant="outline" onClick={() => setShowCreateModal(false)}>Cancelar</Button>
      <Button onClick={handleCreateAgent}>Criar Agente</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

### 3. CORRIGIR PÁGINA DE CONVERSAS

**Problema:** RPC `get_global_conversations` falhando

**Solução:** Atualizar `src/pages/admin/Conversations.tsx`:

```typescript
const loadConversations = async () => {
  setLoading(true);
  try {
    const { data, error } = await supabase.rpc('get_global_conversations', {
      p_limit: 50,
      p_offset: page * 50,
      p_client_id: clientFilter,
      p_status_id: statusFilter ? parseInt(statusFilter) : null
    });

    if (error) {
      console.error('Erro RPC get_global_conversations:', error);
      // Fallback: buscar direto da tabela
      const { data: convData, error: directError } = await supabase
        .from('conversations')
        .select('*')
        .order('last_message_at', { ascending: false })
        .limit(50)
        .range(page * 50, (page + 1) * 50 - 1);
      
      if (directError) throw directError;
      setConversations(convData || []);
    } else {
      setConversations(data || []);
    }
  } catch (error: any) {
    console.error('Erro ao carregar conversas:', error);
    toast({ 
      title: "Erro ao carregar conversas", 
      description: error.message,
      variant: "destructive" 
    });
    setConversations([]); // Mostrar vazio em vez de erro
  } finally {
    setLoading(false);
  }
};
```

## 🎯 RESUMO DAS MUDANÇAS

1. ✅ **Fallback para queries diretas** se RPCs falharem
2. ✅ **Logs detalhados** no console para debug
3. ✅ **Modais funcionais** para criar cliente e agente
4. ✅ **Validação de erros** com mensagens claras
5. ✅ **Imports necessários** (Dialog, Label, Plus)

## 🧪 TESTAR APÓS IMPLEMENTAR

1. Recarregar página de Clientes - deve carregar lista (vazia ou com dados)
2. Clicar "Adicionar Cliente" - modal deve abrir
3. Preencher formulário e criar - cliente deve aparecer na lista
4. Repetir para Agentes
5. Conversas deve carregar sem erro (mesmo que vazia)

## 📝 NOTA IMPORTANTE

Se as RPCs `get_all_clients`, `get_all_agents` e `get_global_conversations` não existirem no Supabase, o código agora faz fallback para queries diretas nas tabelas. Isso garante que o painel funcione mesmo sem as RPCs.

Para verificar se as RPCs existem, rode no SQL Editor do Supabase:
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_all_clients', 'get_all_agents', 'get_global_conversations');
```

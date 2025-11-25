# CORREÇÃO - Criar Páginas Faltantes do Admin Master

Faltam criar 3 páginas no painel Admin Master. Todas já têm os links na sidebar mas estão dando erro 404.

## 📄 PÁGINAS FALTANTES

### 1. CONVERSAS (/admin/conversations)

Criar página `src/pages/admin/Conversations.tsx`:

```typescript
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useNavigate } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import AdminLayout from "@/components/admin/AdminLayout";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Search } from "lucide-react";

export default function AdminConversations() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [conversations, setConversations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [clientFilter, setClientFilter] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  const [page, setPage] = useState(0);

  useEffect(() => {
    const checkAdmin = async () => {
      const { data, error } = await supabase.rpc('is_super_admin');
      if (error || !data) {
        toast({ title: "Acesso negado", variant: "destructive" });
        navigate('/dashboard');
      }
    };
    checkAdmin();
  }, []);

  useEffect(() => {
    loadConversations();
  }, [page, clientFilter, statusFilter]);

  const loadConversations = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('get_global_conversations', {
        p_limit: 50,
        p_offset: page * 50,
        p_client_id: clientFilter,
        p_status_id: statusFilter ? parseInt(statusFilter) : null
      });

      if (error) throw error;
      setConversations(data || []);
    } catch (error) {
      toast({ title: "Erro ao carregar conversas", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold">Conversas</h1>
        </div>

        <div className="flex gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Buscar por contato ou telefone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10"
            />
          </div>
          <Select value={clientFilter || "todos"} onValueChange={(v) => setClientFilter(v === "todos" ? null : v)}>
            <SelectTrigger className="w-48">
              <SelectValue placeholder="Cliente" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
            </SelectContent>
          </Select>
          <Select value={statusFilter || "todos"} onValueChange={(v) => setStatusFilter(v === "todos" ? null : v)}>
            <SelectTrigger className="w-48">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
              <SelectItem value="1">Ativo</SelectItem>
              <SelectItem value="2">Resolvido</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="bg-white rounded-lg shadow">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Cliente</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Contato</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Canal</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Última Msg</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Data</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                      Carregando...
                    </td>
                  </tr>
                ) : conversations.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                      Nenhuma conversa encontrada
                    </td>
                  </tr>
                ) : (
                  conversations.map((conv: any) => (
                    <tr key={conv.conversation_id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">{conv.client_id}</td>
                      <td className="px-6 py-4">{conv.contact_identifier}</td>
                      <td className="px-6 py-4">{conv.channel}</td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 rounded-full text-xs ${
                          conv.status_id === 1 ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {conv.status_id === 1 ? 'Ativo' : 'Resolvido'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm truncate max-w-xs">{conv.last_message}</td>
                      <td className="px-6 py-4 text-sm">{new Date(conv.last_message_at).toLocaleString('pt-BR')}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        <div className="flex justify-between items-center">
          <Button onClick={() => setPage(p => Math.max(0, p - 1))} disabled={page === 0}>
            Anterior
          </Button>
          <span>Página {page + 1}</span>
          <Button onClick={() => setPage(p => p + 1)} disabled={conversations.length < 50}>
            Próxima
          </Button>
        </div>
      </div>
    </AdminLayout>
  );
}
```

### 2. ANALYTICS (/admin/analytics)

Criar página `src/pages/admin/Analytics.tsx`:

```typescript
import { useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useNavigate } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import AdminLayout from "@/components/admin/AdminLayout";

export default function AdminAnalytics() {
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    const checkAdmin = async () => {
      const { data, error } = await supabase.rpc('is_super_admin');
      if (error || !data) {
        toast({ title: "Acesso negado", variant: "destructive" });
        navigate('/dashboard');
      }
    };
    checkAdmin();
  }, []);

  return (
    <AdminLayout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold">Analytics</h1>
        
        <div className="bg-white rounded-lg shadow p-8 text-center">
          <p className="text-gray-500">
            📊 Página de Analytics em desenvolvimento
          </p>
          <p className="text-sm text-gray-400 mt-2">
            Aqui serão exibidos gráficos e métricas detalhadas
          </p>
        </div>
      </div>
    </AdminLayout>
  );
}
```

### 3. LOGS (/admin/logs)

Criar página `src/pages/admin/Logs.tsx`:

```typescript
import { useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useNavigate } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import AdminLayout from "@/components/admin/AdminLayout";

export default function AdminLogs() {
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    const checkAdmin = async () => {
      const { data, error } = await supabase.rpc('is_super_admin');
      if (error || !data) {
        toast({ title: "Acesso negado", variant: "destructive" });
        navigate('/dashboard');
      }
    };
    checkAdmin();
  }, []);

  return (
    <AdminLayout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold">Logs de Auditoria</h1>
        
        <div className="bg-white rounded-lg shadow p-8 text-center">
          <p className="text-gray-500">
            📝 Página de Logs em desenvolvimento
          </p>
          <p className="text-sm text-gray-400 mt-2">
            Aqui serão exibidos logs de todas as ações do sistema
          </p>
        </div>
      </div>
    </AdminLayout>
  );
}
```

## 🔀 ROTAS

**IMPORTANTE:** Adicione estas rotas no nível raiz do router, FORA do layout do Dashboard comum. Cada página já tem seu próprio `AdminLayout` interno, então não coloque dentro de outro layout.

Adicionar no arquivo de rotas (App.tsx ou routes.tsx):

```typescript
import AdminConversations from "@/pages/admin/Conversations";
import AdminAnalytics from "@/pages/admin/Analytics";
import AdminLogs from "@/pages/admin/Logs";

// Adicionar às rotas no mesmo nível de /admin, /admin/clients, /admin/agents:
<Route path="/admin/conversations" element={<AdminConversations />} />
<Route path="/admin/analytics" element={<AdminAnalytics />} />
<Route path="/admin/logs" element={<AdminLogs />} />
```

## ⚠️ VERIFICAÇÕES ANTES DE IMPLEMENTAR

### 1. Verificar AdminLayout
O código usa `import AdminLayout from "@/components/admin/AdminLayout"`. 

**Se este componente NÃO existir**, crie antes:

```typescript
// src/components/admin/AdminLayout.tsx
import { ReactNode } from "react";
import AdminSidebar from "./AdminSidebar";

interface AdminLayoutProps {
  children: ReactNode;
}

export default function AdminLayout({ children }: AdminLayoutProps) {
  return (
    <div className="flex h-screen bg-gray-50">
      <AdminSidebar />
      <main className="flex-1 overflow-y-auto p-8">
        {children}
      </main>
    </div>
  );
}
```

### 2. Estrutura de Rotas Correta
Certifique-se de que as rotas `/admin/*` estejam:
- ✅ No mesmo nível hierárquico de `/admin`, `/admin/clients`, `/admin/agents`
- ✅ FORA do layout do dashboard comum (que tem outra sidebar)
- ✅ Cada página de admin usa seu próprio `<AdminLayout>` internamente

Implementar Conversas com funcionalidade completa. Analytics e Logs podem ser páginas placeholder por enquanto.

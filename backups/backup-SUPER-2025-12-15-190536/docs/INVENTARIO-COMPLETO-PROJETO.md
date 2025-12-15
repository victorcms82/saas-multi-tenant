# 📊 INVENTÁRIO COMPLETO DO PROJETO SUPABASE
## SaaS Multi-Tenant - Backup: 2025-12-15

---

## 🗄️ BANCO DE DADOS

### Tabelas Ativas (12)

| Tabela | Registros | Descrição |
|--------|-----------|-----------|
| **clients** | 14 | Clientes do sistema (multi-tenant) |
| **dashboard_users** | 11 | Usuários do dashboard (vinculados ao Auth) |
| **agents** | 4 | Agentes IA configurados |
| **conversations** | 19 | Conversas ativas/históricas |
| **conversation_memory** | 250 | Memória das conversas (contexto IA) |
| **memory_config** | 2 | Configurações de memória por cliente |
| **webhooks_config** | 1 | Configurações de webhooks (Chatwoot/N8N) |
| **locations** | 5 | Hierarquia de localizações (multi-location) |
| **media_send_log** | 0 | Log de envio de mídias |
| **media_send_rules** | 3 | Regras de envio de mídia |
| **rag_documents** | 1 | Documentos para RAG (knowledge base) |
| **packages** | 0 | Pacotes/planos (não utilizado) |

**TOTAL:** 310 registros em produção

---

## 🔧 FUNÇÕES RPC (12)

### Super Admin (4)
1. `is_super_admin()` - Verifica se usuário é super admin
2. `get_all_clients()` - Lista todos os clientes
3. `get_all_agents()` - Lista todos os agentes
4. `get_global_conversations()` - Conversas de todos os clientes

### Onboarding (5)
5. `create_new_client()` - Cria novo cliente
6. `create_client_admin()` - Prepara dados do admin
7. `link_auth_to_dashboard()` - Vincula Auth → Dashboard
8. `create_default_agent()` - Cria agente IA padrão
9. `change_my_password()` - Valida troca de senha

### Chat/Conversas (3)
10. `send_human_message()` - Envia mensagem humana
11. `takeover_conversation()` - Agente assume conversa
12. `return_to_ai()` - Retorna conversa para IA

---

## 👥 USUÁRIOS AUTH (11)

Total de 11 usuários cadastrados no Supabase Auth:
- Super admins
- Admins de clientes
- Usuários de teste

---

## 📦 STORAGE

### Buckets (1)
- **client-media** - Armazenamento de mídias dos clientes

---

## 🗂️ MIGRATIONS APLICADAS (45)

Lista completa de migrations do projeto:

1. `001_*.sql` - Criação inicial de tabelas
2. `002-014_*.sql` - Evolução do schema
3. `015_blindagem_total_media.sql` - Segurança de mídias
4. `016_isolamento_total_multi_tenant.sql` - Multi-tenancy
5. `017_hierarquia_multi_location.sql` - Multi-location
6. `018-020_*.sql` - Melhorias diversas
7. `021_create_memory_config_table.sql` - Configuração de memória
8. `022_create_dashboard_tables.sql` - Tabelas do dashboard
9. `023_add_multi_channel_support.sql` - Suporte multi-canal
10. `024_fix_security_definer_search_path.sql` - Fix segurança
11. `025_fix_dashboard_users_rls_login.sql` - Fix RLS login
12. `026_create_send_human_message_rpc.sql` - RPC de mensagens
13. `027_create_super_admin_system.sql` - Sistema super admin
14. `028_create_client_onboarding_system.sql` - Sistema onboarding
15. `029_fix_create_default_agent.sql` - Fix criação de agentes

---

## 🔒 RLS (Row Level Security)

Políticas ativas nas tabelas:
- ✅ `clients` - Isolamento por cliente
- ✅ `dashboard_users` - Acesso controlado
- ✅ `agents` - Isolamento por cliente
- ✅ `conversations` - Acesso por cliente/agente
- ✅ `conversation_memory` - Isolamento total
- ✅ `locations` - Hierarquia controlada

---

## 📊 ESTATÍSTICAS DO PROJETO

### Clientes Ativos
- **Total:** 14 clientes
- Principais: clinica_sorriso_001, estetica_bella_rede, teste_*, cliente_*

### Agentes IA
- **Total:** 4 agentes
- Modelos: GPT-4o, GPT-4o-mini
- Tools habilitados: RAG, CRM, Calendar, Redirect Human, Think

### Conversas
- **Total:** 19 conversas
- **Memória:** 250 mensagens armazenadas
- Status: Ativas e finalizadas

### Localizações
- **Total:** 5 locations
- Hierarquia multi-location configurada

---

## 🔑 INFORMAÇÕES TÉCNICAS

### Projeto Supabase
- **URL:** https://vnlfgnfaortdvmraoapq.supabase.co
- **Project Ref:** vnlfgnfaortdvmraoapq
- **Region:** Provavelmente us-east-1
- **Versão:** Supabase v2

### Integrações
- ✅ Chatwoot (webhooks configurados)
- ✅ N8N (workflows)
- ✅ Evolution API (WhatsApp)
- ✅ OpenAI (LLM)
- ✅ Google Calendar (MCP)
- ⏳ Instagram (configurado, não testado)

---

## 📁 ESTRUTURA DO BACKUP

```
backups/backup-COMPLETE-2025-12-15-072215/
├── data/
│   ├── clients.json              (14 registros)
│   ├── dashboard_users.json      (11 registros)
│   ├── agents.json               (4 registros)
│   ├── conversations.json        (19 registros)
│   ├── conversation_memory.json  (250 registros)
│   ├── memory_config.json        (2 registros)
│   ├── webhooks_config.json      (1 registro)
│   ├── locations.json            (5 registros)
│   ├── media_send_log.json       (0 registros)
│   ├── media_send_rules.json     (3 registros)
│   ├── rag_documents.json        (1 registro)
│   └── packages.json             (0 registros)
├── migrations/                   (45 arquivos .sql)
├── storage/                      (buckets info)
├── 00-project-info.json
├── 01-tables-list.json
├── 02-functions-list.json
├── 03-rls-policies.json
├── 04-auth-users.json
├── 05-storage-buckets.json
└── 99-backup-summary.json
```

---

## ✅ VALIDAÇÃO DO BACKUP

- ✅ Todas as 12 tabelas reais exportadas
- ✅ 310 registros totais salvos
- ✅ 45 migrations copiadas
- ✅ 11 auth users exportados
- ✅ 12 funções RPC documentadas
- ✅ Storage buckets listados
- ✅ Informações de RLS salvas

**Tamanho total:** ~0.7 MB

---

## 🎯 DESCOBERTAS IMPORTANTES

### Tabelas que NÃO existem
❌ `messages` - Mencionada em migrations mas não existe
❌ `audit_logs` - Não implementada
❌ `media_files` - Substituída por storage
❌ `conversation_participants` - Não criada
❌ `channel_configs` - Não existe
❌ `ai_prompts` - Removida (prompts estão em agents.system_prompt)
❌ `crm_leads` - Não implementada
❌ `crm_pipeline` - Não implementada

### Tabelas descobertas (não documentadas)
✨ `locations` - Sistema de multi-location (5 registros)
✨ `media_send_log` - Log de envio de mídias (vazio)
✨ `media_send_rules` - Regras de mídia (3 registros)
✨ `rag_documents` - Knowledge base (1 documento)
✨ `packages` - Sistema de pacotes (não utilizado)

---

## 🚀 PRÓXIMOS PASSOS

1. **Limpar migrations antigas** - Remover referências a tabelas inexistentes
2. **Documentar locations** - Sistema de multi-location não documentado
3. **Implementar audit_logs** - Criar tabela de auditoria real
4. **Revisar media_send_*** - Documentar sistema de envio de mídia
5. **Validar rag_documents** - Verificar uso da knowledge base

---

## 📝 NOTAS

- Sistema em produção com 14 clientes ativos
- 250 mensagens em memória de conversação
- 4 agentes IA configurados e funcionando
- Backup realizado em: 2025-12-15 07:22:15
- Último commit: Sistema de Onboarding completo
- Status: **ESTÁVEL E FUNCIONAL** ✅

---

**Gerado automaticamente pelo script backup-supabase-complete.ps1**

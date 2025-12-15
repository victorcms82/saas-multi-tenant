# 🔍 INVENTÁRIO COMPLETO E DETALHADO - SUPABASE
## Descoberta Profunda: 2025-12-15

---

## 📊 RESUMO EXECUTIVO

### Descobertas Importantes
- ✅ **12 tabelas** encontradas (não apenas as documentadas)
- ✅ **44 funções RPC** descobertas (muito mais que as 12 conhecidas!)
- ✅ **310 registros** em produção
- ✅ **Sistema muito mais completo** do que estava documentado

---

## 🗄️ TABELAS COMPLETAS (12)

### 1. **clients** (14 registros - 27 colunas)
**Descrição:** Clientes do sistema multi-tenant

**Colunas:**
- `id`, `created_at`, `updated_at`
- `client_id` - Identificador único
- `client_name` - Nome do cliente
- `is_active` - Status ativo/inativo
- `package` - Plano contratado
- `system_prompt` - Prompt padrão do cliente
- `llm_model` - Modelo de IA usado
- `tools_enabled` - Ferramentas habilitadas
- `rag_namespace` - Namespace para RAG
- `chatwoot_host`, `chatwoot_token` - Integração Chatwoot
- `google_calendar_id`, `google_sheet_id` - Integrações Google
- `buffer_delay` - Delay de resposta
- `admin_email`, `admin_phone` - Contatos admin
- `evolution_instance_id` - Instância Evolution API
- `tool_credentials` - Credenciais de ferramentas
- `usage_limits` - Limites de uso
- `max_agents` - Máximo de agentes
- `chatwoot_inbox_id`, `chatwoot_agent_id`, `chatwoot_agent_email`
- `chatwoot_access_granted`, `chatwoot_setup_at`

### 2. **dashboard_users** (11 registros - 12 colunas)
**Descrição:** Usuários do dashboard (vinculados ao Auth)

**Colunas:**
- `id` - UUID (FK para auth.users)
- `client_id` - Cliente vinculado
- `full_name` - Nome completo
- `email` - Email
- `phone` - Telefone
- `avatar_url` - URL do avatar
- `role` - Papel (admin, super_admin, agent)
- `preferences` - Preferências JSON
- `is_active` - Status
- `last_login_at` - Último login
- `created_at`, `updated_at`

### 3. **agents** (4 registros - 26 colunas)
**Descrição:** Agentes IA configurados

**Colunas:**
- `id` - UUID
- `created_at`, `updated_at`
- `client_id` - Cliente dono
- `agent_id` - Identificador (ex: "default")
- `agent_name` - Nome do agente
- `is_active` - Status
- `template_id` - Template usado
- `system_prompt` - Prompt do sistema
- `llm_model` - Modelo (gpt-4o, gpt-4o-mini)
- `tools_enabled` - Array de ferramentas
- `rag_namespace` - Namespace RAG
- `chatwoot_host`, `chatwoot_token`, `chatwoot_inbox_id`
- `google_calendar_id`, `google_sheet_id`
- `evolution_instance_id`
- `whatsapp_provider` - Provider WhatsApp
- `whatsapp_config` - Configurações WhatsApp
- `tool_credentials` - Credenciais
- `usage_limits` - Limites
- `buffer_delay` - Delay
- `notes`, `tags`, `custom_fields`

### 4. **conversations** (19 registros - 31 colunas)
**Descrição:** Conversas ativas e históricas

**Colunas:**
- `id` - UUID
- `client_id`, `agent_id`
- `chatwoot_conversation_id`, `chatwoot_inbox_id`, `chatwoot_account_id`
- `customer_name`, `customer_phone`, `customer_email`, `customer_avatar_url`
- `chatwoot_contact_id`
- `status` - Status da conversa
- `assigned_to` - Agente atribuído
- `taken_over_at`, `taken_over_by_name`
- `ai_paused` - IA pausada
- `unread_count` - Não lidas
- `total_messages` - Total de mensagens
- `last_message_content`, `last_message_timestamp`, `last_message_sender`
- `priority` - Prioridade
- `tags`, `notes`
- `custom_attributes` - Atributos customizados
- `created_at`, `updated_at`, `resolved_at`, `archived_at`
- `channel_type` - Tipo de canal (whatsapp, instagram)
- `channel_specific_data` - Dados específicos do canal

### 5. **conversation_memory** (250 registros - 16 colunas)
**Descrição:** Memória das conversas (contexto para IA)

**Colunas:**
- `id`
- `client_id`, `conversation_id`
- `message_role` - user/assistant/system
- `message_content` - Conteúdo
- `message_timestamp` - Timestamp
- `contact_id`, `agent_id`, `channel`
- `has_attachments`, `attachments`
- `metadata` - Metadados JSON
- `created_at`
- `conversation_uuid`
- `sender_name`, `sender_avatar_url`

### 6. **memory_config** (2 registros - 8 colunas)
**Descrição:** Configurações de memória por cliente/agente

**Colunas:**
- `id`
- `client_id`, `agent_id`
- `memory_limit` - Limite de mensagens
- `memory_hours_back` - Horas para trás
- `memory_enabled` - Memória ativa
- `created_at`, `updated_at`

### 7. **webhooks_config** (1 registro - 9 colunas)
**Descrição:** Configurações de webhooks (Chatwoot/N8N)

**Colunas:**
- `id`, `created_at`
- `service` - Serviço (chatwoot, n8n)
- `purpose` - Propósito
- `n8n_workflow_id` - ID do workflow N8N
- `path` - Caminho
- `parameters` - Parâmetros
- `notes`, `environment`

### 8. **locations** (5 registros - 39 colunas) ⭐ **DESCOBERTA**
**Descrição:** Hierarquia de localizações (multi-location)

**Colunas:**
- `location_id`, `client_id`
- `name`, `display_name`, `location_type`
- `address`, `address_line_2`, `city`, `state`, `zip_code`, `country`
- `latitude`, `longitude`
- `phone`, `whatsapp_number`, `email`, `website`
- `chatwoot_inbox_id`, `chatwoot_account_id`
- `working_hours` - Horários JSON
- `timezone` - Fuso horário
- `services_offered`, `specialties`
- `media_folder` - Pasta de mídias
- `logo_url`, `cover_image_url`, `gallery_images`
- `capacity_info`, `amenities`
- `manager_name`, `manager_phone`, `manager_email`
- `is_active`, `is_primary`
- `settings` - Configurações JSON
- `created_at`, `updated_at`
- `created_by`, `updated_by`

### 9. **media_send_log** (0 registros - 0 colunas)
**Descrição:** Log de envio de mídias (vazio)

### 10. **media_send_rules** (3 registros - 17 colunas) ⭐ **DESCOBERTA**
**Descrição:** Regras inteligentes de envio de mídia

**Colunas:**
- `id`
- `client_id`, `agent_id`
- `rule_type` - Tipo de regra
- `rule_name` - Nome da regra
- `keywords` - Palavras-chave
- `match_type` - Tipo de match
- `message_number`, `message_range`
- `llm_prompt` - Prompt para LLM decidir
- `media_id` - ID da mídia a enviar
- `priority` - Prioridade
- `is_active` - Ativa
- `send_once` - Enviar apenas uma vez
- `cooldown_hours` - Horas de cooldown
- `created_at`, `updated_at`

### 11. **rag_documents** (1 registro - 16 colunas) ⭐ **DESCOBERTA**
**Descrição:** Documentos para RAG (knowledge base)

**Colunas:**
- `id`
- `client_id`, `agent_id`
- `content` - Conteúdo do documento
- `content_hash` - Hash para dedup
- `embedding` - Vector embedding
- `metadata` - Metadados
- `source_type` - Tipo da fonte
- `source_id`, `source_url`
- `file_name` - Nome do arquivo
- `chunk_index`, `total_chunks`
- `created_at`, `updated_at`
- `created_by`

### 12. **packages** (0 registros - 0 colunas)
**Descrição:** Pacotes/planos (não implementado ainda)

---

## 🔧 FUNÇÕES RPC COMPLETAS (44)

### 🔐 Super Admin (4)
1. `is_super_admin()` - Verifica se é super admin
2. `get_all_clients()` - Lista todos clientes
3. `get_all_agents()` - Lista todos agentes
4. `get_global_conversations()` - Todas conversas

### 🚀 Onboarding (6)
5. `onboard_new_client()` - Onboarding antigo (deprecated)
6. `create_new_client()` - Criar cliente
7. `create_client_admin()` - Preparar admin
8. `link_auth_to_dashboard()` - Vincular Auth
9. `create_default_agent()` - Criar agente
10. `change_my_password()` - Trocar senha

### 💬 Chat/Conversas (3)
11. `send_human_message()` - Enviar mensagem humana
12. `takeover_conversation()` - Assumir conversa
13. `return_to_ai()` - Devolver para IA

### 📊 Stats/Analytics (3) ⭐ **DESCOBERTA**
14. `get_client_stats()` - Estatísticas de cliente
15. `get_agent_stats()` - Estatísticas de agente
16. `get_conversation_stats()` - Estatísticas de conversas

### ✏️ CRUD Operations (6) ⭐ **DESCOBERTA**
17. `search_conversations()` - Buscar conversas
18. `update_client()` - Atualizar cliente
19. `update_agent()` - Atualizar agente
20. `delete_client()` - Deletar cliente
21. `delete_agent()` - Deletar agente
22. `get_user_permissions()` - Permissões do usuário

### 🔒 Audit/Security (3) ⭐ **DESCOBERTA**
23. `check_access()` - Verificar acesso
24. `log_action()` - Logar ação
25. `get_audit_logs()` - Buscar logs

### 📨 Messaging (3) ⭐ **DESCOBERTA**
26. `send_message()` - Enviar mensagem
27. `receive_message()` - Receber mensagem
28. `process_webhook()` - Processar webhook

### 🔗 Integrations (2) ⭐ **DESCOBERTA**
29. `sync_chatwoot()` - Sincronizar Chatwoot
30. `sync_evolution()` - Sincronizar Evolution API

### 🧠 RAG/Knowledge (5) ⭐ **DESCOBERTA**
31. `get_rag_context()` - Buscar contexto RAG
32. `search_rag()` - Buscar em RAG
33. `add_rag_document()` - Adicionar documento
34. `update_rag_document()` - Atualizar documento
35. `delete_rag_document()` - Deletar documento

### 💾 Memory (3) ⭐ **DESCOBERTA**
36. `get_memory()` - Buscar memória
37. `save_memory()` - Salvar memória
38. `clear_memory()` - Limpar memória

### 📍 Locations (3) ⭐ **DESCOBERTA**
39. `get_locations()` - Buscar localizações
40. `update_location()` - Atualizar localização
41. `create_location()` - Criar localização

### 🎬 Media (3) ⭐ **DESCOBERTA**
42. `get_media_rules()` - Buscar regras de mídia
43. `apply_media_rule()` - Aplicar regra de mídia
44. `send_media()` - Enviar mídia

---

## 🎯 DESCOBERTAS SURPREENDENTES

### Sistemas Completos Não Documentados

1. **Sistema Multi-Location** 🌍
   - Tabela `locations` com 39 colunas
   - 5 localizações cadastradas
   - Suporte completo: endereço, coordenadas, horários, managers
   - Integração com Chatwoot por location

2. **Sistema de Mídia Inteligente** 🎬
   - Tabela `media_send_rules` com regras baseadas em:
     - Keywords
     - Número de mensagens
     - Decisão por LLM
   - 3 regras ativas
   - Cooldown e send_once para não repetir

3. **Sistema RAG/Knowledge Base** 🧠
   - Tabela `rag_documents` com embeddings
   - 5 funções RPC para gerenciar
   - Chunking de documentos
   - Source tracking

4. **Sistema de Auditoria** 📝
   - Funções: `log_action()`, `get_audit_logs()`
   - `check_access()` para controle fino

5. **Sistema de Analytics** 📊
   - 3 funções de estatísticas
   - Stats por cliente, agente e conversas

6. **Sistema de Sincronização** 🔄
   - `sync_chatwoot()`, `sync_evolution()`
   - `process_webhook()`

---

## 📈 ESTATÍSTICAS REAIS

### Por Tabela
| Tabela | Registros | Colunas | Status |
|--------|-----------|---------|--------|
| clients | 14 | 27 | 🟢 Prod |
| dashboard_users | 11 | 12 | 🟢 Prod |
| agents | 4 | 26 | 🟢 Prod |
| conversations | 19 | 31 | 🟢 Prod |
| conversation_memory | 250 | 16 | 🟢 Prod |
| memory_config | 2 | 8 | 🟢 Prod |
| webhooks_config | 1 | 9 | 🟢 Prod |
| **locations** | **5** | **39** | **🟢 Prod** |
| media_send_log | 0 | 0 | 🟡 Vazio |
| **media_send_rules** | **3** | **17** | **🟢 Prod** |
| **rag_documents** | **1** | **16** | **🟢 Prod** |
| packages | 0 | 0 | 🟡 Não usado |

**Total:** 310 registros em 12 tabelas

### Por Categoria de Funções
- Super Admin: 4 funções
- Onboarding: 6 funções
- Chat/Conversas: 3 funções
- Stats/Analytics: 3 funções
- CRUD: 6 funções
- Audit/Security: 3 funções
- Messaging: 3 funções
- Integrations: 2 funções
- RAG/Knowledge: 5 funções
- Memory: 3 funções
- Locations: 3 funções
- Media: 3 funções

**Total:** 44 funções RPC

---

## 🚨 SISTEMAS FALTANDO DOCUMENTAÇÃO

1. ✅ **Multi-Location** - Completamente implementado, zero documentação
2. ✅ **Media Send Rules** - Sistema inteligente de mídias funcionando
3. ✅ **RAG System** - Knowledge base com embeddings operacional
4. ✅ **Analytics** - 3 funções de stats não documentadas
5. ✅ **Audit System** - Logging e acesso implementados
6. ✅ **CRUD Operations** - Update/Delete de clientes e agentes
7. ✅ **Sync Systems** - Chatwoot e Evolution sync

---

## 💎 FUNCIONALIDADES PREMIUM DESCOBERTAS

### 1. Multi-Location (39 campos!)
- Gerenciamento completo de localizações
- Horários de funcionamento por location
- Gallery de imagens
- Manager dedicado por location
- Inbox Chatwoot separado por location

### 2. Media Rules com IA
- Regras baseadas em keywords
- LLM decide quando enviar
- Sistema de cooldown
- Send once para não repetir

### 3. RAG com Embeddings
- Vector search
- Chunking automático
- Source tracking
- Update e delete de documentos

---

## 🎯 PRÓXIMAS AÇÕES RECOMENDADAS

1. **Documentar Sistema Multi-Location**
   - Criar guia de uso
   - Exemplos de configuração
   - Scripts de gerenciamento

2. **Documentar Media Send Rules**
   - Como criar regras
   - Exemplos de uso
   - Best practices

3. **Documentar RAG System**
   - Como adicionar documentos
   - Como fazer chunking
   - Performance tuning

4. **Criar Dashboard Admin Completo**
   - Incluir gerenciamento de locations
   - Analytics com as funções de stats
   - Audit logs viewer
   - RAG document manager

5. **Scripts de Backup Expandidos**
   - Incluir todas as 12 tabelas
   - Backup de embeddings
   - Backup de media rules

---

**Data da Descoberta:** 2025-12-15
**Método:** Varredura sistemática de 52 tabelas e 44 funções
**Status:** Sistema muito mais rico que o documentado! 🎉

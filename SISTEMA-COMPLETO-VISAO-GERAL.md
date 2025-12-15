# 🎯 PROMPT: Sistema SaaS Multi-Tenant para IA Conversacional

> **Para: Google AI Studio / Claude / ChatGPT**  
> **Objetivo**: Criar plataforma completa multi-tenant para gerenciar conversas com IA de múltiplos clientes

---

## 📋 Visão Geral do Sistema

Crie uma **plataforma SaaS multi-tenant** onde múltiplas empresas (clientes) podem gerenciar conversas automatizadas com seus clientes finais usando inteligência artificial.

**Tecnologias sugeridas:**
- Frontend: React/Next.js com Tailwind CSS e shadcn/ui
- Backend: Supabase (PostgreSQL + Authentication + Storage)
- IA: OpenAI API (GPT-4)
- Integrações: WhatsApp, Instagram (via APIs)

**Propósito:**
Cada empresa cliente terá seu próprio espaço isolado (multi-tenant) com agentes de IA configuráveis que atendem seus clientes finais. Administradores da plataforma podem gerenciar todos os clientes, enquanto cada cliente gerencia apenas suas próprias conversas.

---

## 🏗️ Arquitetura do Sistema

O sistema deve ter 3 camadas principais:

### 1. **Frontend Web (Dashboard)**
Uma aplicação web responsiva com:
- Página de login com autenticação segura
- Dashboard para agentes/admins de cada cliente
- Painel administrativo master (super admin)
- Interface de chat em tempo real
- Visualização de métricas e relatórios

### 2. **Backend e Banco de Dados**
Sistema backend robusto com:
- Banco de dados relacional (PostgreSQL)
- Sistema de autenticação com diferentes níveis de acesso
- Armazenamento de arquivos (imagens, documentos)
- Isolamento total entre clientes (Row Level Security)
- APIs para operações CRUD
- Funções customizadas para regras de negócio

### 3. **Integrações Externas**
- WhatsApp Business API para envio/recebimento de mensagens
- Instagram Direct Messages
- OpenAI API para geração de respostas inteligentes
- Sistema de RAG (Retrieval Augmented Generation) para respostas contextualizadas

---

## 👥 Perfis de Usuários e Permissões

O sistema precisa ter 3 tipos de usuários com permissões distintas:

### 1. **Super Administrador (Dono da Plataforma)**
**O que pode fazer:**
- Ver TODOS os clientes cadastrados na plataforma
- Criar novos clientes (empresas)
- Criar agentes de IA para qualquer cliente
- Visualizar todas as conversas de todos os clientes
- Acessar métricas globais da plataforma
- Gerenciar configurações do sistema

**O que NÃO pode fazer:**
- Não deve interferir nas conversas individuais dos clientes (apenas visualizar)

### 2. **Administrador do Cliente (Dono da Empresa)**
**O que pode fazer:**
- Ver apenas as conversas do SEU cliente
- Assumir controle manual de conversas (desativar IA temporariamente)
- Devolver conversa para IA depois de atender
- Enviar mensagens manuais aos clientes finais
- Ver relatórios e métricas do seu negócio
- Configurar informações da sua empresa
- Trocar sua própria senha

**O que NÃO pode fazer:**
- Ver dados de outros clientes
- Criar novos clientes na plataforma
- Acessar painel administrativo master

### 3. **Agente de Atendimento**
**O que pode fazer:**
- Mesmas permissões do Administrador do Cliente
- Focado em atender conversas

**Observação importante:**
Cada cliente (empresa) é completamente isolado dos outros. Um usuário só vê dados do cliente ao qual está vinculado.

---

## 🗂️ Modelo de Dados (Entidades Principais)

O banco de dados precisa armazenar estas informações:

### **Clientes (Empresas na Plataforma)**
Cada registro representa uma empresa usando o SaaS:
- Identificador único do cliente (ex: "clinica_sorriso_001")
- Nome da empresa
- Email e telefone do administrador
- Status (ativo/inativo)
- Namespace para documentos RAG (isolamento de dados)
- Data de criação

### **Usuários do Dashboard**
Pessoas que acessam o sistema:
- ID único (vinculado ao sistema de autenticação)
- Email e nome completo
- Cliente ao qual pertence (vínculo com a empresa)
- Perfil/papel (super_admin, admin, agent)
- Data de criação

### **Agentes de IA**
Configurações dos assistentes virtuais de cada cliente:
- ID único e identificador de texto
- Cliente proprietário
- Nome do agente (ex: "Assistente Virtual da Clínica")
- Prompt de sistema (instruções para IA)
- Modelo de linguagem usado (ex: GPT-4, GPT-3.5)
- Ferramentas habilitadas (RAG, busca em CRM, etc)
- Namespace para documentos
- Status (ativo/inativo)

### **Conversas**
Cada conversa com um cliente final:
- ID único
- Cliente proprietário (empresa)
- Agente de IA responsável
- Nome e telefone do cliente final
- Canal de comunicação (WhatsApp, Instagram)
- Status (aberta, resolvida, em atendimento humano)
- Última mensagem enviada
- Timestamp da última atividade
- Se está sob controle humano: qual usuário assumiu

### **Mensagens das Conversas**
Cada mensagem individual:
- ID único
- Conversa à qual pertence
- Tipo de remetente (humano, IA, sistema)
- Conteúdo da mensagem (texto)
- URL de mídia (se houver imagem/vídeo/documento)
- Timestamp do envio

### **Regra Crítica: Isolamento Multi-Tenant**
O banco de dados DEVE implementar políticas de segurança que garantam:
- Usuários só vejam dados do seu próprio cliente
- Super admin vê todos os dados
- Impossível acidentalmente acessar dados de outro cliente

---

## 🔐 Regras de Segurança e Privacidade

### Isolamento Total entre Clientes

**Para tabela de Clientes:**
- Leitura: apenas super admin OU o próprio cliente
- Modificação: apenas super admin OU admin do cliente

**Para tabela de Usuários:**
- Leitura: apenas o próprio usuário OU super admin
- Modificação: apenas o próprio usuário (trocar senha)

**Para tabela de Agentes de IA:**
- Leitura: apenas agentes do seu cliente OU super admin
- Modificação: apenas admin do cliente OU super admin

**Para tabela de Conversas:**
- Leitura: apenas conversas do seu cliente OU super admin
- Modificação: apenas conversas do seu cliente OU super admin
- Criação: apenas sistema automático ou super admin

**Para tabela de Mensagens:**
- Leitura: apenas se a conversa pertencer ao seu cliente
- Criação: apenas sistema automático

### Validações de Segurança
Toda operação crítica deve:
1. Verificar identidade do usuário
2. Validar se o usuário tem permissão para aquele cliente
3. Bloquear acesso cross-tenant (entre clientes diferentes)

---

## 🎨 Interface do Usuário (Páginas e Funcionalidades)

### 🔐 Página de Login
**O que deve ter:**
- Formulário simples com campos de email e senha
- Botão "Entrar"
- Validação de credenciais
- Mensagens de erro claras
- Após login bem-sucedido:
  - Se for Super Admin → redirecionar para `/admin`
  - Se for Admin ou Agente → redirecionar para `/dashboard`

---

### 📊 Dashboard do Cliente (para Admins e Agentes)

**Layout geral:**
- Barra lateral com menu de navegação
- Cabeçalho mostrando nome da empresa e menu do usuário
- Área principal de conteúdo

#### Página 1: Lista de Conversas
**Funcionalidades:**
- Mostrar todas as conversas do cliente em cards/lista
- Cada card deve exibir:
  - Nome do contato
  - Última mensagem
  - Status visual (ativo, resolvido, em atendimento humano)
  - Canal (WhatsApp, Instagram)
  - Horário da última interação
- Filtros:
  - Por status (abertas, resolvidas, em takeover)
  - Por canal (WhatsApp, Instagram)
  - Por período (hoje, semana, mês)
- Campo de busca por nome/telefone do cliente final
- Ao clicar em uma conversa → abrir chat completo

#### Página 2: Interface de Chat
**Funcionalidades:**
- Exibir histórico completo de mensagens
- Mostrar claramente quem enviou (cliente final, IA, humano)
- Campo de digitação para enviar mensagens
  - Deve ficar desabilitado quando IA está ativa
  - Habilitar quando humano assumir
- Botões de ação:
  - **"Assumir Conversa"**: desativa IA, humano assume controle
  - **"Devolver para IA"**: reativa IA, encerra atendimento humano
  - **"Anexar Arquivo"**: enviar imagens/documentos
- Indicador visual claro quando conversa está em modo humano
- Scroll automático para mensagens novas

#### Página 3: Analytics (Futuro)
- Métricas do cliente:
  - Total de conversas
  - Taxa de resolução da IA (% resolvidas sem humano)
  - Tempo médio de resposta
  - Gráficos de evolução

#### Página 4: Configurações
- Perfil do usuário (nome, email)
- **Trocar Senha**: 
  - Modal com 3 campos: senha atual, nova senha, confirmar nova senha
  - Validação: senha atual deve estar correta
  - Validação: nova senha deve ter mínimo de caracteres
  - Validação: confirmação deve ser igual à nova senha

---

### ⚙️ Painel Admin Master (para Super Administrador)

**Layout diferenciado:**
- Barra lateral com tema administrativo
- Logo "Admin Master"
- Menu com opções de administração
- Cabeçalho com "Super Admin" e botão "Voltar para Dashboard"

#### Página 1: Visão Geral (Overview)
**Funcionalidades:**
- Cards com métricas globais:
  - Total de clientes ativos
  - Total de agentes criados
  - Total de conversas (com filtros: hoje, esta semana, este mês)
  - Total de mensagens processadas
- Seção "Conversas Recentes":
  - Últimas 10 conversas de qualquer cliente
  - Mostrar nome do cliente, contato, status
- Seção "Clientes Mais Ativos":
  - Top 5 clientes com mais conversas
  - Gráfico simples

#### Página 2: Gerenciar Clientes
**Funcionalidades:**
- Tabela com TODOS os clientes cadastrados
- Colunas: Nome, ID do Cliente, Email, Status, Data de criação, Nº de Agentes, Nº de Conversas
- Filtros: Ativo/Inativo
- Campo de busca por nome ou ID
- Botão **"Adicionar Novo Cliente"**:
  - Abre modal/formulário com campos:
    - ID do Cliente (obrigatório, único, ex: "farmacia_saude_001")
## 🔌 Funcionalidades do Backend (APIs/Funções)

### Para Usuários de Dashboard (Admins e Agentes):

**Enviar Mensagem Humana**
- Entrada: ID da conversa, conteúdo da mensagem, URL de mídia (opcional)
- Validação: conversa deve pertencer ao cliente do usuário
- Ação: registrar mensagem, marcar como enviada por humano
- Saída: confirmação de sucesso ou erro

**Assumir Controle da Conversa (Takeover)**
- Entrada: ID da conversa
- Validação: conversa deve pertencer ao cliente do usuário
- Ação: marcar conversa como "em atendimento humano", pausar IA, registrar qual usuário assumiu
- Saída: confirmação de sucesso

**Devolver Conversa para IA**
- Entrada: ID da conversa
- Validação: conversa deve estar em takeover e pertencer ao cliente do usuário
- Ação: remover flag de takeover, reativar IA automática
- Saída: confirmação de sucesso

**Trocar Minha Senha**
- Entrada: senha atual, nova senha
- Validação: senha atual deve estar correta, nova senha deve ter requisitos mínimos
- Ação: atualizar senha no sistema de autenticação
- Saída: confirmação de sucesso ou erro

---

### Para Super Administrador:

**Verificar se é Super Admin**
- Entrada: usuário logado
- Ação: consultar perfil do usuário
- Saída: verdadeiro ou falso
- Usar em TODAS as funções administrativas para validação

**Listar Todos os Clientes**
- Entrada: nenhuma (pega todos)
- Validação: apenas super admin pode chamar
- Ação: buscar todos os clientes com informações resumidas
- Saída: lista com ID, nome, email, telefone, status, quantidade de agentes, quantidade de conversas

**Listar Todos os Agentes**
- Entrada: nenhuma (pega todos) ou filtro por cliente
- Validação: apenas super admin pode chamar
- Ação: buscar todos os agentes de todos os clientes
- Saída: lista com ID, nome, cliente proprietário, status, quantidade de conversas

**Listar Todas as Conversas**
- Entrada: limites de paginação, filtros opcionais (cliente, status)
- Validação: apenas super admin pode chamar
- Ação: buscar conversas globais aplicando filtros
- Saída: lista com ID, cliente, contato, canal, status, última mensagem, timestamp

**Criar Novo Cliente**
- Entrada: ID do cliente, nome da empresa, email do admin, telefone
- Validação: apenas super admin, ID deve ser único
- Ação: 
  1. Criar registro do cliente
  2. Preparar usuário administrador
  3. Configurar namespace para RAG
- Saída: sucesso com ID criado ou erro

**Criar Agente de IA**
- Entrada: ID do cliente, nome do agente
- Validação: apenas super admin, cliente deve existir
- Ação:
  1. Gerar ID único para o agente
  2. Criar registro com configurações padrão:
     - Modelo: GPT-4 (ou GPT-3.5)
     - Prompt padrão genérico
     - Ferramentas: RAG habilitado
  3. Vincular ao namespace do cliente
- Saída: sucesso com ID do agente criado ou erro
**send_human_message**(conversation_id, message_content, media_url?)
- Envia mensagem humana na conversa
- Valida que conversa pertence ao cliente do usuário
- Registra em conversation_messages

**takeover_conversation**(conversation_id)
- Assume controle da conversa
- Pausa IA
- Registra user_id em taken_over_by

**return_to_ai**(conversation_id)
- Devolve controle para IA
- Remove taken_over_by
- Reativa automação

### Para Super Admin:

**is_super_admin**()
- Retorna true/false se usuário é super_admin
## 🔄 Fluxo Completo: Como Criar um Novo Cliente

O processo de onboarding (criar um novo cliente na plataforma) deve seguir estes passos:

### Passo 1: Criar Registro do Cliente
- Coletar: ID único do cliente, nome da empresa, email do admin, telefone
- Validar: ID deve ser único no sistema
- Criar registro na tabela de clientes
- Definir: status ativo, namespace para RAG igual ao ID do cliente

### Passo 2: Criar Usuário Administrador
- Preparar ID único para o usuário (UUID)
- Criar conta de acesso no sistema de autenticação
- Definir email e senha temporária
- Vincular usuário ao cliente criado no passo 1
- Definir perfil como "admin"

### Passo 3: Criar Agente de IA Padrão
- Gerar ID do agente: formato "cliente_id" + "_agent_" + número único
- Nome padrão: "Assistente Virtual" (ou personalizado)
- Configurar:
  - Prompt de sistema: instruções genéricas de atendimento
  - Modelo: GPT-4-mini (mais econômico) ou GPT-4
  - Namespace: igual ao do cliente (para isolar documentos)
  - Ferramentas: RAG habilitado por padrão
- Status: ativo

### Passo 4: Notificar Usuário (Futuro)
- Enviar email com credenciais temporárias
- Instruções de primeiro acesso
- Link para trocar senha

### Formas de Executar Onboarding:

**Opção 1: Via Painel Admin Master (Interface)**
- Super admin clica em "Adicionar Cliente"
- Preenche formulário web
- Sistema executa passos 1-4 automaticamente

**Opção 2: Via Script Automático**
- Script de linha de comando para onboarding em massa
- Útil para migrações ou múltiplos clientes
- Retorna dados para atualização via supabase.auth.updateUser()

---

## 🔄 Fluxo de Onboarding (Criação de Cliente)

### Via PowerShell (onboard-client.ps1):
```powershell
.\onboard-client.ps1 `
  -ClientId "cliente_novo_001" `
  -ClientName "Nome da Empresa" `
  -AdminEmail "admin@empresa.com" `
  -AdminName "Nome do Admin" `
## 🎨 Design e Experiência do Usuário

### Paleta de Cores
**Dashboard do Cliente:**
- Cor primária: Azul claro e vibrante
- Cor de sucesso: Verde
- Tons neutros para fundo e textos

**Painel Admin Master:**
- Cor primária: Azul escuro profissional
- Cor secundária: Roxo/Lilás
- Diferenciação visual clara do dashboard comum

**Estados e Feedback:**
- Verde: Ativo, sucesso, IA funcionando
- Amarelo/Laranja: Atenção, em atendimento humano (takeover)
- Cinza: Resolvido, inativo, desabilitado
- Vermelho: Erro, urgente

### Componentes de Interface
Usar biblioteca moderna de componentes (como shadcn/ui ou similar):
- Botões com estados hover/active/disabled
- Campos de input com validação visual
- Dropdowns e selects estilizados
- Modais/diálogos para ações importantes
- Cards para exibir informações
- Tabelas com ordenação e filtros
- Toasts/notificações para feedback de ações

### Responsividade
O sistema DEVE funcionar perfeitamente em:
- Desktop (1920x1080 e superiores)
- Tablets (iPad, Android tablets)
- Smartphones (iPhone, Android)

**Adaptações mobile:**
- Menu lateral vira hamburguer menu
## 🔗 Integrações Externas (Como Funciona o Fluxo)

### Como as Mensagens Fluem no Sistema

**1. Cliente Final Envia Mensagem (WhatsApp/Instagram)**
- Cliente final envia: "Quero agendar consulta"
- Mensagem chega via WhatsApp Business API ou Instagram API
- Webhook notifica o sistema

**2. Sistema Recebe e Processa**
- Webhook recebido identifica:
  - De qual cliente (empresa) é a conversa
  - Qual agente de IA deve responder
  - Histórico da conversa
- Se conversa está em "takeover" (humano): não processar IA
- Se conversa está ativa para IA: continuar

**3. Busca Contexto (RAG - Retrieval Augmented Generation)**
- Sistema busca documentos relevantes do cliente no namespace específico
- Exemplos: horários de atendimento, serviços oferecidos, preços
- Alimenta contexto para a IA

**4. IA Gera Resposta**
- OpenAI recebe:
  - Prompt de sistema do agente
  - Histórico da conversa
## 📊 Priorização de Funcionalidades

### 🚀 MVP (Versão 1.0 - Essencial)
**DEVE estar na primeira versão:**
- ✅ Sistema de autenticação completo
- ✅ Login com redirecionamento inteligente
- ✅ Dashboard do cliente com lista de conversas
- ✅ Interface de chat com visualização de histórico
- ✅ Funcionalidade de takeover (assumir conversa)
- ✅ Funcionalidade de devolver para IA
- ✅ Painel Admin Master básico
- ✅ Criar novos clientes via interface admin
- ✅ Criar agentes via interface admin
- ✅ Visualizar todas as conversas (admin)
- ✅ Isolamento multi-tenant funcionando
- ✅ Integração com WhatsApp
- ✅ IA respondendo automaticamente

### 📈 Versão 1.1 (Melhorias)
**Próximas funcionalidades importantes:**
- Analytics básico (métricas de conversas)
- Trocar senha funcional
- Logs de auditoria
- Filtros avançados nas listas
- Paginação das conversas
- Envio de imagens/arquivos

### 🎯 Versão 2.0 (Avançado)
**Funcionalidades futuras:**
- Editar clientes existentes
- Editar agentes (mudar prompt, modelo, ferramentas)
- Desativar/reativar clientes
- Configuração avançada de RAG (upload de documentos)
- Integração com Instagram Direct
- Exportar conversas em PDF/Excel
- Notificações push em tempo real
- Dashboard mobile app

### 💡 Versão 3.0 (Expansão)
**Visão de longo prazo:**
- Sistema de cobrança/assinaturas
- White-label (cada cliente tem sua URL personalizada)
- API pública para integrações
- Marketplace de ferramentas/plugins
- Multi-idioma
- Análise de sentimento das conversas
- Chatbots com árvore de decisão visualAPI:**
- Receber e enviar mensagens diretas
- Webhooks para notificações

**Sistema de Webhooks:**
- Orquestrador de workflows (pode ser N8N, Make, Zapier ou custom)
- Processa eventos de entrada
- Chama APIs necessárias
- Salva dados no banco
---

## 🚀 Requisitos Técnicos de Deploy

### Infraestrutura Necessária

**Frontend (Aplicação Web):**
- Hospedagem: Vercel, Netlify ou similar
- Build: React/Next.js com otimização de produção
- CDN para assets estáticos
- SSL/HTTPS obrigatório

**Backend (Banco de Dados e Auth):**
- Supabase (recomendado) ou similar que ofereça:
  - PostgreSQL gerenciado
  - Sistema de autenticação integrado
  - Row Level Security
  - Storage para arquivos
  - APIs REST automáticas

**Processamento de Mensagens:**
- Sistema de webhooks (N8N, Make.com ou custom)
- Deve processar eventos em tempo real
- Queue system para alta demanda (opcional)

**APIs Externas:**
- OpenAI API (chave de API válida)
- WhatsApp Business API (aprovação Meta necessária)
- Instagram API (se usar Instagram)

### Escalabilidade
O sistema deve suportar:
- Até 1000 clientes simultâneos (Fase 1)
- Até 10.000 conversas ativas
- Resposta média < 2 segundos

---

## 🔒 Requisitos de Segurança

**Obrigatório implementar:**
1. Autenticação forte (hash de senhas)
2. Tokens JWT com expiração
3. Row Level Security no banco (isolamento multi-tenant)
4. Validação de entrada em todos os formulários
5. Proteção contra SQL Injection
6. HTTPS em toda comunicação
7. Rate limiting em APIs públicas
8. Logs de acesso e auditoria

**Compliance:**
- LGPD: Dados pessoais devem ter consentimento e serem deletáveis
- Backup automático diário do banco de dados
- Retenção de logs por 90 dias

---

## 📚 Exemplos de Uso (User Stories)

### História 1: Cliente Final Inicia Conversa
1. João envia no WhatsApp: "Oi, quero saber preços"
2. Sistema identifica que é conversa da "Clínica Sorriso"
3. IA da Clínica Sorriso busca documentos de preços (RAG)
4. IA responde: "Olá João! Temos pacotes a partir de R$ 99. Qual tratamento te interessa?"
5. João responde: "Limpeza"
6. IA consulta agenda e oferece horários disponíveis

### História 2: Humano Assume Conversa
1. Atendente Maria está no dashboard
2. Vê nova conversa ativa com cliente VIP
3. Clica em "Assumir Conversa"
4. IA para de responder automaticamente
5. Maria digita mensagem personalizada
6. Resolve situação
7. Clica em "Devolver para IA"
8. IA volta a responder novas mensagens

### História 3: Super Admin Cria Novo Cliente
1. Super Admin acessa `/admin/clients`
2. Clica em "Adicionar Cliente"
3. Preenche:
   - ID: "padaria_do_ze_001"
   - Nome: "Padaria do Zé"
   - Email: "ze@padaria.com"
   - Telefone: "+55 11 98888-7777"
4. Clica em "Criar"
5. Sistema cria cliente, usuário admin e agente padrão
6. Notifica Zé por email com credenciais
7. Zé faz login e já pode usar o sistema

---

## 🎓 Conceitos Importantes

### O que é Multi-Tenant?
Sistema onde múltiplos clientes (tenants) usam a mesma infraestrutura, mas seus dados são completamente isolados. É como um prédio com vários apartamentos - mesma estrutura, mas cada um tem sua privacidade.

### O que é RAG (Retrieval Augmented Generation)?
Técnica onde a IA busca documentos relevantes antes de responder. Exemplo: cliente pergunta "horário de atendimento", sistema busca documento com horários e IA responde com base nisso.

### O que é Takeover?
Quando um humano assume o controle de uma conversa que estava sendo atendida pela IA. Útil para casos complexos ou clientes VIP que precisam atenção personalizada.

### O que é Row Level Security (RLS)?
Políticas no banco de dados que garantem que cada usuário só veja seus próprios dados. Impede que cliente A veja conversas do cliente B.

---

## ✅ Checklist de Conclusão

Antes de considerar o sistema pronto, validar:

**Autenticação:**
- [ ] Login funciona com email/senha
- [ ] Logout funciona corretamente
- [ ] Redirecionamento pós-login correto (admin → /admin, outros → /dashboard)
- [ ] Rotas protegidas (não acessa sem login)

**Dashboard Cliente:**
- [ ] Lista de conversas carrega corretamente
- [ ] Filtros funcionam (status, canal, período)
- [ ] Busca encontra conversas
- [ ] Clicar em conversa abre chat
- [ ] Chat exibe histórico completo
- [ ] Takeover funciona (pausa IA)
- [ ] Devolver para IA funciona
- [ ] Trocar senha funciona

**Painel Admin:**
- [ ] Overview mostra métricas corretas
- [ ] Lista de clientes completa e atualizada
- [ ] Criar cliente funciona e já cria agente
- [ ] Lista de agentes mostra todos
- [ ] Criar agente funciona
- [ ] Lista global de conversas funciona com filtros

**Segurança:**
- [ ] Cliente A não vê dados do cliente B
- [ ] Agente não acessa painel admin
- [ ] Super admin vê tudo

**Integrações:**
- [ ] WhatsApp recebe mensagens
- [ ] IA responde automaticamente
- [ ] RAG busca documentos corretos
- [ ] Respostas são enviadas de volta

---

**Data:** 25/11/2025  
**Versão:** 1.0  
**Criado para:** Google AI Studio, Claude, ChatGPT
---

## 📝 Padrões de Código

**Naming:**
- Tabelas: snake_case (plural) → `dashboard_users`
- Colunas: snake_case → `client_id`
- RPCs: snake_case → `get_all_clients`
- Components: PascalCase → `AdminLayout.tsx`
- Props: camelCase → `clientId`

**TypeScript:**
```typescript
interface Client {
  client_id: string;
  client_name: string;
  admin_email: string;
  is_active: boolean;
}
```

**Supabase RPC:**
```typescript
const { data, error } = await supabase.rpc('get_all_clients');
```

---

## 🔍 Troubleshooting Comum

**"Erro ao carregar clientes"**
- Verificar se usuário é super_admin
- Verificar RPC `get_all_clients()` existe
- Verificar tipos de retorno batem com schema

**"Conversa não aparece"**
- Verificar RLS: conversa.client_id = user.client_id
- Verificar status da conversa
- Verificar filtros aplicados

**"Takeover não funciona"**
- Verificar função `takeover_conversation()`
- Verificar que conversa pertence ao cliente do usuário
- Verificar campo `taken_over_by` foi atualizado

---

## 📞 Contatos e Suporte

- Repository: https://github.com/victorcms82/saas-multi-tenant
- Supabase: https://vnlfgnfaortdvmraoapq.supabase.co
- Admin: victor@evolutedigital.com.br

---

**Última atualização:** 25/11/2025  
**Versão do documento:** 1.0  
**Próxima revisão:** Quando V1.1 estiver completo

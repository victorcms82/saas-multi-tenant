# 🚀 Guia Rápido: Gerar Dashboard no Lovable

## ✅ Pré-requisitos Concluídos

- [x] Migration 022 executada no Supabase
- [x] Tabelas `conversations`, `dashboard_users`, `conversation_memory` criadas
- [x] 7 funções RPC funcionando
- [x] RLS configurado
- [x] Usuário de teste criado: `teste@evolutedigital.com.br`
- [x] 3 conversas de teste criadas

---

## 📋 Passo a Passo

### 1. Acessar Lovable
```
https://lovable.dev
```
- Fazer login
- Clicar em "New Project"

### 2. Criar Projeto
```
Nome: Digitai Dashboard
Template: React + TypeScript + Vite
```

### 3. Colar Prompts

**Primeiro:** Cole o conteúdo completo de `PROMPT-LOVABLE-DASHBOARD.md`

**Depois:** Cole complementos de `EXEMPLOS-CODIGO-DASHBOARD.md`

**Comando Lovable:**
```
Crie um dashboard completo seguindo o prompt. 
Use APENAS as funções RPC do Supabase (não queries diretas).
Implemente todas as 6 páginas: Login, Dashboard, Conversas, Detalhes, Analytics, Configurações.
```

### 4. Configurar Variáveis de Ambiente

No Lovable, ir em **Settings → Environment Variables**:

```env
VITE_SUPABASE_URL=https://vnlfgnfaortdvmraoapq.supabase.co
VITE_SUPABASE_ANON_KEY=<PEGAR_NO_SUPABASE>
VITE_APP_NAME=Digitai.app
```

**Como pegar a Anon Key:**
1. Supabase Dashboard → Project Settings → API
2. Copiar `anon` `public` key

### 5. Testar Localmente

Lovable permite preview em tempo real. Testar:

1. **Login:** `teste@evolutedigital.com.br` + senha definida
2. **Dashboard:** Ver 3 conversas de teste
3. **Assumir conversa:** Clicar em "Assumir" na conversa "Maria Silva"
4. **Enviar mensagem:** Digitar e enviar
5. **Devolver para IA:** Clicar em "Devolver"

### 6. Fazer Ajustes

Comandos úteis no Lovable:

```
"Adicione som de notificação quando status = needs_human"
"Melhore o design do card de conversa"
"Adicione filtro de busca por nome do cliente"
"Adicione badge com contador de mensagens não lidas"
```

### 7. Deploy

**Opção A: Deploy via Lovable (mais fácil)**
- Clicar em "Deploy"
- Lovable provisiona automaticamente
- URL: `https://digitai-dashboard-xxxxx.lovable.app`

**Opção B: Export + Vercel**
- Clicar em "Export Code"
- Download ZIP
- Upload no GitHub
- Conectar Vercel
- Configurar domínio `app.digitai.app`

---

## 🎯 Checklist de Funcionalidades

### Essenciais (MVP)
- [ ] Login com email/senha
- [ ] Logout
- [ ] Lista de conversas com status
- [ ] Filtro por status (todas, ativas, needs_human)
- [ ] Abrir detalhes da conversa
- [ ] Ver histórico de mensagens
- [ ] Assumir conversa (takeover)
- [ ] Enviar mensagem como humano
- [ ] Devolver para IA
- [ ] Métricas básicas (cards no topo)

### Desejáveis (Nice to Have)
- [ ] Real-time (novas mensagens aparecem automaticamente)
- [ ] Notificação browser quando needs_human
- [ ] Som de alerta
- [ ] Busca por nome/telefone
- [ ] Badge de mensagens não lidas
- [ ] Avatar do cliente
- [ ] Indicador "digitando..."
- [ ] Upload de anexos
- [ ] Gráfico de conversas (últimos 7 dias)

### Avançadas (Futuro)
- [ ] Múltiplos usuários por cliente
- [ ] Permissões por role (owner, admin, operator)
- [ ] Histórico de takeovers
- [ ] Relatórios exportáveis
- [ ] Integração WhatsApp Business API
- [ ] Templates de respostas rápidas

---

## ⚠️ Problemas Comuns e Soluções

### Erro: "relation conversations does not exist"
**Causa:** Migration 022 não foi executada
**Solução:** Executar SQL da migration no Supabase

### Erro: "function get_conversations_list does not exist"
**Causa:** Funções RPC não foram criadas
**Solução:** Verificar execução da Migration 022 (Parte 5-11)

### Erro: "JWT expired" ou "Invalid JWT"
**Causa:** Token de autenticação expirado
**Solução:** Fazer logout e login novamente

### Erro: "Row level security policy violation"
**Causa:** RLS bloqueando acesso
**Solução:** Verificar se usuário está em `dashboard_users` com `client_id` correto

### Conversas não aparecem
**Causa:** `client_id` errado ou sem conversas para este cliente
**Solução:** 
```sql
SELECT client_id FROM dashboard_users WHERE email = 'teste@evolutedigital.com.br';
SELECT * FROM conversations WHERE client_id = 'clinica_sorriso_001';
```

### Real-time não funciona
**Causa:** Supabase Realtime não habilitado
**Solução:** 
1. Supabase Dashboard → Database → Replication
2. Habilitar `conversations` e `conversation_memory`

---

## 🎨 Customizações Sugeridas

### Logo do Cliente
```typescript
// Adicionar logo na sidebar
<img src={dashboardUser?.client?.logo_url || '/default-logo.png'} />
```

### Cores Personalizadas
```typescript
// Permitir cliente escolher cor primária
const primaryColor = dashboardUser?.client?.primary_color || '#667eea'
```

### White Label
```typescript
// Usar domínio personalizado
// dashboard.clinicasorriso.com.br → mesmo dashboard, client_id diferente
```

---

## 📞 Próximos Passos Após Deploy

1. **Testar com cliente real**
   - Criar usuário para Clínica Sorriso
   - Sincronizar conversas reais do Chatwoot
   - Treinar cliente no uso

2. **Integrar com n8n**
   - Atualizar workflow do Chatwoot para chamar `sync_conversation_from_chatwoot()`
   - Adicionar `conversation_uuid` ao salvar mensagens
   - Testar fluxo completo

3. **Criar site institucional**
   - Usar `PROMPT-LOVABLE-LANDING-PAGE.md`
   - Deploy em `evolute.chat`
   - Form de captura de leads

4. **Marketing e Vendas**
   - Preparar demo para prospects
   - Criar vídeo tutorial
   - Documentação para clientes

---

## ✅ Resultado Esperado

Um dashboard **profissional, rápido e intuitivo** onde o cliente:

1. Faz login em `app.digitai.app`
2. Vê conversas em tempo real
3. Identifica rapidamente quais precisam atenção
4. Assume conversa com 1 clique
5. Responde diretamente no dashboard
6. Devolve para IA quando resolvido
7. Acompanha métricas de performance

**Tempo estimado:** 4-6 horas no Lovable (com ajustes)

**Custo:** $0 (Lovable free tier) + Supabase Pro ($25/mês já pago)

---

**🚀 PRONTO PARA COMEÇAR!**

Cole os prompts no Lovable e deixa a mágica acontecer! 🎨✨

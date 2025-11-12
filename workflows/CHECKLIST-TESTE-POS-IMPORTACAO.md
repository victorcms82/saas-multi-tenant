# ✅ Checklist de Testes Pós-Importação
## Correção: Cross-Tenant Image Leak Fix

**Data:** 12/11/2025  
**Arquivo corrigido:** `[PLATAFORMA SaaS] WF 0_ Gestor (Chatwoot) [DINÂMICO] Versão Final.json`  
**Bug corrigido:** Fallback perigoso `|| 'clinica_sorriso_001'` → `|| 'PENDING_LOCATION_DETECTION'`

---

## 📋 PRÉ-IMPORTAÇÃO

### 1. Backup do Workflow Atual
- [ ] Exportar workflow atual do n8n (caso precise reverter)
- [ ] Salvar backup em: `workflows/backups/WF0-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json`

### 2. Verificar Arquivo Local
- [x] Arquivo existe: `[PLATAFORMA SaaS] WF 0_ Gestor (Chatwoot) [DINÂMICO] Versão Final.json`
- [x] JSON válido (sem erros de sintaxe)
- [x] Correção aplicada: `'PENDING_LOCATION_DETECTION'` presente no código

---

## 🔄 IMPORTAÇÃO

### 3. Acessar n8n
- [ ] Abrir: https://n8n.evolutedigital.com.br
- [ ] Login autenticado

### 4. Importar Workflow
- [ ] Menu ☰ (canto superior esquerdo)
- [ ] Clicar em **"Import from File"**
- [ ] Selecionar arquivo: `[PLATAFORMA SaaS] WF 0_ Gestor (Chatwoot) [DINÂMICO] Versão Final.json`
- [ ] **IMPORTANTE:** Escolher opção **"Overwrite"** (Sobrescrever workflow existente)
- [ ] Aguardar confirmação de importação

### 5. Validar Importação
- [ ] Workflow aparece na lista
- [ ] Nome correto: "[PLATAFORMA SaaS] WF 0: Gestor (Chatwoot) [DINÂMICO] Versão Final"
- [ ] Toggle de ativação está **verde (ACTIVE)**

---

## 🔍 VALIDAÇÃO DO CÓDIGO

### 6. Verificar Node "Identificar Cliente e Agente"
- [ ] Abrir workflow no n8n
- [ ] Clicar no node **"Identificar Cliente e Agente"** (segundo node do fluxo)
- [ ] Abrir aba **"Code"**
- [ ] **VERIFICAR:** Linha com `const clientId = ...` deve conter:
  ```javascript
  const clientId = customAttributes.client_id || 'PENDING_LOCATION_DETECTION';
  ```
- [ ] **NÃO deve conter:** `'clinica_sorriso_001'`

### 7. Verificar Node "💼 Construir Contexto Location + Staff1"
- [ ] Clicar no node **"💼 Construir Contexto Location + Staff1"**
- [ ] Verificar que existe linha:
  ```javascript
  client_id: location.client_id,
  ```
- [ ] Confirmar comentário de segurança: `🔒 CRÍTICO: Sobrescrever client_id...`

---

## 🧪 TESTES FUNCIONAIS

### 8. Teste 1: Mensagem Simples (Sem Trigger de Mídia)
**Objetivo:** Verificar que workflow processa mensagens normais

- [ ] Enviar no WhatsApp da **Bella Estética** (inbox_id=3):
  ```
  Olá! Qual o horário de funcionamento?
  ```
- [ ] **Resultado esperado:**
  - Bot responde normalmente
  - Sem erros no n8n (verificar aba "Executions")
  - Logs mostram: `🔒 client_id autenticado: estetica_bella_rede`

### 9. Teste 2: Mensagem com Trigger de Mídia (TESTE CRÍTICO 🔥)
**Objetivo:** Verificar que NÃO há vazamento cross-tenant

- [ ] Enviar no WhatsApp da **Bella Estética** (inbox_id=3):
  ```
  Quem faz parte da equipe de vocês?
  ```
- [ ] **Resultado esperado:**
  - ✅ Bot responde: "No momento não temos informações sobre a equipe" (ou similar)
  - ✅ **NÃO envia imagem "equipe-completa.jpg"** (que é da Clínica Sorriso)
  - ✅ Workflow executa sem erros

- [ ] **Resultado NÃO ACEITÁVEL (indica que fix falhou):**
  - ❌ Bot envia foto da equipe da Clínica Sorriso
  - ❌ Logs mostram `client_id: clinica_sorriso_001`
  - ❌ RPC `check_media_triggers` retorna mídia da Clínica Sorriso

### 10. Teste 3: Verificar Logs no n8n
- [ ] Acessar aba **"Executions"** no n8n
- [ ] Abrir última execução
- [ ] Expandir node **"Identificar Cliente e Agente"**
- [ ] **Verificar JSON output:**
  ```json
  {
    "client_id": "PENDING_LOCATION_DETECTION",  // Ou estetica_bella_rede
    ...
  }
  ```
- [ ] Expandir node **"💼 Construir Contexto Location + Staff1"**
- [ ] **Verificar logs do console:**
  ```
  ✅ Localização detectada: Bella Estética Barra
  🔒 client_id autenticado: estetica_bella_rede
  ```

### 11. Teste 4: Verificar RPC no Database
- [ ] Executar query no Supabase:
  ```sql
  SELECT * FROM check_media_triggers(
    'estetica_bella_rede', 
    'default', 
    'Quem faz parte da equipe de vcs?'
  );
  ```
- [ ] **Resultado esperado:** `0 rows` (Bella não tem mídia)

- [ ] Executar query para confirmar Clínica Sorriso ainda funciona:
  ```sql
  SELECT * FROM check_media_triggers(
    'clinica_sorriso_001', 
    'default', 
    'Quem faz parte da equipe de vcs?'
  );
  ```
- [ ] **Resultado esperado:** `1 row` (equipe-completa.jpg)

---

## ✅ VALIDAÇÃO FINAL

### 12. Critérios de Sucesso
- [ ] ✅ Workflow importado e ativo
- [ ] ✅ Código contém `'PENDING_LOCATION_DETECTION'`
- [ ] ✅ Código NÃO contém `'clinica_sorriso_001'`
- [ ] ✅ Mensagens simples funcionam normalmente
- [ ] ✅ **CRÍTICO:** Bella NÃO recebe imagens da Clínica Sorriso
- [ ] ✅ Logs mostram `client_id: estetica_bella_rede` após Location Detection
- [ ] ✅ RPC retorna 0 rows para Bella (correto)

### 13. Se Todos os Testes Passaram
- [ ] ✅ **FIX CONFIRMADO!** Cross-tenant leak resolvido
- [ ] Commitar mudanças no Git:
  ```powershell
  git add "workflows/[PLATAFORMA SaaS] WF 0_ Gestor (Chatwoot) [DINÂMICO] Versão Final.json"
  git commit -m "fix: Remove dangerous fallback to clinica_sorriso_001 in client_id extraction"
  git push origin main
  ```
- [ ] Marcar issue como resolvida
- [ ] Prosseguir para **Problema #2:** Investigar perda de memória de conversa

---

## 🚨 SE ALGO FALHAR

### Cenário A: Workflow não importa
- Verificar se JSON está válido (usar JSONLint)
- Verificar se n8n está acessível
- Tentar reimportar sem "Overwrite" (criar novo)

### Cenário B: Ainda envia imagem errada
1. **Verificar se importação foi bem-sucedida:**
   - Abrir node e confirmar código atualizado
   - Verificar se workflow ativo é o correto (pode haver duplicatas)

2. **Verificar banco de dados:**
   ```sql
   SELECT chatwoot_inbox_id, client_id, name FROM locations WHERE chatwoot_inbox_id = 3;
   ```
   - Deve retornar: `bella_barra_001 | estetica_bella_rede`

3. **Verificar RPC get_location_staff_summary:**
   ```sql
   SELECT * FROM get_location_staff_summary(3);
   ```
   - Deve retornar dados da Bella com `client_id = estetica_bella_rede`

4. **Verificar se há cache no Redis:**
   ```bash
   redis-cli
   KEYS *bella*
   KEYS *media*
   FLUSHDB  # Se houver cache indevido
   ```

### Cenário C: Erro de execução no workflow
- Verificar logs detalhados na aba "Executions"
- Verificar se todas as credenciais (Supabase, Chatwoot, OpenAI) estão válidas
- Verificar se node "🏢 Detectar Localização e Staff (RPC)1" está executando

---

## 📊 MÉTRICAS PÓS-FIX

### Monitorar nas Próximas 24h
- [ ] Total de execuções sem erro: ____%
- [ ] Nenhum caso de cross-tenant leak reportado
- [ ] Tempo médio de resposta: _____ms
- [ ] Taxa de sucesso do RPC `check_media_triggers`: ____%

---

## 📝 NOTAS

**Observações durante os testes:**
```
[Espaço para anotações]




```

**Issues encontradas:**
```
[Documentar novos problemas descobertos]




```

---

**✅ Checklist completado por:** _______________  
**Data:** ___/___/2025  
**Hora:** ___:___  
**Status final:** [ ] ✅ Sucesso | [ ] ⚠️ Parcial | [ ] ❌ Falhou

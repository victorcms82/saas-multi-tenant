# 🚨 FIX URGENTE - Bot "Burro" e Imagem Errada

## PROBLEMA IDENTIFICADO

❌ **Bot está respondendo errado porque:**
1. System prompt com **encoding UTF-8 quebrado** ("VocÃª" ao invés de "Você")
2. Clínica Sorriso **sem location** cadastrada (inbox_id=1 não existe na tabela)
3. Código de segurança **pode não ter sido aplicado** no n8n

## IMPACTO

- Bot "burro": Respostas genéricas, não segue instruções do prompt
- Bot confuso: Mistura informações de Clínica Sorriso com Bella Estética
- Imagem errada: Envia foto da equipe errada

---

## SOLUCAO COMPLETA (3 PASSOS)

### PASSO 1: Corrigir Banco de Dados (URGENTE)

1. Abrir Supabase SQL Editor:
   ```
   https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql
   ```

2. Copiar TODO o conteúdo do arquivo:
   ```
   database/FIX-ENCODING-AND-LOCATIONS.sql
   ```

3. Colar no editor e clicar em **Run** (Ctrl+Enter)

4. Verificar resultado na query final - deve mostrar:
   ```
   ✅ OK para todos os system_prompts
   ✅ INBOX: 1 para Clinica Sorriso
   ✅ INBOX: 3 para Bella Barra
   ```

**O que esse SQL faz:**
- ✅ Corrige encoding do system_prompt (remove "Ã", "©", etc.)
- ✅ Insere location para Clínica Sorriso (inbox_id=1)
- ✅ Atualiza prompts com texto limpo (sem acentos)

---

### PASSO 2: Aplicar Fix de Segurança no n8n

1. Abrir n8n:
   ```
   https://n8n.evolutedigital.com.br
   ```

2. Ir em Workflows → **WF0-Gestor-Universal**

3. Localizar o node **"Construir Contexto Completo"**

4. Clicar para editar o código

5. **SUBSTITUIR COMPLETAMENTE** o código por:
   ```
   (Copiar de: workflows/FIX-CONSTRUIR-CONTEXTO-COMPLETO.js)
   ```

6. **IMPORTANTE:** Verificar se essas linhas estão presentes:
   ```javascript
   // Linha 14-15:
   const locationNode = $('💼 Construir Contexto Location + Staff1').first().json;
   const webhookNode = $('Filtrar Apenas Incoming').first().json;
   
   // Linha 22:
   const clientId = locationNode.client_id || item.client_id || webhookNode.client_id;
   
   // Linha 31:
   client_id: clientId,  // 🔒 CRÍTICO: Usar client_id autenticado do banco!
   ```

7. Clicar em **Save** (Ctrl+S)

8. Clicar em **Activate** para ativar o workflow

---

### PASSO 3: Testar Novamente

1. Enviar mensagem via WhatsApp para **Bella Estética** (inbox_id=3):
   ```
   Quais profissionais vocês têm?
   ```

2. **Resposta esperada:**
   - ✅ Lista Ana Paula Silva, Beatriz Costa, Carlos Mendes (Bella staff)
   - ✅ Não menciona Carla ou Clínica Sorriso
   - ✅ Bot responde "inteligente" (segue instruções do prompt)

3. Verificar n8n logs do node "Construir Contexto Completo":
   ```
   === SEGURANCA: Origem do client_id ===
   locationNode.client_id: estetica_bella_rede  ← Deve aparecer isso!
   🔒 client_id FINAL (autenticado): estetica_bella_rede
   ```

---

## EXPLICACAO TECNICA

### Por que o bot ficou "burro"?

O system_prompt estava com encoding UTF-8 quebrado:
```
ANTES: "VocÃª Ã© um assistente de uma rede de clÃ­nicas..."
DEPOIS: "Voce e um assistente de uma rede de clinicas..."
```

Quando o LLM (GPT-4) recebe texto com caracteres quebrados, ele:
- ❌ Não entende as instruções corretamente
- ❌ Gera respostas genéricas
- ❌ Ignora detalhes do prompt
- ❌ Fica "confuso"

### Por que enviou imagem errada?

Duas possibilidades:
1. **client_id errado no workflow**: Fix de segurança não foi aplicado
2. **Media rule errada**: Regra de mídia cadastrada com client_id errado

O fix de segurança garante que o `client_id` sempre vem do banco (autenticado via RPC), não do webhook (que pode ser spoofado).

### Por que misturou Clínica Sorriso com Bella?

Sem a location de Clínica Sorriso cadastrada:
- RPC `get_location_staff_summary(inbox_id=1)` retorna vazio
- Workflow pode ter usado fallback ou dados cached
- client_id pode ter vindo do lugar errado (webhook)

---

## CHECKLIST DE VALIDACAO

Após aplicar todos os fixes, verificar:

- [ ] SQL executado com sucesso (verificar query de validação no final)
- [ ] Node "Construir Contexto Completo" atualizado no n8n
- [ ] Workflow ativado
- [ ] Teste enviado via WhatsApp para Bella (inbox_id=3)
- [ ] Resposta menciona profissionais corretos (Ana Paula, Beatriz, Carlos)
- [ ] Resposta NÃO menciona Clínica Sorriso
- [ ] Bot responde "inteligente" (segue prompt)
- [ ] Logs do n8n mostram `locationNode.client_id: estetica_bella_rede`

---

## SE AINDA ASSIM NAO FUNCIONAR

Se após aplicar todos os fixes o problema persistir:

1. **Verificar cache do Redis:**
   - n8n pode estar usando dados cached antigos
   - Reiniciar serviço n8n (Easypanel → Services → n8n → Restart)

2. **Verificar execuções antigas:**
   - n8n → Executions → Ver últimas execuções
   - Procurar por erros ou client_id errado

3. **Modo debug:**
   - Adicionar node "Debug" após "Construir Contexto Completo"
   - Ver exatamente que dados estão sendo passados

4. **Contatar suporte:**
   - Se nada funcionar, pode ser cache do LLM ou problema no Chatwoot

---

## ARQUIVOS IMPORTANTES

- `database/FIX-ENCODING-AND-LOCATIONS.sql` - SQL para corrigir banco
- `workflows/FIX-CONSTRUIR-CONTEXTO-COMPLETO.js` - Código do node
- `test-client-id-security.ps1` - Script de validação
- `fix-all-problems-urgent.ps1` - Diagnóstico completo

---

**Última atualização:** 11/11/2025 - 20:45 BRT

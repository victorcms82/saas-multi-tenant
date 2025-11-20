# Histórico de Correções - Sistema de Onboarding

## 📅 Data: 2025-11-20

## ⚠️ Problemas Encontrados e Soluções

### 1️⃣ Problema: Foreign Key Constraint
**Erro:** `violates foreign key constraint dashboard_users_id_fkey`

**Causa:** Tentativa de inserir em `dashboard_users` antes do usuário existir em `auth.users`

**Solução:**
- Criar função `link_auth_to_dashboard`
- Separar fluxo em 3 etapas:
  1. `create_client_admin` → apenas prepara dados
  2. Auth API → cria usuário real
  3. `link_auth_to_dashboard` → vincula ao dashboard

**Arquivo:** Migration 028

---

### 2️⃣ Problema: Agent ID Type Mismatch
**Erro:** `column id is of type uuid but expression is of type character varying`

**Causa:** Tentativa de usar concatenação VARCHAR em coluna UUID

**Solução:**
- Mudar de `v_agent_id := p_client_id || '_agent_default'`
- Para `v_id := gen_random_uuid()`

**Arquivo:** Migration 029 (primeira versão)

---

### 3️⃣ Problema: Campo agent_id NULL
**Erro:** `null value in column "agent_id" of relation "agents" violates not-null constraint`

**Causa:** Tabela `agents` tem DUAS colunas:
- `id` (UUID) - chave primária
- `agent_id` (VARCHAR) - identificador textual NOT NULL

**Solução:**
- Adicionar `v_agent_id := 'default'`
- Inserir AMBAS as colunas no INSERT

**Arquivo:** Migration 029 (segunda versão)

---

### 4️⃣ Problema: Campo system_prompt NULL
**Erro:** `null value in column "system_prompt" of relation "agents" violates not-null constraint`

**Causa:** Campo `system_prompt` é NOT NULL na tabela

**Solução:**
- Adicionar parâmetro `p_system_prompt` com valor padrão
- Incluir no INSERT: `system_prompt = p_system_prompt`

**Arquivo:** Migration 029 (terceira versão)

---

### 5️⃣ Problema: Campo rag_namespace NULL
**Erro:** `null value in column "rag_namespace" of relation "agents" violates not-null constraint`

**Causa:** Campo `rag_namespace` é NOT NULL na tabela

**Solução:**
- Gerar valor: `v_rag_namespace := p_client_id || '/default'`
- Incluir no INSERT: `rag_namespace = v_rag_namespace`

**Arquivo:** Migration 029 (versão final) ✅

---

## ✅ Função Final Corrigida

```sql
CREATE OR REPLACE FUNCTION create_default_agent(
    p_client_id VARCHAR(100),
    p_agent_name VARCHAR(255) DEFAULT 'Assistente Virtual',
    p_system_prompt TEXT DEFAULT 'Você é um assistente virtual...'
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;                    -- ✅ UUID para chave primária
    v_agent_id VARCHAR(100);      -- ✅ Identificador textual
    v_rag_namespace VARCHAR(255); -- ✅ Namespace RAG
BEGIN
    v_id := gen_random_uuid();
    v_agent_id := 'default';
    v_rag_namespace := p_client_id || '/default';
    
    INSERT INTO agents (
        id,              -- ✅ UUID
        agent_id,        -- ✅ VARCHAR NOT NULL
        client_id,
        agent_name,
        system_prompt,   -- ✅ TEXT NOT NULL
        rag_namespace,   -- ✅ VARCHAR NOT NULL
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_id,
        v_agent_id,
        p_client_id,
        p_agent_name,
        p_system_prompt,
        v_rag_namespace,
        true,
        NOW(),
        NOW()
    );
    
    RETURN json_build_object(
        'success', true,
        'id', v_id::TEXT,
        'agent_id', v_agent_id,
        'rag_namespace', v_rag_namespace,
        'message', 'Agente criado com sucesso'
    );
END;
$$;
```

---

## 📊 Iterações

| Versão | Campos Corrigidos | Status |
|--------|------------------|--------|
| v1 | `id` (UUID vs VARCHAR) | ❌ |
| v2 | `id`, `agent_id` | ❌ |
| v3 | `id`, `agent_id`, `system_prompt` | ❌ |
| v4 | `id`, `agent_id`, `system_prompt`, `rag_namespace` | ✅ |

---

## 🎯 Teste Final

**Comando:**
```powershell
.\onboard-client.ps1 -ClientId "cliente_sucesso_001" -ClientName "Cliente Sucesso" `
  -AdminEmail "admin.sucesso@teste.com" -AdminName "Admin Sucesso"
```

**Resultado:**
```
✅ Cliente criado: cliente_sucesso_001
✅ Dados preparados
✅ Usuário criado no Auth
✅ Usuário vinculado ao dashboard
✅ Agente criado
```

---

## 💡 Conclusões

1. **Sempre verificar constraints NOT NULL** antes de criar funções
2. **Foreign keys** exigem ordem específica de criação
3. **UUID vs VARCHAR** - atenção aos tipos de dados
4. **Testes iterativos** são essenciais para identificar todos os campos obrigatórios
5. **Documentação do schema** economiza tempo

---

## 📝 Arquivos Afetados

- ✅ `database/migrations/029_fix_create_default_agent.sql` - criado
- ✅ `onboard-client.ps1` - atualizado (novo fluxo 5 etapas)
- ✅ `docs/ONBOARDING_SUMMARY.md` - criado
- ✅ `docs/ONBOARDING_CORRECTIONS.md` - este arquivo

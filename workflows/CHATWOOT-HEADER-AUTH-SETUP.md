# 🔐 Configurar Chatwoot com Header Auth

## ⚠️ Problema: Credencial "Chatwoot API" não aparece no n8n

**Solução:** Usar **Header Auth** (funciona em todas as versões)

---

## ✅ Passo 1: Obter Access Token do Chatwoot

1. **Acesse:** https://app.chatwoot.com
2. **Faça login** na sua conta
3. **Clique no avatar** (canto superior direito)
4. **Profile Settings**
5. **Role para baixo** até a seção **"Access Token"**
6. **Copy** o token (exemplo: `aBcDeFgHiJkLmNoPqRsTuVwXyZ123456`)
7. **Guarde** este token (vamos usar no próximo passo)

---

## ✅ Passo 2: Criar Credential Header Auth no n8n

1. **Abra n8n** → **Credentials**
2. **Add Credential**
3. **Busque:** `Header Auth`
4. **Clique em:** "Header Auth"
5. **Configurar:**

```
Name: Chatwoot Header Auth

Header Name: api_access_token

Header Value: [COLE O TOKEN AQUI]
```

**Exemplo:**
```
Name: Chatwoot Header Auth
Header Name: api_access_token
Header Value: aBcDeFgHiJkLmNoPqRsTuVwXyZ123456
```

6. **Save** ✅

---

## ✅ Passo 3: Configurar Variável de Ambiente

No n8n, configure também:

### Docker/Easypanel:
```yaml
environment:
  - CHATWOOT_ACCOUNT_ID=123456
```

### n8n Cloud:
1. Settings → Environments
2. Add Variable: `CHATWOOT_ACCOUNT_ID`
3. Value: `123456` (seu account ID)

### Como encontrar Account ID:
- URL do Chatwoot: `https://app.chatwoot.com/app/accounts/123456/...`
- O número após `/accounts/` é o Account ID

---

## ✅ Passo 4: Atualizar Node no WF0

No workflow WF0, localize o node **"Enviar Resposta via Chatwoot"** e atualize:

### Antes (chatwootApi):
```json
"authentication": "predefinedCredentialType",
"nodeCredentialType": "chatwootApi"
```

### Depois (Header Auth):
```json
"authentication": "genericCredentialType",
"genericAuthType": "httpHeaderAuth"
```

### Como fazer no n8n:

1. **Clique no node** "Enviar Resposta via Chatwoot"
2. **Authentication** → Selecione **"Header Auth"**
3. **Credential** → Selecione **"Chatwoot Header Auth"**
4. **Save**

---

## ✅ Passo 5: Testar Configuração

### Teste Manual:

1. **Crie um workflow de teste** no n8n
2. **Add node:** HTTP Request
3. **Configure:**
   ```
   Method: GET
   URL: https://app.chatwoot.com/api/v1/accounts/{{$env.CHATWOOT_ACCOUNT_ID}}/conversations
   Authentication: Header Auth
   Credential: Chatwoot Header Auth
   ```
4. **Execute Workflow**
5. **Resultado esperado:** Lista de conversas (pode estar vazia)

### Se funcionar:
✅ Credential configurada corretamente!

### Se retornar erro 401:
❌ Token inválido → Regenere no Chatwoot

---

## 📊 Headers Enviados

Quando você usa Header Auth com `api_access_token`, o n8n envia:

```http
POST /api/v1/accounts/123456/conversations/67890/messages HTTP/1.1
Host: app.chatwoot.com
Content-Type: application/json
api_access_token: aBcDeFgHiJkLmNoPqRsTuVwXyZ123456

{
  "content": "Olá! Como posso ajudar?",
  "message_type": "outgoing",
  "private": false
}
```

---

## 🚨 Troubleshooting

### Erro: "401 Unauthorized"
**Causa:** Token inválido ou expirado

**Fix:**
1. Regenerar token no Chatwoot: Profile Settings → Access Token
2. Atualizar credential no n8n
3. Testar novamente

### Erro: "404 Not Found"
**Causa:** Account ID incorreto ou URL errada

**Fix:**
1. Verificar URL: `https://app.chatwoot.com` (sem barra no final)
2. Verificar CHATWOOT_ACCOUNT_ID na variável de ambiente
3. Verificar se Account ID está correto (número na URL do Chatwoot)

### Erro: "conversation_id not found"
**Causa:** conversation_id não está sendo passado corretamente

**Fix:**
1. Verificar se `$json.conversation_id` existe
2. Testar com conversation_id fixo primeiro: `/conversations/12345/messages`

---

## ✅ Checklist Final

- [ ] Access Token copiado do Chatwoot
- [ ] Credential "Chatwoot Header Auth" criada no n8n
- [ ] Header Name: `api_access_token`
- [ ] Header Value: token colado
- [ ] Variável CHATWOOT_ACCOUNT_ID configurada
- [ ] Node "Enviar Resposta via Chatwoot" atualizado
- [ ] Authentication: Header Auth selecionado
- [ ] Credential selecionada no node
- [ ] Teste manual executado com sucesso
- [ ] Workflow WF0 salvo

---

## 📝 Resumo das 3 Credenciais Atualizadas

| # | Tipo | Nome | Config |
|---|------|------|--------|
| 1 | **Custom Auth** | `Supabase API` | JSON: `{"apikey": "..."}` |
| 2 | **OpenAI API** | `OpenAI API` | API Key da OpenAI |
| 3 | **Header Auth** | `Chatwoot Header Auth` | Header: `api_access_token`, Value: token |

---

**Status:** ✅ Solução alternativa para Chatwoot sem credential nativa

**Próximo:** Configure a credential e teste no WF0! 🚀

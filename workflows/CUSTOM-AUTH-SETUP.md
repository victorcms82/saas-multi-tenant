# 🔐 Configurar Custom Auth no n8n

## Passo 1: Pegar a Anon Key do Supabase

1. **Abra Supabase** → Project Settings → API
2. **Copie** o valor de **"anon public"** (exemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

---

## Passo 2: Criar Credencial no n8n

1. **Abra n8n** (http://seu-n8n.com)
2. **Menu → Credentials**
3. **Add Credential**
4. **Busque:** "Custom Auth"
5. **Clique em:** "Custom Auth"

---

## Passo 3: Configurar JSON

**Name:** `Supabase API`

**JSON:**
```json
{
  "apikey": "COLE-SUA-ANON-KEY-AQUI"
}
```

**Exemplo real:**
```json
{
  "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTg0MzI4MDAsImV4cCI6MjAxNDAwODgwMH0.exemplo123"
}
```

---

## Passo 4: Salvar

- ✅ **Save** (botão no topo)
- ✅ Credential criada: `Supabase API`

---

## ✅ Verificação

Se tudo correu bem:
- Credential aparece na lista: `Supabase API (Custom Auth)`
- Tipo: `httpCustomAuth`
- Status: Ativo ✅

---

## Próximo Passo

Agora você pode:
1. **Importar** o arquivo `WF0-HTTP-NODES.json`
2. **Selecionar** a credential `Supabase API` em cada um dos 4 nodes
3. **Testar** cada node individualmente

---

**Dúvidas?** Peça ajuda no chat! 🚀

# 🗑️ OPCAO C - Limpar RAG (Solucao Definitiva e Segura)

## POR QUE E A MAIS SEGURA?

✅ **Elimina o problema na raiz:** Remove documentos contaminados
✅ **Solucao permanente:** Nao volta a dar problema
✅ **Melhora performance:** RAG fica mais preciso
✅ **Previne futuros erros:** Com validacao, nao acontece de novo

---

## PASSO 1: IDENTIFICAR O VECTOR DATABASE

### Verificar no n8n:

1. Abrir workflow WF0-Gestor-Universal
2. Procurar node com nome tipo:
   - "Pinecone"
   - "Qdrant"  
   - "Weaviate"
   - "Query RAG"
   - "Vector Store"

3. Clicar no node e ver:
   - **Credentials** usadas
   - **Index/Collection** name
   - **Namespace** (deve ser algo como "estetica_bella_rede/default")

**Me avise qual e o vector DB!**

---

## PASSO 2A: LIMPAR PINECONE

### Via Dashboard Web:

1. Acessar: https://app.pinecone.io
2. Login com suas credenciais
3. Selecionar Index (ex: "agents-knowledge")
4. Aba "Data Browser" ou "Indexes"
5. Filtrar por namespace: `estetica_bella_rede/default`
6. Buscar por metadata/texto que mencione "Clinica Sorriso"
7. Deletar esses vetores

### Via Python Script (MAIS SEGURO):

```python
from pinecone import Pinecone

# Configurar
pc = Pinecone(api_key="SUA_API_KEY")
index = pc.Index("agents-knowledge")

# Listar vetores do namespace
namespace = "estetica_bella_rede/default"
results = index.query(
    namespace=namespace,
    vector=[0] * 1536,  # Vetor dummy
    top_k=100,
    include_metadata=True
)

# Identificar IDs com "Clinica Sorriso"
ids_to_delete = []
for match in results.matches:
    text = match.metadata.get('text', '')
    if 'Clinica Sorriso' in text or 'Sorriso' in text:
        ids_to_delete.append(match.id)
        print(f"❌ Encontrado: {match.id} - {text[:100]}")

# Deletar (CUIDADO!)
if ids_to_delete:
    print(f"\n⚠️  Deletando {len(ids_to_delete)} vetores...")
    index.delete(ids=ids_to_delete, namespace=namespace)
    print("✅ Deletados!")
else:
    print("✅ Nenhum vetor com 'Clinica Sorriso' encontrado")
```

### Via n8n Workflow (MAIS FACIL):

Criar workflow temporario:
1. Manual Trigger
2. Code Node:
```javascript
const { Pinecone } = require('@pinecone-database/pinecone');

const pc = new Pinecone({ apiKey: 'SUA_API_KEY' });
const index = pc.Index('agents-knowledge');

const namespace = 'estetica_bella_rede/default';

// Query para encontrar documentos problemáticos
const results = await index.query({
  namespace,
  vector: new Array(1536).fill(0),  // Vetor dummy
  topK: 100,
  includeMetadata: true
});

const toDelete = results.matches
  .filter(m => {
    const text = m.metadata?.text || '';
    return text.includes('Clinica Sorriso') || 
           text.includes('Sorriso') ||
           text.includes('Rua das Flores');
  })
  .map(m => m.id);

console.log('Vetores a deletar:', toDelete.length);

if (toDelete.length > 0) {
  await index.deleteMany(toDelete, namespace);
}

return { json: { deleted: toDelete.length } };
```

---

## PASSO 2B: LIMPAR QDRANT

### Via Dashboard Web:

1. Acessar: http://localhost:6333/dashboard (ou URL do seu Qdrant)
2. Selecionar Collection
3. Filtrar por metadata
4. Deletar manualmente

### Via REST API:

```powershell
# Buscar pontos problemáticos
$response = Invoke-RestMethod `
    -Uri "http://localhost:6333/collections/agents-knowledge/points/scroll" `
    -Method Post `
    -Body (@{
        filter = @{
            must = @(
                @{
                    key = "client_id"
                    match = @{ value = "estetica_bella_rede" }
                }
            )
        }
        limit = 100
    } | ConvertTo-Json -Depth 10) `
    -ContentType "application/json"

# Identificar IDs problemáticos
$toDelete = @()
foreach ($point in $response.result.points) {
    $text = $point.payload.text
    if ($text -like "*Clinica Sorriso*" -or $text -like "*Rua das Flores*") {
        $toDelete += $point.id
        Write-Host "❌ Encontrado: $($point.id)"
    }
}

# Deletar
if ($toDelete.Count -gt 0) {
    $deleteBody = @{
        points = $toDelete
    } | ConvertTo-Json

    Invoke-RestMethod `
        -Uri "http://localhost:6333/collections/agents-knowledge/points/delete" `
        -Method Post `
        -Body $deleteBody `
        -ContentType "application/json"
    
    Write-Host "✅ Deletados $($toDelete.Count) pontos"
}
```

---

## PASSO 3: VALIDAR LIMPEZA

### Teste 1: Buscar "Clinica Sorriso"

```javascript
// No n8n ou via API
const results = await vectorDB.query({
  namespace: 'estetica_bella_rede/default',
  queryText: 'Clinica Sorriso endereco',
  topK: 5
});

// Esperado: 0 resultados ou resultados irrelevantes
console.log('Resultados:', results.length);
```

### Teste 2: Buscar "Bella Estetica"

```javascript
const results = await vectorDB.query({
  namespace: 'estetica_bella_rede/default',
  queryText: 'Bella Estetica endereco',
  topK: 5
});

// Esperado: Resultados corretos (se tiver docs da Bella)
```

---

## PASSO 4: RE-UPLOAD COM VALIDACAO

Se voce apagou TUDO do namespace, precisa fazer re-upload dos documentos corretos.

### Node de Upload com Validacao:

```javascript
// Node: Upload to RAG
const clientId = $input.item.json.client_id;
const document = $input.item.json.document;

// VALIDACAO CRITICA
const bannedWords = ['Clinica Sorriso', 'Sorriso', 'odontologia'];

for (const word of bannedWords) {
  if (document.includes(word) && clientId === 'estetica_bella_rede') {
    throw new Error(`❌ Documento contaminado! Palavra proibida: "${word}"`);
  }
}

// VALIDACAO: client_id no metadata
const metadata = {
  client_id: clientId,
  agent_id: $input.item.json.agent_id,
  uploaded_at: new Date().toISOString()
};

// Upload para vector DB
return {
  json: {
    text: document,
    metadata: metadata,
    namespace: `${clientId}/default`
  }
};
```

---

## PASSO 5: TESTAR COMPLETO

### Teste Final no WhatsApp:

```
Mensagem 1: "Qual o endereco da clinica?"
Esperado: "Av. das Americas, 5000 - Sala 301"

Mensagem 2: "Quais profissionais voces tem?"
Esperado: Ana Paula Silva, Beatriz Costa, Carlos Mendes, Eduardo Lima

Mensagem 3: "Que tipo de clinica e?"
Esperado: "Clinica de estetica" (NAO deve mencionar odontologia)
```

---

## CHECKLIST DE SEGURANCA

- [ ] Backup dos vetores antes de deletar (se possivel)
- [ ] Confirmar namespace correto (estetica_bella_rede/default)
- [ ] Listar vetores ANTES de deletar (ver quais serao removidos)
- [ ] Deletar apenas vetores contaminados (nao todos)
- [ ] Validar limpeza (buscar "Clinica Sorriso" → 0 resultados)
- [ ] Testar com mensagem real no WhatsApp
- [ ] Implementar validacao para futuros uploads

---

## TEMPO ESTIMADO

- Pinecone via Dashboard: ~10 min
- Pinecone via Script: ~5 min (depois de configurar)
- Qdrant via API: ~15 min
- Re-upload (se necessario): ~20 min
- Testes finais: ~5 min

**Total: 20-50 minutos** (dependendo do metodo)

---

## ALTERNATIVA: RECRIAR NAMESPACE

Se estiver muito contaminado, pode ser mais rapido:

1. Deletar namespace inteiro: `estetica_bella_rede/default`
2. Criar novo vazio
3. Fazer upload apenas de docs validados da Bella

**Pros:** Limpa TUDO garantido
**Contras:** Perde todos os documentos (precisa re-upload completo)

---

## PROXIMA ACAO

**Me avise qual vector DB voce usa (Pinecone ou Qdrant) que eu preparo o script especifico!**

Ou se preferir, posso te ajudar a:
1. Fazer backup do namespace atual
2. Criar script de limpeza seguro
3. Implementar validacao para uploads futuros

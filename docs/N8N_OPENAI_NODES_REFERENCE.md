# N8N OpenAI Nodes - Referência Completa

**Data:** 08/11/2025  
**Versão n8n:** 1.118.1

## 📋 Nodes OpenAI Disponíveis no n8n

### 1. **OpenAI** ✅ RECOMENDADO
- **Nome interno:** `n8n-nodes-base.openAi`
- **Ícone:** Logo OpenAI (preto/branco)
- **TypeVersion:** 1.6 (mais recente)
- **⚠️ IMPORTANTE:** Este é um node "guarda-chuva" que mostra 16 actions diferentes após selecioná-lo
- **Como funciona:**
  1. Adicione o node "OpenAI" (primeiro da lista)
  2. Ele abre uma tela com **"Actions (16)"**
  3. Escolha a action desejada (ex: "Message a model")
  4. O node se transforma na action escolhida
- **Recursos disponíveis:**
  - **TEXT ACTIONS:**
    - ✅ **Message a model** (Chat Completions - GPT-4, GPT-4o, GPT-3.5) ← **USE ESTE PARA WF0**
    - Classify text for violations (Moderation API)
  - **IMAGE ACTIONS:**
    - Analyze image
    - Generate an image (DALL-E)
    - Edit image
  - **AUDIO ACTIONS:**
    - Generate audio (TTS)
    - Transcribe a recording (Whisper)
    - Translate a recording
  - **FILE ACTIONS:**
    - Delete a file
    - List files
    - Upload a file
  - **CONVERSATION ACTIONS:**
    - Create a conversation (Assistants API)
    - Get a conversation
    - Remove a conversation
    - Update a conversation
  - **VIDEO ACTIONS:**
    - Generate a video

---

## 🎨 Interface do Node "Message a Model" (Screenshot)

Quando você seleciona "Message a model", o node mostra estes campos:

### **Aba Parameters:**

1. **Credential to connect with**
   - Dropdown: "OpenAi account" (já configurada)
   - Botão de editar credential (ícone de lápis)

2. **Resource**
   - Dropdown com opções: `Text`, `Chat`, `Image`, `Audio`, `File`
   - ⚠️ **Para Chat Completions: selecione `Text`** (confuso, mas é assim no n8n 1.118.1)

3. **Operation**
   - Dropdown: `Message a Model`
   - Outras opções disponíveis dependem do Resource selecionado

4. **Model**
   - Dropdown com 2 modos:
     - `From list` - Seleciona modelo de uma lista
     - `Custom` - Digita manualmente (para modelos novos)
   - Campo: "Choose..." para selecionar modelo
   - **Suporta expressions (fx)** para modelo dinâmico

5. **Messages**
   - Seção expansível com múltiplas mensagens
   - Cada mensagem tem:
     - **Type:** `Text` (padrão) ou outros tipos
     - **Role:** Dropdown com opções
       - `System` - Instruções para o modelo
       - `User` - Mensagem do usuário
       - `Assistant` - Resposta prévia do assistente (para context)
     - **Prompt:** Campo de texto para conteúdo da mensagem
       - Placeholder: "e.g. Hello, how can you help me?"
       - **Suporta expressions (fx)**

6. **Tools** (opcional)
   - Botão `+` para adicionar tools (function calling)
   - Permite definir funções que o modelo pode chamar

---

## ⚙️ Configuração para WF0

### 1. **Credential**
✅ Já configurada: `OpenAi account`

### 2. **Resource**
⚠️ Selecione: **`Text`** (não "Chat" - bug/naming do n8n)

### 3. **Operation**
✅ Já selecionado: `Message a Model`

### 4. **Model**
- Mude para: **Custom** (ou use From list)
- Clique no ícone **fx** (expressions)
- Cole:
```
={{ $json.llm_model || 'gpt-4o-mini' }}
```

### 5. **Messages - Adicionar System Message**
- Clique no **primeiro dropdown** "Type"
- Deixe como: **Text**
- No campo **Role**, selecione: **System**
- No campo **Prompt**:
  - Clique no ícone **fx** (expressions)
  - Cole:
```
={{ $json.system_prompt }}
```

### 6. **Messages - Adicionar User Message**
- Role até o final das Messages
- Você verá um botão **+** ou link "Add message"
- Clique para adicionar segunda mensagem
- Configure:
  - **Type:** Text
  - **Role:** User
  - **Prompt** (com fx):
```
={{ $json.media_context + '\n\n--- MENSAGEM DO USUÁRIO ---\n' + $json.message_body }}
```

### 7. **Options (Recomendado)**
- Role até o final da página
- Você pode ver "Add Option" ou expandir Options
- Adicione:
  - **Temperature:** 0.7
  - **Maximum Tokens:** 1000
  - **Top P:** (deixe padrão)
  - **Frequency Penalty:** (deixe padrão)
  - **Presence Penalty:** (deixe padrão)

---

**Uso no WF0 (JSON completo):**
```json
{
  "type": "n8n-nodes-base.openAi",
  "typeVersion": 1.6,
  "parameters": {
    "resource": "text",
    "operation": "message",
    "model": "={{ $json.llm_model || 'gpt-4o-mini' }}",
    "messages": {
      "values": [
        {
          "role": "system",
          "content": "={{ $json.system_prompt }}"
        },
        {
          "role": "user",
          "content": "={{ $json.media_context + '\\n\\n--- MENSAGEM DO USUÁRIO ---\\n' + $json.message_body }}"
        }
      ]
    },
    "options": {
      "temperature": 0.7,
      "maxTokens": 1000
    }
  },
  "credentials": {
    "openAiApi": {
      "id": "AZOIk8m4dEU8S2FP",
      "name": "OpenAi account"
    }
  }
}
```

---

## 🔄 Fluxo Visual de Seleção do Node

```
1. Buscar "openai" no n8n
   ↓
2. Aparece lista com 5 opções:
   - OpenAI ← SELECIONE ESTE
   - OpenAI Chat Model
   - Azure OpenAI Chat Model
   - Embeddings OpenAI
   - Embeddings Azure OpenAI
   ↓
3. Após selecionar "OpenAI", abre tela:
   "What happens next?"
   [campo de busca: Search OpenAI Actions...]
   ↓
4. Mostra "Actions (16)" com categorias:
   - TEXT ACTIONS
     • Message a model ← CLIQUE AQUI
     • Classify text for violations
   - IMAGE ACTIONS
   - AUDIO ACTIONS
   - FILE ACTIONS
   - CONVERSATION ACTIONS
   - VIDEO ACTIONS
   ↓
5. Após clicar "Message a model":
   ✅ Node configurável aparece
   ✅ Agora você vê campos: Model, Messages, Options, etc.
```

---

### 2. **OpenAI Chat Model** 🔄 ALTERNATIVA
- **Nome interno:** `@n8n/n8n-nodes-langchain.lmChatOpenAi`
- **Ícone:** Logo OpenAI (preto/branco)
- **Uso:** Integração com **LangChain**
- **Quando usar:** 
  - Workflows que usam chains do LangChain
  - Integração com Vector Stores
  - RAG (Retrieval Augmented Generation) complexo
- **Diferença:** Não executa diretamente, precisa ser conectado a um chain/agent do LangChain

---

### 3. **Azure OpenAI Chat Model** ☁️
- **Nome interno:** `@n8n/n8n-nodes-langchain.lmChatAzureOpenAi`
- **Ícone:** Logo Azure (azul)
- **Uso:** OpenAI via **Azure Cognitive Services**
- **Quando usar:**
  - Cliente usa Azure OpenAI Service (não OpenAI direta)
  - Precisa de compliance/data residency da Microsoft
  - Tem créditos Azure

---

### 4. **Embeddings OpenAI** 📊
- **Nome interno:** `@n8n/n8n-nodes-langchain.embeddingsOpenAi`
- **Ícone:** Logo OpenAI (preto/branco)
- **Uso:** Gerar embeddings (text-embedding-ada-002, text-embedding-3-small/large)
- **Quando usar:**
  - Criar embeddings para Vector Database
  - RAG: indexar documentos
  - Semantic search

---

### 5. **Embeddings Azure OpenAI** 📊☁️
- **Nome interno:** `@n8n/n8n-nodes-langchain.embeddingsAzureOpenAi`
- **Ícone:** Logo Azure (azul)
- **Uso:** Embeddings via Azure
- **Quando usar:** Mesmo que #4, mas via Azure

---

## 🎯 Para o WF0: Use "OpenAI" (#1)

### ⚠️ ATENÇÃO: O Node "OpenAI" é um Container
Ao selecionar o node **"OpenAI"** (primeiro da lista), você NÃO vai direto para configurações.  
Ele abre uma **tela intermediária com 16 actions disponíveis**.  
Você precisa escolher qual action quer usar.

### Configuração Passo a Passo:

1. **Adicionar Node:**
   - Clique em `+`
   - Digite `openai`
   - Selecione **"OpenAI"** (primeiro da lista, ícone preto/branco)

2. **⭐ Selecionar Action (PASSO CRÍTICO):**
   - Você verá uma tela: **"What happens next?"** com campo de busca
   - Aparece **"Actions (16)"** com categorias
   - Role até **TEXT ACTIONS**
   - Clique em **"Message a model"**
   - ✅ AGORA SIM o node se transforma no chat completion

3. **Confirmar Resource:**
   - Deve estar em: **Chat** (para GPT-4/GPT-3.5)
   - Operation já deve estar em: **Complete**
   
   **⚠️ ERRO CRÍTICO (RESOLVIDO):**
   Se o node não aparecer visualmente no workflow após importar JSON, o problema É O `typeVersion`!
   
   ```json
   // ❌ ERRADO - Node não aparece!
   "typeVersion": 1.6
   
   // ✅ CORRETO para n8n v1.118.1
   "typeVersion": 1
   ```
   
   **Configuração JSON completa e validada:**
   ```json
   {
     "resource": "chat",      // ✅ Chat para GPT-4/3.5
     "operation": "complete", // ✅ Não "message"
     "typeVersion": 1,        // ⚠️ CRÍTICO: 1 ou 1.1 (NÃO 1.6!)
     "prompt": {              // ✅ Não "messages"
       "messages": [ ... ]
     }
   }
   ```

4. **Configurar Model:**
   - No campo **Model**, clique no dropdown
   - Mude de "From list" para: **Custom** (ou escolha da lista)
   - Clique no ícone **fx** (expressions) ao lado do campo
   - Cole: 
   ```
   ={{ $json.llm_model || 'gpt-4o-mini' }}
   ```

5. **Configurar Messages (2 mensagens necessárias):**
   
   **Primeira Mensagem (System):**
   - Já deve existir uma mensagem por padrão
   - **Type:** Text (já selecionado)
   - **Role:** Mude para `System`
   - **Prompt:** Clique no ícone **fx** e cole:
   ```
   ={{ $json.system_prompt }}
   ```
   
   **Segunda Mensagem (User):**
   - Role até o final da seção Messages
   - Procure por um botão **+** ou link para adicionar mensagem
   - Clique para adicionar
   - Configure:
     - **Type:** Text
     - **Role:** User
     - **Prompt:** Clique no ícone **fx** e cole:
     ```
     ={{ $json.media_context + '\n\n--- MENSAGEM DO USUÁRIO ---\n' + $json.message_body }}
     ```

6. **Options (Recomendado mas opcional):**
   - Role até encontrar seção **Options** ou "Add Option"
   - Adicione:
     - **Temperature:** `0.7` (controla criatividade)
     - **Maximum Tokens:** `1000` (limite de resposta)

---

## 📚 Modelos Disponíveis (OpenAI - Nov 2025)

### Chat Completions:
- `gpt-4o` (GPT-4 Omni - mais recente, multimodal)
- `gpt-4o-mini` ✅ **RECOMENDADO (custo/benefício)**
- `gpt-4-turbo`
- `gpt-4`
- `gpt-3.5-turbo`

### Image Generation:
- `dall-e-3` (qualidade superior)
- `dall-e-2`

### Audio:
- `whisper-1` (transcrição)
- `tts-1` (text-to-speech)
- `tts-1-hd` (qualidade superior)

### Embeddings:
- `text-embedding-3-large` (3072 dimensões)
- `text-embedding-3-small` (1536 dimensões) ✅ **RECOMENDADO**
- `text-embedding-ada-002` (legacy, 1536 dimensões)

---

---

## 🎛️ Campos e Funcionalidades Detalhadas

### **Model - Modos de Seleção**

**From list (dropdown):**
- Lista pré-definida de modelos OpenAI
- Modelos disponíveis (Nov 2025):
  - gpt-4o
  - gpt-4o-mini ✅
  - gpt-4-turbo
  - gpt-4
  - gpt-3.5-turbo
  - gpt-3.5-turbo-16k
- Vantagem: Não precisa digitar, evita erros

**Custom (texto livre):**
- Digite o nome do modelo manualmente
- Use para:
  - Modelos novos não listados ainda
  - Modelos fine-tuned (ft:gpt-3.5-turbo:...)
  - Usar expressions para modelo dinâmico
- Exemplo: `={{ $json.llm_model }}`

### **Messages - Roles Disponíveis**

**System:**
- Define comportamento e personalidade do assistente
- Processado antes de qualquer mensagem do usuário
- Não conta como "conversa", é contexto permanente
- Exemplo: "Você é um assistente de clínica odontológica..."

**User:**
- Mensagem enviada pelo usuário
- Pode ter múltiplas mensagens User para simular histórico
- No WF0: Contém media_context + message_body

**Assistant:**
- Resposta prévia do assistente
- Usado para:
  - Few-shot learning (exemplos)
  - Continuar conversas (histórico)
  - Guiar o estilo de resposta
- Exemplo de uso:
  ```
  User: "Qual o preço?"
  Assistant: "Claro! Vou enviar a tabela..."
  User: "E o horário?"
  ```

**Tool:**
- Resultado de uma function call
- Usado quando o modelo chamou uma tool
- Contém o retorno da função executada

**Function (deprecated):**
- Substituído por "Tool" em versões recentes
- Não use em novos workflows

### **Messages - Type**

**Text:** (padrão)
- Mensagem de texto simples
- Suporta markdown
- Suporta expressions

**Image (quando resource=image):**
- Análise de imagem (GPT-4 Vision)
- Requer URL ou base64 da imagem

**Audio (quando resource=audio):**
- Para Whisper (transcrição)
- Requer arquivo de áudio

### **Options - Parâmetros Avançados**

**Temperature (0.0 - 2.0):**
- `0.0` = Determinístico, sempre mesma resposta
- `0.7` = ✅ **Recomendado** - Balanceado
- `1.0` = Padrão OpenAI
- `2.0` = Muito criativo/aleatório
- Valores baixos para: FAQ, precisão, consistência
- Valores altos para: Criatividade, brainstorming

**Maximum Tokens:**
- Limite de tokens na resposta
- `1000` = ✅ **Recomendado WF0** (~750 palavras)
- `4096` = Resposta longa
- Afeta custo diretamente
- Não confundir com context window (limite de entrada)

**Top P (0.0 - 1.0):**
- Amostragem nucleus
- `1.0` = Considera todos os tokens (padrão)
- `0.1` = Considera apenas 10% mais prováveis
- Use Temperature OU Top P, não ambos

**Frequency Penalty (-2.0 - 2.0):**
- Penaliza repetição de tokens
- `0.0` = Sem penalidade (padrão)
- `0.5` = Evita repetição moderadamente
- `2.0` = Evita muito repetição
- Útil para: Evitar respostas repetitivas

**Presence Penalty (-2.0 - 2.0):**
- Penaliza tokens já usados (independente de frequência)
- `0.0` = Sem penalidade (padrão)
- `0.6` = Encoraja novos tópicos
- Útil para: Diversidade de resposta

**Stop Sequences:**
- Array de strings que param a geração
- Exemplo: `["\n\n", "###", "FIM"]`
- Útil para: Formatar saídas estruturadas

**Response Format (JSON Mode):**
- Force saída em JSON válido
- Requer mencionar "JSON" no prompt
- Exemplo: `{ "type": "json_object" }`

### **Tools (Function Calling)**

**Quando usar:**
- Modelo precisa buscar dados externos
- Executar ações (agendar, criar registro)
- Cálculos complexos
- Integração com APIs

**Estrutura de uma Tool:**
```json
{
  "type": "function",
  "function": {
    "name": "get_weather",
    "description": "Get current weather for a location",
    "parameters": {
      "type": "object",
      "properties": {
        "location": {
          "type": "string",
          "description": "City name"
        }
      },
      "required": ["location"]
    }
  }
}
```

**Fluxo com Tools no WF0:**
1. LLM recebe mensagem
2. Se precisar de tool, retorna `finish_reason: "tool_calls"`
3. Node "Chamou Tool?" detecta isso
4. Node "Executar Tools" roda as funções
5. Resultado volta para LLM
6. LLM gera resposta final

---

## ⚠️ Erros Comuns

### Erro: "This is a chat model and not supported in the v1/completions endpoint"
**Causa:** Usando typeVersion antiga (1.1) ou endpoint errado  
**Solução:** Use resource: "text" (confuso mas correto no n8n 1.118.1), operation: "message"

### Erro: "Parameter 'modelId' is not defined"
**Causa:** Parâmetro obsoleto (versões antigas usavam "modelId")  
**Solução:** Use "model" ao invés de "modelId"

### Erro: "messages.messageValues is not iterable"
**Causa:** Estrutura antiga (messageValues)  
**Solução:** Use "messages.values" ao invés de "messages.messageValues"

---

## 🔗 Conexões do WF0

```
Preparar Prompt LLM
        ↓
LLM (GPT-4o-mini + Tools) ← [OpenAI node]
        ↓
Preservar Contexto Após LLM
        ↓
Chamou Tool?
```

---

## 📌 Notas Importantes

1. **Sempre use typeVersion 1.6** para chat completions
2. **Resource deve ser "chat"**, não "text"
3. **Messages devem ter array "values"**, não "messageValues"
4. **Model (não modelId)** desde typeVersion 1.5+
5. **Expressions (fx)** são obrigatórias para valores dinâmicos

---

**Última atualização:** 08/11/2025  
**Workflow:** WF0-Gestor-Universal  
**Projeto:** saas-multi-tenant

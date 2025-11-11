# 🚀 ADICIONAR 10 NODES DE ENVIO DE MÍDIA

## 📍 ONDE INSERIR

**DEPOIS DO NODE:** "Log Chatwoot Response"  
**ANTES DE:** (nada - é o final do workflow)

---

## 🎯 FLUXO COMPLETO

```
Log Chatwoot Response
  ↓
1️⃣ Detectar Mídia
  ↓
2️⃣ IF: Tem Mídia?
  ├─→ TRUE → 3️⃣ Preparar → 4️⃣ Loop → 5️⃣ Download → 6️⃣ Upload → 7️⃣ Log → 9️⃣ Texto Final → 🔟 Enviar
  └─→ FALSE → 8️⃣ Enviar Texto (sem mídia)
```

---

## ⚙️ CONFIGURAÇÃO DE CADA NODE

### 1️⃣ **Detectar Mídia na Resposta** (Code)

**Type:** Code (JavaScript)  
**Code:**
```javascript
const clientMediaAttachments = $input.item.json.client_media_attachments || [];
const hasMedia = clientMediaAttachments.length > 0;

console.log('🔍 Tem mídia?', hasMedia);
console.log('📎 Arquivos:', clientMediaAttachments.length);

return {
  json: {
    ...($input.item.json),
    has_media_to_send: hasMedia
  }
};
```

---

### 2️⃣ **Tem Mídia para Enviar?** (IF)

**Type:** IF  
**Condition:**
- Value 1: `{{ $json.has_media_to_send }}`
- Operation: `equals`
- Value 2: `true`

**Connections:**
- **TRUE → 3️⃣ Preparar Arquivos**
- **FALSE → 8️⃣ Enviar Texto (Sem Mídia)**

---

### 3️⃣ **Preparar Arquivos** (Code)

**Type:** Code  
**Code:**
```javascript
const attachments = $input.item.json.client_media_attachments || [];

console.log('📦 Preparando', attachments.length, 'arquivo(s)');

return {
  json: {
    ...$input.item.json,
    files_to_send: attachments
  }
};
```

---

### 4️⃣ **Loop: Cada Arquivo** (Code)

**Type:** Code  
**Code:**
```javascript
const files = $input.item.json.files_to_send || [];
const baseData = $input.item.json;

console.log('🔁 Criando', files.length, 'item(s) para loop');

if (files.length === 0) {
  return [{ json: baseData }];
}

return files.map(file => ({
  json: {
    ...baseData,
    current_file: file
  }
}));
```

---

### 5️⃣ **Download Arquivo do Supabase** (HTTP Request)

**Type:** HTTP Request  
**Method:** GET  
**URL:** `{{ $json.current_file.file_url }}`  
**Options → Response:**
- **Response Format:** `file` ← **CRÍTICO!**

---

### 6️⃣ **Upload Arquivo para Chatwoot** (HTTP Request)

**Type:** HTTP Request  
**Method:** POST  
**URL:** `https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}/messages`

**Send Headers:** ON
- Header: `api_access_token` = `zL8FNtrajZjGv4LP9BrZiCif`

**Send Body:** ON  
**Content Type:** `multipart/form-data`

**Body Parameters:**
1. Name: `message_type` | Value: `outgoing`
2. Name: `private` | Value: `false`
3. Name: `attachments[]` | **Type: Form Binary Data** | **Input Data Field Name:** `data`

**Options:**
- **Continue On Fail:** ON
- **Full Response:** ON

---

### 7️⃣ **Log Envio Arquivo** (Code)

**Type:** Code  
**Code:**
```javascript
const response = $input.item.json;
const file = $input.item.json.current_file || {};
const success = response.statusCode >= 200 && response.statusCode < 300;

console.log('📤 Enviado:', file.file_name);
console.log('✅ Status:', response.statusCode, success ? 'OK' : 'ERRO');

return {
  json: {
    file_name: file.file_name,
    status_code: response.statusCode,
    sent_ok: success,
    conversation_id: $input.item.json.conversation_id
  }
};
```

---

### 8️⃣ **Enviar Texto (Sem Mídia)** (HTTP Request)

**Type:** HTTP Request  
**Method:** POST  
**URL:** `https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}/messages`

**Send Headers:** ON
- Header: `api_access_token` = `zL8FNtrajZjGv4LP9BrZiCif`

**Send Body:** ON  
**Body Parameters:**
1. Name: `content` | Value: `={{ $json.final_response }}`
2. Name: `message_type` | Value: `outgoing`
3. Name: `private` | Value: `false`

**Options:**
- **Continue On Fail:** ON

---

### 9️⃣ **Preparar Texto Final** (Code)

**Type:** Code  
**Code:**
```javascript
const baseData = $('2️⃣ Tem Mídia para Enviar?').first().json;

console.log('📝 Preparando texto final');

return {
  json: {
    conversation_id: baseData.conversation_id,
    final_response: baseData.final_response
  }
};
```

---

### 🔟 **Enviar Texto Acompanhando** (HTTP Request)

**Type:** HTTP Request  
**Method:** POST  
**URL:** `https://chatwoot.evolutedigital.com.br/api/v1/accounts/1/conversations/{{ $json.conversation_id }}/messages`

**Send Headers:** ON
- Header: `api_access_token` = `zL8FNtrajZjGv4LP9BrZiCif`

**Send Body:** ON  
**Body Parameters:**
1. Name: `content` | Value: `={{ $json.final_response }}`
2. Name: `message_type` | Value: `outgoing`
3. Name: `private` | Value: `false`

**Options:**
- **Continue On Fail:** ON

---

## 🔗 CONEXÕES

```
Log Chatwoot Response → 1️⃣ Detectar Mídia
1️⃣ → 2️⃣ IF
2️⃣ TRUE → 3️⃣ Preparar
2️⃣ FALSE → 8️⃣ Texto Sem Mídia
3️⃣ → 4️⃣ Loop
4️⃣ → 5️⃣ Download
5️⃣ → 6️⃣ Upload
6️⃣ → 7️⃣ Log
7️⃣ → 9️⃣ Texto Final
9️⃣ → 🔟 Enviar Texto
```

---

## ⚠️ PONTOS CRÍTICOS

### **Node 5️⃣ (Download):**
- ✅ **Options → Response → Response Format: `file`**
- ❌ Se não configurar, download falha!

### **Node 6️⃣ (Upload):**
- ✅ **Content Type: `multipart/form-data`**
- ✅ **Parameter Type: `Form Binary Data`**
- ✅ **Input Data Field Name: `data`**
- ❌ Se usar "string" ou "file", Chatwoot rejeita!

---

## 🧪 TESTAR

1. **Salvar workflow**
2. **Enviar pelo WhatsApp:** "quero ver a clínica"
3. **Esperar:**
   - Bot envia FOTO (consultorio-recepcao.jpg)
   - Bot envia TEXTO ("Claro! Estou enviando...")

**Se funcionar:** 🎉 **WORKFLOW COMPLETO!**

**Se falhar:** Me manda os logs dos nodes 5️⃣, 6️⃣ e 7️⃣!

---

**Bora adicionar os 10 nodes! Qualquer dúvida, grita!** 🚀

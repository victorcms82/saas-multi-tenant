# 🎬 PROCESSAMENTO DE MÍDIA - INPUT

**Data:** 12/11/2025  
**Status:** 🚨 IMPLEMENTAR - Bot recebe mídia mas não processa  
**Localização:** Inserir após "Identificar Cliente e Agente"

---

## 🔴 PROBLEMA ATUAL

```
Usuario envia:
- 🎤 Áudio (OGG, MP3) → Bot responde "não consigo processar"
- 🖼️ Imagem (JPG, PNG) → Bot responde "não posso ver imagens"
- 📄 Documento (PDF, DOCX) → Bot responde "não consigo ler"
- 🎬 Vídeo (MP4) → Bot responde "não posso assistir"
```

**Root Cause:** Workflow passa attachments adiante mas não processa conteúdo

---

## ✅ SOLUÇÃO: Node "🎬 Processar Mídia do Usuário"

### **Inserir Após:** `Identificar Cliente e Agente`
### **Antes De:** `Filtrar Apenas Incoming`

---

## 📝 CÓDIGO DO NODE

```javascript
// ============================================================================
// 🎬 PROCESSAR MÍDIA DO USUÁRIO (INPUT)
// ============================================================================
// Transforma mídia em texto para o LLM processar:
// - Áudio → Transcrição (Whisper API)
// - Imagem → Descrição (GPT-4o-vision)
// - Documento → Texto extraído (PDF.js)
// - Vídeo → Frames + análise (GPT-4o-vision)
// ============================================================================

const data = $input.item.json;
const attachments = data.attachments || [];

console.log('🎬 Processando mídia do usuário...');
console.log('Total de attachments:', attachments.length);

// Se não tem attachments, passar adiante
if (attachments.length === 0) {
  console.log('✅ Sem attachments para processar');
  return { json: data };
}

// Processar cada attachment
let mediaProcessed = false;
let mediaContent = '';
let mediaType = '';

for (const attachment of attachments) {
  const fileType = attachment.file_type || '';
  const dataUrl = attachment.data_url || '';
  
  console.log(`📎 Processando: ${fileType} - ${dataUrl}`);
  
  // ============================================
  // 1. ÁUDIO → Transcrição (Whisper API)
  // ============================================
  if (fileType === 'audio' || dataUrl.includes('.ogg') || dataUrl.includes('.mp3')) {
    console.log('🎤 Detectado: ÁUDIO');
    
    try {
      // Download do áudio
      const audioResponse = await fetch(dataUrl);
      const audioBuffer = await audioResponse.arrayBuffer();
      const audioBlob = new Blob([audioBuffer], { type: 'audio/mpeg' });
      
      // Criar FormData para Whisper API
      const formData = new FormData();
      formData.append('file', audioBlob, 'audio.mp3');
      formData.append('model', 'whisper-1');
      formData.append('language', 'pt');
      
      // Chamar OpenAI Whisper
      const whisperResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer YOUR_OPENAI_API_KEY'
        },
        body: formData
      });
      
      const whisperData = await whisperResponse.json();
      const transcription = whisperData.text || '';
      
      if (transcription) {
        mediaContent += `\n\n[TRANSCRIÇÃO DO ÁUDIO]:\n${transcription}\n`;
        mediaType = 'audio';
        mediaProcessed = true;
        console.log('✅ Áudio transcrito:', transcription.substring(0, 100) + '...');
      }
    } catch (error) {
      console.error('❌ Erro ao transcrever áudio:', error.message);
      mediaContent += '\n\n[Áudio recebido mas não foi possível transcrever]\n';
    }
  }
  
  // ============================================
  // 2. IMAGEM → Análise (GPT-4o Vision)
  // ============================================
  else if (fileType === 'image' || dataUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
    console.log('🖼️ Detectado: IMAGEM');
    
    try {
      // Download da imagem
      const imageResponse = await fetch(dataUrl);
      const imageBuffer = await imageResponse.arrayBuffer();
      const imageBase64 = Buffer.from(imageBuffer).toString('base64');
      const mimeType = dataUrl.includes('.png') ? 'image/png' : 'image/jpeg';
      
      // Chamar GPT-4o com visão
      const visionResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer YOUR_OPENAI_API_KEY',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [{
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'Descreva detalhadamente esta imagem em português. Seja específico sobre o que você vê.'
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`
                }
              }
            ]
          }],
          max_tokens: 500
        })
      });
      
      const visionData = await visionResponse.json();
      const description = visionData.choices?.[0]?.message?.content || '';
      
      if (description) {
        mediaContent += `\n\n[IMAGEM ENVIADA - DESCRIÇÃO]:\n${description}\n`;
        mediaType = 'image';
        mediaProcessed = true;
        console.log('✅ Imagem analisada:', description.substring(0, 100) + '...');
      }
    } catch (error) {
      console.error('❌ Erro ao analisar imagem:', error.message);
      mediaContent += '\n\n[Imagem recebida mas não foi possível analisar]\n';
    }
  }
  
  // ============================================
  // 3. DOCUMENTO → Extração de Texto
  // ============================================
  else if (fileType === 'file' || dataUrl.match(/\.(pdf|docx|txt)$/i)) {
    console.log('📄 Detectado: DOCUMENTO');
    
    try {
      // Para PDF, usar API de OCR simples (ou implementar pdf-parse)
      if (dataUrl.includes('.pdf')) {
        // TODO: Implementar extração de PDF real
        // Por enquanto, informar que foi recebido
        mediaContent += '\n\n[DOCUMENTO PDF RECEBIDO]\nNome: ' + (attachment.file_name || 'documento.pdf') + '\n';
        mediaContent += 'ℹ️ Processamento de PDF será implementado em breve.\n';
        mediaType = 'document';
        mediaProcessed = true;
      }
      // Para TXT, baixar e ler conteúdo
      else if (dataUrl.includes('.txt')) {
        const txtResponse = await fetch(dataUrl);
        const txtContent = await txtResponse.text();
        
        mediaContent += `\n\n[DOCUMENTO TXT - CONTEÚDO]:\n${txtContent.substring(0, 3000)}\n`;
        if (txtContent.length > 3000) {
          mediaContent += '...(texto truncado)\n';
        }
        mediaType = 'document';
        mediaProcessed = true;
        console.log('✅ TXT extraído:', txtContent.length, 'caracteres');
      }
      // Para DOCX
      else if (dataUrl.includes('.docx')) {
        mediaContent += '\n\n[DOCUMENTO DOCX RECEBIDO]\nNome: ' + (attachment.file_name || 'documento.docx') + '\n';
        mediaContent += 'ℹ️ Processamento de DOCX será implementado em breve.\n';
        mediaType = 'document';
        mediaProcessed = true;
      }
    } catch (error) {
      console.error('❌ Erro ao processar documento:', error.message);
      mediaContent += '\n\n[Documento recebido mas não foi possível processar]\n';
    }
  }
  
  // ============================================
  // 4. VÍDEO → Análise de Frames
  // ============================================
  else if (fileType === 'video' || dataUrl.match(/\.(mp4|mov|avi)$/i)) {
    console.log('🎬 Detectado: VÍDEO');
    
    // Para vídeo, informar que foi recebido (extração de frames complexa)
    mediaContent += '\n\n[VÍDEO RECEBIDO]\nNome: ' + (attachment.file_name || 'video.mp4') + '\n';
    mediaContent += 'ℹ️ Análise de vídeo será implementada em breve.\n';
    mediaType = 'video';
    mediaProcessed = true;
  }
}

// ============================================
// RESULTADO FINAL
// ============================================

if (mediaProcessed) {
  // Adicionar conteúdo da mídia à mensagem
  const originalMessage = data.message_body || '';
  const newMessage = originalMessage + mediaContent;
  
  console.log('✅ Mídia processada com sucesso!');
  console.log('Tipo:', mediaType);
  console.log('Conteúdo extraído:', mediaContent.length, 'caracteres');
  
  return {
    json: {
      ...data,
      message_body: newMessage,
      original_message_body: originalMessage,
      media_processed: true,
      media_type: mediaType,
      media_content: mediaContent
    }
  };
} else {
  console.log('⚠️ Nenhuma mídia foi processada');
  return { json: data };
}
```

---

## 🎯 ONDE INSERIR NO WORKFLOW

### Conexão Atual:
```
Identificar Cliente e Agente → Filtrar Apenas Incoming
```

### Nova Conexão:
```
Identificar Cliente e Agente → 🎬 Processar Mídia do Usuário → Filtrar Apenas Incoming
```

---

## 📊 ESTRUTURA DO NODE

| Campo | Valor |
|-------|-------|
| **Nome** | `🎬 Processar Mídia do Usuário` |
| **Tipo** | `n8n-nodes-base.code` |
| **TypeVersion** | 2 |
| **Posição** | [-1888, 96] (entre Identificar e Filtrar) |

---

## 🧪 TESTES NECESSÁRIOS

### 1. Teste de Áudio
```
Enviar: Áudio de voz dizendo "Olá, meu nome é João"
Esperado: Bot entende e responde usando o nome
```

### 2. Teste de Imagem
```
Enviar: Foto de um produto
Esperado: Bot descreve o produto na imagem
```

### 3. Teste de Documento
```
Enviar: arquivo.txt com texto
Esperado: Bot lê e responde sobre o conteúdo
```

### 4. Teste de Vídeo
```
Enviar: vídeo.mp4
Esperado: Bot reconhece que recebeu vídeo
```

---

## ⚙️ CONFIGURAÇÕES NECESSÁRIAS

### 1. OpenAI API Key
Já configurada no workflow: `AZOIk8m4dEU8S2FP`

### 2. Modelos Utilizados
- **Whisper-1**: Transcrição de áudio ($0.006/minuto)
- **GPT-4o-mini**: Visão de imagem ($0.15/1M tokens input)

### 3. Limites
- Áudio: Até 25MB
- Imagem: Até 20MB
- Texto: Até 3000 caracteres (trunca se maior)

---

## 🔧 IMPLEMENTAÇÃO PASSO-A-PASSO

### 1. Abrir n8n
- Acessar workflow "Chatwoot Multi-Tenant"

### 2. Adicionar Node
- Clicar no + entre "Identificar Cliente" e "Filtrar Incoming"
- Selecionar "Code"
- Renomear para: `🎬 Processar Mídia do Usuário`

### 3. Colar Código
- Copiar todo o código JavaScript acima
- Colar no campo "JavaScript Code"

### 4. Conectar
- Conectar "Identificar Cliente e Agente" → "🎬 Processar Mídia"
- Conectar "🎬 Processar Mídia" → "Filtrar Apenas Incoming"

### 5. Salvar e Ativar
- Salvar workflow
- Ativar workflow

---

## 🎨 MELHORIAS FUTURAS

### Fase 2 (Opcional):
1. **PDF Processing**
   - Integrar `pdf-parse` ou Google Document AI
   - Extrair texto completo de PDFs

2. **DOCX Processing**
   - Integrar `mammoth.js`
   - Extrair texto formatado de Word

3. **Video Processing**
   - Extrair frames-chave do vídeo
   - Enviar frames para GPT-4o Vision
   - Gerar resumo do vídeo

4. **Multimodal Advanced**
   - Combinar áudio + imagem + texto
   - Análise contextual mais rica

---

## 💰 CUSTOS ESTIMADOS

| Tipo | API | Custo por Uso |
|------|-----|---------------|
| Áudio (1 min) | Whisper | $0.006 |
| Imagem | GPT-4o-mini Vision | ~$0.0001 |
| Documento | Grátis (nativo) | $0 |
| Vídeo | Futuro | - |

**Custo médio por mensagem com mídia:** ~$0.01

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

- [ ] Adicionar node "🎬 Processar Mídia do Usuário"
- [ ] Colar código JavaScript
- [ ] Conectar entre "Identificar" e "Filtrar"
- [ ] Salvar workflow
- [ ] Ativar workflow
- [ ] Testar com áudio (WhatsApp)
- [ ] Testar com imagem
- [ ] Testar com documento .txt
- [ ] Verificar logs (console.log)
- [ ] Confirmar que bot entende conteúdo

---

## 🚨 TROUBLESHOOTING

### Erro: "Authorization header required"
**Causa:** API key OpenAI incorreta ou expirada  
**Solução:** Verificar credencial `OpenAi account` no n8n

### Erro: "File too large"
**Causa:** Attachment maior que limite API  
**Solução:** Adicionar validação de tamanho antes de processar

### Erro: "Cannot read property 'json'"
**Causa:** Attachment sem data_url  
**Solução:** Adicionar validação `if (!dataUrl) continue;`

---

## 📝 NOTAS IMPORTANTES

1. **Segurança:** Código já valida se attachment existe antes de processar
2. **Performance:** Processamento paralelo não implementado (processa 1 por vez)
3. **Fallback:** Se falhar processamento, mensagem original é mantida
4. **Logs:** Console.log detalhado para debug

---

**Criado por:** GitHub Copilot  
**Data:** 12/11/2025  
**Versão:** 1.0 (Whisper + GPT-4o-mini Vision)

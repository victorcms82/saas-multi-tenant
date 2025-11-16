// ============================================================================
// 🎬 PROCESSAMENTO COMPLETO DE MÍDIA - VERSÃO FINAL
// ============================================================================
// Suporta: Imagens (Vision API), Áudio (Whisper API), TXT, PDF, DOCX, Video
// OpenAI APIs: GPT-4o-mini Vision + Whisper
// ============================================================================

const items = $input.all();
const processedItems = [];

for (const item of items) {
  const data = item.json;
  const attachments = data.attachments || [];
  
  if (attachments.length === 0) {
    processedItems.push({ json: data });
    continue;
  }
  
  let mediaProcessed = false;
  let mediaContent = '';
  let mediaType = '';
  
  for (const attachment of attachments) {
    const fileType = attachment.file_type || '';
    const dataUrl = attachment.data_url || '';
    
    if (!dataUrl) continue;
    
    // ========================================
    // 🖼️ PROCESSAR IMAGEM (Vision API)
    // ========================================
    if (fileType === 'image' || dataUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
      try {
        const imageResponse = await fetch(dataUrl);
        const imageBuffer = await imageResponse.arrayBuffer();
        const imageBase64 = Buffer.from(imageBuffer).toString('base64');
        
        let mimeType = 'image/jpeg';
        if (dataUrl.includes('.png')) mimeType = 'image/png';
        else if (dataUrl.includes('.webp')) mimeType = 'image/webp';
        else if (dataUrl.includes('.gif')) mimeType = 'image/gif';
        
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
                  text: 'Descreva detalhadamente esta imagem em português. Seja específico sobre o que você vê, incluindo objetos, pessoas, cores, texto visível e contexto geral.'
                },
                {
                  type: 'image_url',
                  image_url: { url: `data:${mimeType};base64,${imageBase64}` }
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
        }
      } catch (error) {
        console.error('Erro ao processar imagem:', error.message);
        mediaContent += '\n\n[Imagem recebida mas não foi possível analisar]\n';
      }
    }
    
    // ========================================
    // 🎵 PROCESSAR ÁUDIO (Whisper API)
    // ========================================
    else if (fileType === 'audio' || dataUrl.match(/\.(mp3|wav|m4a|ogg|opus|webm)$/i)) {
      try {
        const audioResponse = await fetch(dataUrl);
        const audioBuffer = await audioResponse.arrayBuffer();
        const audioBlob = new Blob([audioBuffer], { type: 'audio/mpeg' });
        
        const formData = new FormData();
        formData.append('file', audioBlob, 'audio.mp3');
        formData.append('model', 'whisper-1');
        formData.append('language', 'pt');
        formData.append('response_format', 'text');
        
        const whisperResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
          method: 'POST',
          headers: {
            'Authorization': 'Bearer YOUR_OPENAI_API_KEY'
          },
          body: formData
        });
        
        const transcription = await whisperResponse.text();
        
        if (transcription) {
          mediaContent += `\n\n[ÁUDIO ENVIADO - TRANSCRIÇÃO]:\n${transcription}\n`;
          mediaType = 'audio';
          mediaProcessed = true;
        }
      } catch (error) {
        console.error('Erro ao processar áudio:', error.message);
        mediaContent += '\n\n[Áudio recebido mas não foi possível transcrever]\n';
      }
    }
    
    // ========================================
    // 📄 PROCESSAR ARQUIVO TXT
    // ========================================
    else if (fileType === 'file' && dataUrl.match(/\.txt$/i)) {
      try {
        const txtResponse = await fetch(dataUrl);
        let txtContent = await txtResponse.text();
        
        if (txtContent.length > 5000) {
          txtContent = txtContent.substring(0, 5000) + '\n\n[... conteúdo truncado por tamanho]';
        }
        
        mediaContent += `\n\n[ARQUIVO TXT ENVIADO - CONTEÚDO]:\n${txtContent}\n`;
        mediaType = 'text';
        mediaProcessed = true;
      } catch (error) {
        console.error('Erro ao processar TXT:', error.message);
        mediaContent += '\n\n[Arquivo TXT recebido mas não foi possível ler]\n';
      }
    }
    
    // ========================================
    // 📑 RECONHECER PDF/DOCX (sem extração)
    // ========================================
    else if (dataUrl.match(/\.(pdf|doc|docx)$/i)) {
      const docType = dataUrl.match(/\.pdf$/i) ? 'PDF' : 'Word';
      mediaContent += `\n\n[DOCUMENTO ${docType} RECEBIDO]\nPor favor, me diga qual informação específica você precisa deste documento.\n`;
      mediaType = 'document';
      mediaProcessed = true;
    }
    
    // ========================================
    // 🎬 RECONHECER VÍDEO (sem processamento)
    // ========================================
    else if (fileType === 'video' || dataUrl.match(/\.(mp4|avi|mov|wmv|flv|webm)$/i)) {
      mediaContent += `\n\n[VÍDEO RECEBIDO]\nRecebi seu vídeo. Por favor, descreva o que você gostaria que eu analisasse ou entendesse dele.\n`;
      mediaType = 'video';
      mediaProcessed = true;
    }
  }
  
  // ========================================
  // ✅ CONSTRUIR RESULTADO FINAL
  // ========================================
  if (mediaProcessed) {
    const originalMessage = data.message_body || '';
    const newMessage = originalMessage + mediaContent;
    
    processedItems.push({
      json: {
        ...data,
        message_body: newMessage,
        original_message_body: originalMessage,
        media_processed: true,
        media_type: mediaType,
        media_content: mediaContent
      }
    });
  } else {
    processedItems.push({ json: data });
  }
}

return processedItems;

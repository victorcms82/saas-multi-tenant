// ============================================================================
// 🎬 PROCESSAR MÍDIA DO USUÁRIO (INPUT)
// ============================================================================
// Node: Inserir APÓS "Identificar Cliente e Agente"
// Posição: [-1888, 96]
// ============================================================================

// n8n itera sobre items, então processamos todos
const items = $input.all();
const processedItems = [];

for (const item of items) {
  const data = item.json;
  const attachments = data.attachments || [];

  console.log('🎬 Processando mídia do usuário...');
  console.log('Total de attachments:', attachments.length);

  if (attachments.length === 0) {
    console.log('✅ Sem attachments para processar');
    processedItems.push({ json: data });
    continue;
  }

  let mediaProcessed = false;
  let mediaContent = '';
  let mediaType = '';

  for (const attachment of attachments) {
    const fileType = attachment.file_type || '';
    const dataUrl = attachment.data_url || '';
    
    if (!dataUrl) {
      console.log('⚠️ Attachment sem data_url, pulando...');
      continue;
    }
    
    console.log(`📎 Processando: ${fileType} - ${dataUrl.substring(0, 50)}...`);
    
    // ==========================================
    // 1. ÁUDIO → Transcrição (Whisper API)
    // ==========================================
    if (fileType === 'audio' || dataUrl.match(/\.(ogg|mp3|m4a|wav)$/i)) {
      console.log('🎤 Detectado: ÁUDIO');
    
    try {
      const audioResponse = await fetch(dataUrl);
      const audioBuffer = await audioResponse.arrayBuffer();
      const audioBlob = new Blob([audioBuffer], { type: 'audio/mpeg' });
      
      const formData = new FormData();
      formData.append('file', audioBlob, 'audio.mp3');
      formData.append('model', 'whisper-1');
      formData.append('language', 'pt');
      
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
  
  // ==========================================
  // 2. IMAGEM → Análise (GPT-4o Vision)
  // ==========================================
  else if (fileType === 'image' || dataUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
    console.log('🖼️ Detectado: IMAGEM');
    
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
  
  // ==========================================
  // 3. DOCUMENTO → Extração de Texto
  // ==========================================
  else if (fileType === 'file' || dataUrl.match(/\.(pdf|docx|txt|doc)$/i)) {
    console.log('📄 Detectado: DOCUMENTO');
    
    try {
      if (dataUrl.match(/\.txt$/i)) {
        // TXT: Baixar e ler conteúdo
        const txtResponse = await fetch(dataUrl);
        const txtContent = await txtResponse.text();
        
        mediaContent += `\n\n[DOCUMENTO TXT - CONTEÚDO]:\n${txtContent.substring(0, 5000)}\n`;
        if (txtContent.length > 5000) {
          mediaContent += '...(texto truncado para os primeiros 5000 caracteres)\n';
        }
        mediaType = 'document';
        mediaProcessed = true;
        console.log('✅ TXT extraído:', txtContent.length, 'caracteres');
      } 
      else if (dataUrl.match(/\.pdf$/i)) {
        // PDF: Informar recebimento (processamento completo requer biblioteca)
        const fileName = attachment.file_name || 'documento.pdf';
        mediaContent += `\n\n[DOCUMENTO PDF RECEBIDO]\nNome: ${fileName}\n`;
        mediaContent += 'O arquivo PDF foi recebido. Para análise detalhada, por favor descreva o que você precisa saber sobre o documento.\n';
        mediaType = 'document';
        mediaProcessed = true;
        console.log('✅ PDF recebido:', fileName);
      }
      else if (dataUrl.match(/\.(docx|doc)$/i)) {
        // DOCX/DOC: Informar recebimento
        const fileName = attachment.file_name || 'documento.docx';
        mediaContent += `\n\n[DOCUMENTO WORD RECEBIDO]\nNome: ${fileName}\n`;
        mediaContent += 'O arquivo Word foi recebido. Para análise detalhada, por favor descreva o que você precisa saber sobre o documento.\n';
        mediaType = 'document';
        mediaProcessed = true;
        console.log('✅ DOCX recebido:', fileName);
      }
    } catch (error) {
      console.error('❌ Erro ao processar documento:', error.message);
      mediaContent += '\n\n[Documento recebido mas não foi possível processar]\n';
    }
  }
  
  // ==========================================
  // 4. VÍDEO → Informar Recebimento
  // ==========================================
  else if (fileType === 'video' || dataUrl.match(/\.(mp4|mov|avi|webm)$/i)) {
    console.log('🎬 Detectado: VÍDEO');
    
    const fileName = attachment.file_name || 'video.mp4';
    mediaContent += `\n\n[VÍDEO RECEBIDO]\nNome: ${fileName}\n`;
    mediaContent += 'O vídeo foi recebido. Para análise detalhada, por favor descreva o que você precisa saber sobre o conteúdo.\n';
    mediaType = 'video';
    mediaProcessed = true;
    console.log('✅ Vídeo recebido:', fileName);
  }
  
  // ==========================================
  // 5. OUTROS FORMATOS
  // ==========================================
  else {
    console.log('⚠️ Formato não reconhecido:', fileType, dataUrl.substring(0, 50));
    const fileName = attachment.file_name || 'arquivo';
    mediaContent += `\n\n[ARQUIVO RECEBIDO]\nNome: ${fileName}\nTipo: ${fileType || 'desconhecido'}\n`;
    mediaProcessed = true;
  }
}

  // ==========================================
  // RESULTADO FINAL
  // ==========================================

  if (mediaProcessed) {
    const originalMessage = data.message_body || '';
    const newMessage = originalMessage + mediaContent;
    
    console.log('✅ Mídia processada com sucesso!');
    console.log('Tipo:', mediaType);
    console.log('Conteúdo extraído:', mediaContent.length, 'caracteres');
    
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
    console.log('⚠️ Nenhuma mídia foi processada');
    processedItems.push({ json: data });
  }
}

// Retorna todos os items processados
return processedItems;

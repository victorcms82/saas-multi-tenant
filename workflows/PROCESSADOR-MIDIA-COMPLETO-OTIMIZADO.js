// ============================================================================
// 🎬 PROCESSADOR DE MÍDIA COMPLETO - VERSÃO OTIMIZADA COM DEBUG
// ============================================================================
// Processa TODOS os tipos de mídia em um único node:
// ✅ Imagens → OpenAI Vision (descrição detalhada)
// ✅ Áudio → Whisper API (transcrição em português)
// ✅ TXT → Extração de texto
// ✅ PDF/DOCX → Reconhecimento (solicita detalhes)
// ✅ Vídeo → Reconhecimento (solicita descrição)
// ============================================================================

console.log('\n========== 🎬 INÍCIO PROCESSAMENTO MÍDIA ==========');

const items = $input.all();
const processedItems = [];

console.log('📦 Items recebidos:', items.length);

for (const item of items) {
  const data = item.json;
  
  console.log('\n--- PROCESSANDO ITEM ---');
  console.log('Has attachments (root)?', 'attachments' in data);
  console.log('Has body.attachments?', data.body?.attachments ? true : false);
  
  // 🔧 CORREÇÃO: Buscar attachments do lugar correto
  // Pode estar em: data.attachments OU data.body.attachments
  let attachments = data.attachments || [];
  
  // Se não achou no nível raiz, busca dentro de body
  if (attachments.length === 0 && data.body?.attachments) {
    attachments = data.body.attachments;
    console.log('✅ Attachments encontrados em body.attachments');
  }
  
  console.log('📎 Total de attachments:', attachments.length);
  
  // Se não tem attachments, passa direto
  if (attachments.length === 0) {
    console.log('⚠️ Nenhum attachment - passando direto');
    processedItems.push({ json: data });
    continue;
  }
  
  let allMediaContent = '';
  let mediaTypes = [];
  let processedCount = 0;
  
  // ============================================================================
  // PROCESSAR CADA ATTACHMENT
  // ============================================================================
  for (const attachment of attachments) {
    const fileType = attachment.file_type || '';
    const dataUrl = attachment.data_url || '';
    
    console.log(`\n  📎 Processando attachment:`);
    console.log('  - file_type:', fileType);
    console.log('  - data_url:', dataUrl ? dataUrl.substring(0, 80) + '...' : 'VAZIO');
    
    if (!dataUrl) {
      console.log('  ⚠️ data_url vazio, pulando...');
      continue;
    }
    
    try {
      // ========================================
      // 🖼️ IMAGEM - Vision API
      // ========================================
      if (fileType === 'image' || dataUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
        console.log('  🖼️ TIPO: IMAGEM detectado!');
        console.log('  📥 Baixando imagem...');
        
        const imageResponse = await fetch(dataUrl);
        console.log('  ✅ Download OK, status:', imageResponse.status);
        
        const imageBuffer = await imageResponse.arrayBuffer();
        console.log('  ✅ Buffer OK, size:', imageBuffer.byteLength, 'bytes');
        
        const imageBase64 = Buffer.from(imageBuffer).toString('base64');
        console.log('  ✅ Base64 OK, length:', imageBase64.length, 'chars');
        
        // Detectar MIME type
        let mimeType = 'image/jpeg';
        if (dataUrl.includes('.png')) mimeType = 'image/png';
        else if (dataUrl.includes('.webp')) mimeType = 'image/webp';
        else if (dataUrl.includes('.gif')) mimeType = 'image/gif';
        console.log('  📄 MIME type:', mimeType);
        
        console.log('  🤖 Chamando OpenAI Vision API...');
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
                  text: 'Descreva esta imagem em português de forma detalhada. Inclua: objetos visíveis, pessoas (se houver), cores, texto legível, e contexto geral.'
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
        
        console.log('  ✅ Vision API respondeu, status:', visionResponse.status);
        
        const visionData = await visionResponse.json();
        console.log('  📊 Response preview:', JSON.stringify(visionData).substring(0, 150));
        
        const description = visionData.choices?.[0]?.message?.content || '';
        
        if (description) {
          allMediaContent += `\n\n[IMAGEM ENVIADA PELO USUÁRIO]:\n${description}\n`;
          mediaTypes.push('image');
          processedCount++;
          console.log('  ✅ IMAGEM PROCESSADA COM SUCESSO!');
          console.log('  📝 Descrição:', description.substring(0, 100) + '...');
        } else {
          console.log('  ⚠️ Vision API não retornou descrição');
        }
      }
      
      // ========================================
      // 🎵 ÁUDIO - Whisper API
      // ========================================
      else if (fileType === 'audio' || dataUrl.match(/\.(mp3|wav|m4a|ogg|opus|webm|mpeg)$/i)) {
        const audioResponse = await fetch(dataUrl);
        const audioBuffer = await audioResponse.arrayBuffer();
        
        // Criar FormData para Whisper
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
          allMediaContent += `\n\n[ÁUDIO ENVIADO PELO USUÁRIO - TRANSCRIÇÃO]:\n${transcription}\n`;
          mediaTypes.push('audio');
          processedCount++;
        }
      }
      
      // ========================================
      // 📄 ARQUIVO TXT
      // ========================================
      else if (fileType === 'file' && dataUrl.match(/\.txt$/i)) {
        const txtResponse = await fetch(dataUrl);
        let txtContent = await txtResponse.text();
        
        // Limitar tamanho
        if (txtContent.length > 5000) {
          txtContent = txtContent.substring(0, 5000) + '\n\n[... conteúdo truncado]';
        }
        
        allMediaContent += `\n\n[ARQUIVO TXT ENVIADO PELO USUÁRIO]:\n${txtContent}\n`;
        mediaTypes.push('text');
        processedCount++;
      }
      
      // ========================================
      // 📑 PDF / DOCX
      // ========================================
      else if (dataUrl.match(/\.(pdf|doc|docx)$/i)) {
        const docType = dataUrl.match(/\.pdf$/i) ? 'PDF' : 'Word';
        allMediaContent += `\n\n[DOCUMENTO ${docType} RECEBIDO]\nRecebeu o documento ${docType}. Me diga qual informação específica você precisa dele.\n`;
        mediaTypes.push('document');
        processedCount++;
      }
      
      // ========================================
      // 🎬 VÍDEO
      // ========================================
      else if (fileType === 'video' || dataUrl.match(/\.(mp4|avi|mov|wmv|flv|webm)$/i)) {
        allMediaContent += `\n\n[VÍDEO RECEBIDO]\nRecebi seu vídeo. Descreva o que você gostaria que eu analisasse nele.\n`;
        mediaTypes.push('video');
        processedCount++;
      }
      
    } catch (error) {
      console.error(`  ❌ ERRO ao processar ${fileType}:`, error.message);
      console.error('  📚 Stack:', error.stack);
      allMediaContent += `\n\n[Arquivo ${fileType} recebido mas não foi possível processar]\n`;
    }
  }
  
  // ============================================================================
  // RETORNAR RESULTADO
  // ============================================================================
  if (processedCount > 0) {
    const newMessage = data.message_body + allMediaContent;
    
    console.log('\n✅ MÍDIA PROCESSADA!');
    console.log('📌 Tipos processados:', mediaTypes.join(', '));
    console.log('📏 Total de arquivos:', processedCount);
    console.log('📝 message_body original:', data.message_body);
    console.log('📝 message_body NOVO (primeiros 200 chars):', newMessage.substring(0, 200));
    
    processedItems.push({
      json: {
        ...data,
        message_body: newMessage,
        original_message_body: data.message_body,
        media_processed: true,
        media_types: mediaTypes,
        media_content: allMediaContent,
        media_count: processedCount
      }
    });
  } else {
    console.log('\n⚠️ Nenhuma mídia foi processada');
    processedItems.push({ json: data });
  }
}

console.log('\n========== 🎬 FIM PROCESSAMENTO MÍDIA ==========');
console.log('📦 Items processados:', processedItems.length);

return processedItems;

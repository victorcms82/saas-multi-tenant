// ============================================================================
// 🔍 DEBUG COMPLETO COM LOGS DETALHADOS
// ============================================================================

console.log('\n========== INÍCIO DO PROCESSAMENTO ==========');

const items = $input.all();
console.log('📦 Items recebidos:', items.length);

const processedItems = [];

for (let i = 0; i < items.length; i++) {
  const item = items[i];
  const data = item.json;
  
  console.log(`\n--- ITEM ${i + 1} ---`);
  console.log('Has attachments field?', 'attachments' in data);
  console.log('Attachments value:', data.attachments);
  console.log('Attachments length:', data.attachments ? data.attachments.length : 'N/A');
  
  const attachments = data.attachments || [];
  
  if (attachments.length === 0) {
    console.log('⚠️ SEM ATTACHMENTS - passando item sem modificar');
    processedItems.push({ json: data });
    continue;
  }
  
  console.log(`\n✅ TEM ${attachments.length} ATTACHMENT(S) - processando...`);
  
  let mediaProcessed = false;
  let mediaContent = '';
  let mediaType = '';
  
  for (let j = 0; j < attachments.length; j++) {
    const attachment = attachments[j];
    console.log(`\n  📎 ATTACHMENT ${j + 1}:`);
    console.log('  - file_type:', attachment.file_type);
    console.log('  - data_url:', attachment.data_url ? attachment.data_url.substring(0, 80) + '...' : 'VAZIO');
    
    const fileType = attachment.file_type || '';
    const dataUrl = attachment.data_url || '';
    
    if (!dataUrl) {
      console.log('  ⚠️ data_url está vazio, pulando...');
      continue;
    }
    
    // DETECTAR TIPO
    if (fileType === 'image' || dataUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
      console.log('  🖼️ TIPO DETECTADO: IMAGEM');
      console.log('  📥 Baixando imagem...');
      
      try {
        const imageResponse = await fetch(dataUrl);
        console.log('  ✅ Download OK, status:', imageResponse.status);
        
        const imageBuffer = await imageResponse.arrayBuffer();
        console.log('  ✅ Buffer OK, size:', imageBuffer.byteLength, 'bytes');
        
        const imageBase64 = Buffer.from(imageBuffer).toString('base64');
        console.log('  ✅ Base64 OK, length:', imageBase64.length, 'chars');
        
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
        
        console.log('  ✅ Vision API respondeu, status:', visionResponse.status);
        
        const visionData = await visionResponse.json();
        console.log('  📊 Response:', JSON.stringify(visionData).substring(0, 200));
        
        const description = visionData.choices?.[0]?.message?.content || '';
        
        if (description) {
          mediaContent += `\n\n[IMAGEM ENVIADA - DESCRIÇÃO]:\n${description}\n`;
          mediaType = 'image';
          mediaProcessed = true;
          console.log('  ✅ IMAGEM ANALISADA COM SUCESSO!');
          console.log('  📝 Descrição:', description.substring(0, 150) + '...');
        } else {
          console.log('  ⚠️ Vision API não retornou descrição');
          console.log('  📊 Full response:', JSON.stringify(visionData));
        }
        
      } catch (error) {
        console.error('  ❌ ERRO:', error.message);
        console.error('  📚 Stack:', error.stack);
        mediaContent += '\n\n[Imagem recebida mas não foi possível analisar]\n';
      }
    } else {
      console.log('  ⚠️ Tipo não é imagem:', fileType);
    }
  }
  
  // RESULTADO
  if (mediaProcessed) {
    const originalMessage = data.message_body || '';
    const newMessage = originalMessage + mediaContent;
    
    console.log('\n✅ MÍDIA PROCESSADA COM SUCESSO!');
    console.log('📌 Tipo:', mediaType);
    console.log('📏 Tamanho do conteúdo:', mediaContent.length, 'caracteres');
    console.log('📝 Mensagem original:', originalMessage);
    console.log('📝 Mensagem nova (primeiros 200 chars):', newMessage.substring(0, 200));
    
    processedItems.push({
      json: {
        ...data,
        message_body: newMessage,
        original_message_body: originalMessage,
        media_processed: true,
        media_type: mediaType,
        media_content: mediaContent,
        DEBUG_PROCESSOU: true
      }
    });
  } else {
    console.log('\n⚠️ NENHUMA MÍDIA FOI PROCESSADA');
    processedItems.push({ json: data });
  }
}

console.log('\n========== FIM DO PROCESSAMENTO ==========');
console.log('📦 Items processados:', processedItems.length);
console.log('✅ Retornando items...\n');

return processedItems;

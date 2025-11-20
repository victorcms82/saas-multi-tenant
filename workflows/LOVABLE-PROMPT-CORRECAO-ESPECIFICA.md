# 🔧 PROMPT DE CORREÇÃO ESPECÍFICA - LOVABLE

Cole este prompt no Lovable para corrigir os 3 bugs restantes:

---

```
Corrigir 3 bugs no chat:

BUG 1: Botão "Assumir Conversa" não funciona
BUG 2: Botão "Devolver para IA" não funciona  
BUG 3: Mensagem não aparece no chat após enviar

CORREÇÕES NECESSÁRIAS:

1. ASSUMIR CONVERSA - Substituir função handleTakeover:

const handleTakeover = async (conversationUuid: string) => {
  try {
    const { data, error } = await supabase.rpc('takeover_conversation', {
      p_conversation_uuid: conversationUuid
    });

    if (error) throw error;
    
    toast.success('Conversa assumida!');
    
    // IMPORTANTE: Recarregar AMBOS
    await loadConversations(); // Atualizar lista
    if (selectedConversation?.id === conversationUuid) {
      await loadConversation(conversationUuid); // Atualizar conversa aberta
    }
  } catch (err) {
    console.error('Erro:', err);
    toast.error('Erro ao assumir conversa');
  }
};

2. DEVOLVER PARA IA - Substituir função handleReturnToAI:

const handleReturnToAI = async (conversationUuid: string) => {
  try {
    const { data, error } = await supabase.rpc('return_to_ai', {
      p_conversation_uuid: conversationUuid
    });

    if (error) throw error;
    
    toast.success('Conversa devolvida para IA');
    
    // IMPORTANTE: Recarregar AMBOS
    await loadConversations();
    if (selectedConversation?.id === conversationUuid) {
      await loadConversation(conversationUuid);
    }
  } catch (err) {
    console.error('Erro:', err);
    toast.error('Erro ao devolver conversa');
  }
};

3. ENVIAR MENSAGEM - Substituir função handleSend:

const handleSend = async () => {
  if (!message.trim() || !selectedConversation) return;

  const messageToSend = message;
  setMessage(''); // Limpar input ANTES de enviar
  
  try {
    const { data, error } = await supabase.rpc('send_human_message', {
      p_conversation_uuid: selectedConversation.id,
      p_message: messageToSend,
      p_client_id: 'clinica_sorriso_001'
    });

    if (error) throw error;
    
    toast.success('Mensagem enviada!');
    
    // CRÍTICO: Recarregar mensagens para exibir a nova
    await loadConversation(selectedConversation.id);
    
  } catch (err) {
    console.error('Erro ao enviar:', err);
    toast.error('Erro ao enviar mensagem');
    setMessage(messageToSend); // Restaurar mensagem em caso de erro
  }
};

4. GARANTIR que loadConversation recarrega as mensagens:

const loadConversation = async (conversationUuid: string) => {
  try {
    const { data, error } = await supabase
      .rpc('get_conversation_detail', { p_conversation_uuid: conversationUuid })
      .single();

    if (error) throw error;
    
    setSelectedConversation(data);
    setMessages(data.messages || []); // CRÍTICO: Atualizar state das mensagens
    
  } catch (err) {
    console.error('Erro ao carregar conversa:', err);
  }
};

IMPORTANTE: 
- Sempre chamar loadConversation() após ações que mudam dados
- Sempre atualizar state de mensagens em loadConversation
- Limpar input ANTES de enviar (melhor UX)
- Recarregar lista E conversa após assumir/devolver
```

---

## ✅ CHECKLIST APÓS APLICAR:

1. Clique "Assumir Conversa"
   - [ ] Toast "Conversa assumida!" aparece
   - [ ] Status muda para "Em Atendimento"
   - [ ] Botão "Devolver para IA" aparece
   - [ ] Input de mensagem libera

2. Digite mensagem e envie
   - [ ] Toast "Mensagem enviada!" aparece
   - [ ] Mensagem APARECE no chat
   - [ ] Input limpa automaticamente

3. Clique "Devolver para IA"
   - [ ] Toast "Conversa devolvida para IA" aparece
   - [ ] Status muda para "Precisa Atenção"
   - [ ] Botão "Assumir" volta
   - [ ] Input bloqueia

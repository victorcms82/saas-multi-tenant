// ============================================================================
// FUNÇÕES CORRETAS PARA O CHAT DO LOVABLE
// ============================================================================
// Arquivo: src/components/Chat.tsx (ou similar no Lovable)

import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

// ============================================================================
// 1. FUNÇÃO: Assumir Conversa
// ============================================================================
const handleTakeover = async (conversationUuid: string) => {
  try {
    console.log('🎯 Assumindo conversa:', conversationUuid);
    
    // Atualizar status para "Em Atendimento" (status_id = 1)
    const { data, error } = await supabase
      .from('conversations')
      .update({ 
        status_id: 1,  // 1 = Em Atendimento
        updated_at: new Date().toISOString()
      })
      .eq('id', conversationUuid)
      .select()
      .single();

    if (error) {
      console.error('❌ Erro ao assumir conversa:', error);
      toast.error('Erro ao assumir conversa: ' + error.message);
      return;
    }

    console.log('✅ Conversa assumida:', data);
    toast.success('Conversa assumida com sucesso!');
    
    // Recarregar dados da conversa
    await loadConversation(conversationUuid);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
    toast.error('Erro ao assumir conversa');
  }
};

// ============================================================================
// 2. FUNÇÃO: Devolver para IA
// ============================================================================
const handleReturnToAI = async (conversationUuid: string) => {
  try {
    console.log('🤖 Devolvendo para IA:', conversationUuid);
    
    // Atualizar status para "Precisa Atenção" (status_id = 2)
    const { data, error } = await supabase
      .from('conversations')
      .update({ 
        status_id: 2,  // 2 = Precisa Atenção (IA assume)
        updated_at: new Date().toISOString()
      })
      .eq('id', conversationUuid)
      .select()
      .single();

    if (error) {
      console.error('❌ Erro ao devolver para IA:', error);
      toast.error('Erro ao devolver conversa: ' + error.message);
      return;
    }

    console.log('✅ Conversa devolvida para IA:', data);
    toast.success('Conversa devolvida para IA');
    
    // Recarregar dados
    await loadConversation(conversationUuid);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
    toast.error('Erro ao devolver conversa');
  }
};

// ============================================================================
// 3. FUNÇÃO: Enviar Mensagem
// ============================================================================
const handleSend = async (conversationUuid: string, conversationId: number, message: string) => {
  if (!message.trim()) {
    toast.error('Digite uma mensagem');
    return;
  }

  try {
    console.log('📤 Enviando mensagem:', { conversationUuid, conversationId, message });
    
    // 1. Verificar se conversa está "Em Atendimento"
    const { data: conv, error: convError } = await supabase
      .from('conversations')
      .select('status_id')
      .eq('id', conversationUuid)
      .single();

    if (convError) {
      console.error('❌ Erro ao verificar status:', convError);
      toast.error('Erro ao verificar status da conversa');
      return;
    }

    if (conv.status_id !== 1) {  // 1 = Em Atendimento
      toast.error('Você precisa assumir a conversa antes de enviar mensagens');
      return;
    }

    // 2. Inserir mensagem na conversation_memory
    const { error: rpcError } = await supabase.rpc('save_conversation_message', {
      p_client_id: 'clinica_sorriso_001',  // TODO: Pegar do contexto do usuário
      p_conversation_id: conversationId,
      p_conversation_uuid: conversationUuid,
      p_message_role: 'user',  // Mensagem do agente humano
      p_message_content: message,
      p_sender_name: 'Agente',  // TODO: Nome do agente logado
      p_has_attachments: false,
      p_attachments: [],
      p_metadata: { sent_by: 'dashboard' }
    });

    if (rpcError) {
      console.error('❌ Erro ao salvar mensagem:', rpcError);
      toast.error('Erro ao enviar mensagem: ' + rpcError.message);
      return;
    }

    console.log('✅ Mensagem salva na memória');

    // 3. TODO: Enviar via Chatwoot API (se necessário)
    // const chatwootResponse = await fetch(`${CHATWOOT_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conversationId}/messages`, {
    //   method: 'POST',
    //   headers: {
    //     'api_access_token': CHATWOOT_TOKEN,
    //     'Content-Type': 'application/json'
    //   },
    //   body: JSON.stringify({
    //     content: message,
    //     message_type: 'outgoing',
    //     private: false
    //   })
    // });

    toast.success('Mensagem enviada!');
    
    // Limpar input
    setMessage('');
    
    // Recarregar mensagens
    await loadConversation(conversationUuid);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
    toast.error('Erro ao enviar mensagem');
  }
};

// ============================================================================
// 4. FUNÇÃO: Carregar Conversa (já existe, mas corrigida)
// ============================================================================
const loadConversation = async (conversationUuid: string) => {
  try {
    console.log('📖 Carregando conversa:', conversationUuid);
    
    // Buscar dados da conversa
    const { data: conv, error: convError } = await supabase
      .rpc('get_conversation_detail', {
        p_conversation_uuid: conversationUuid
      })
      .single();

    if (convError) {
      console.error('❌ Erro ao carregar conversa:', convError);
      toast.error('Erro ao carregar conversa');
      return;
    }

    console.log('✅ Conversa carregada:', conv);
    setConversation(conv);
    
    // Buscar mensagens
    const messages = conv.messages || [];
    console.log('📨 Mensagens:', messages.length);
    setMessages(messages);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
    toast.error('Erro ao carregar conversa');
  }
};

// ============================================================================
// 5. RENDERIZAÇÃO CONDICIONAL DOS BOTÕES
// ============================================================================
// No JSX do componente:
{conversation && (
  <div className="chat-actions">
    {/* Se está "Precisa Atenção" → mostrar botão ASSUMIR */}
    {conversation.status_id === 2 && (
      <button 
        onClick={() => handleTakeover(conversation.id)}
        className="btn-primary"
      >
        🎯 Assumir Conversa
      </button>
    )}
    
    {/* Se está "Em Atendimento" → mostrar botão DEVOLVER */}
    {conversation.status_id === 1 && (
      <button 
        onClick={() => handleReturnToAI(conversation.id)}
        className="btn-secondary"
      >
        🤖 Devolver para IA
      </button>
    )}
    
    {/* Campo de mensagem: só libera se está "Em Atendimento" */}
    <div className="message-input-container">
      <input
        type="text"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        disabled={conversation.status_id !== 1}  // Bloqueia se NÃO estiver em atendimento
        placeholder={
          conversation.status_id === 1 
            ? "Digite sua mensagem..." 
            : "⚠️ Você precisa assumir a conversa para enviar mensagens"
        }
        onKeyPress={(e) => {
          if (e.key === 'Enter' && conversation.status_id === 1) {
            handleSend(conversation.id, conversation.chatwoot_conversation_id, message);
          }
        }}
      />
      <button
        onClick={() => handleSend(conversation.id, conversation.chatwoot_conversation_id, message)}
        disabled={conversation.status_id !== 1 || !message.trim()}
        className="btn-send"
      >
        📤 Enviar
      </button>
    </div>
  </div>
)}

// ============================================================================
// NOTAS IMPORTANTES
// ============================================================================
// 
// 1. STATUS_ID:
//    - 1 = Em Atendimento (humano)
//    - 2 = Precisa Atenção (IA assume)
//    - 3 = Resolvido
//    - 4 = Aguardando Cliente
//
// 2. FLUXO:
//    - Cliente envia mensagem → status_id = 2 (Precisa Atenção)
//    - Agente clica "Assumir" → status_id = 1 (Em Atendimento)
//    - Agente envia mensagens → campo liberado
//    - Agente clica "Devolver" → status_id = 2 (IA assume de volta)
//
// 3. INTEGRAÇÃO CHATWOOT (TODO):
//    - Adicionar envio via Chatwoot API em handleSend
//    - Atualizar status via Chatwoot API em handleTakeover/handleReturnToAI
//
// ============================================================================

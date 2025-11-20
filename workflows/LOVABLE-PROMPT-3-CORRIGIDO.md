# 🔧 CORREÇÃO PROMPT 3 - CHAT INTERFACE

## 📋 INSTRUÇÕES PARA O LOVABLE

Cole este prompt no Lovable para corrigir os bugs do chat:

---

## PROMPT PARA LOVABLE:

```
Preciso corrigir 3 bugs no chat (Prompt 3):

BUG 1: Botão "Assumir Conversa" não funciona ✅ PRIORIDADE
BUG 2: Falta botão "Devolver para IA"
BUG 3: Erro ao enviar mensagem

SOLUÇÕES:

1. SUBSTITUIR função handleTakeover:
```typescript
const handleTakeover = async (conversationUuid: string) => {
  try {
    const { data, error } = await supabase.rpc('takeover_conversation', {
      p_conversation_uuid: conversationUuid
    });

    if (error) throw error;
    
    toast.success('Conversa assumida com sucesso!');
    await loadConversations(); // Recarregar lista
    await loadConversation(conversationUuid); // Recarregar conversa
  } catch (err) {
    console.error('Erro ao assumir:', err);
    toast.error('Erro ao assumir conversa');
  }
};
```

2. ADICIONAR função handleReturnToAI:
```typescript
const handleReturnToAI = async (conversationUuid: string) => {
  try {
    const { data, error } = await supabase.rpc('return_to_ai', {
      p_conversation_uuid: conversationUuid
    });

    if (error) throw error;
    
    toast.success('Conversa devolvida para IA');
    await loadConversations();
    await loadConversation(conversationUuid);
  } catch (err) {
    console.error('Erro ao devolver:', err);
    toast.error('Erro ao devolver conversa');
  }
};
```

3. SUBSTITUIR função handleSend:
```typescript
const handleSend = async () => {
  if (!message.trim() || !selectedConversation) return;

  try {
    const { data, error } = await supabase.rpc('send_human_message', {
      p_conversation_uuid: selectedConversation.id,
      p_message: message,
      p_client_id: 'clinica_sorriso_001'
    });

    if (error) throw error;
    
    setMessage('');
    await loadConversation(selectedConversation.id);
  } catch (err) {
    console.error('Erro ao enviar:', err);
    toast.error('Erro ao enviar mensagem');
  }
};
```

4. RENDERIZAÇÃO CONDICIONAL DOS BOTÕES:

No JSX, dentro do componente de chat:

```typescript
{selectedConversation && (
  <div className="chat-actions">
    {/* Se status_id === 2 (Precisa Atenção) → Botão ASSUMIR */}
    {selectedConversation.status_id === 2 && (
      <Button 
        onClick={() => handleTakeover(selectedConversation.id)}
        variant="default"
      >
        🎯 Assumir Conversa
      </Button>
    )}
    
    {/* Se status_id === 1 (Em Atendimento) → Botão DEVOLVER */}
    {selectedConversation.status_id === 1 && (
      <Button 
        onClick={() => handleReturnToAI(selectedConversation.id)}
        variant="outline"
      >
        🤖 Devolver para IA
      </Button>
    )}
  </div>
)}

{/* Campo de mensagem: só libera se status_id === 1 */}
<div className="message-input">
  <Input
    value={message}
    onChange={(e) => setMessage(e.target.value)}
    disabled={!selectedConversation || selectedConversation.status_id !== 1}
    placeholder={
      selectedConversation?.status_id === 1 
        ? "Digite sua mensagem..." 
        : "⚠️ Assuma a conversa para enviar mensagens"
    }
    onKeyPress={(e) => {
      if (e.key === 'Enter' && selectedConversation?.status_id === 1) {
        handleSend();
      }
    }}
  />
  <Button
    onClick={handleSend}
    disabled={!message.trim() || selectedConversation?.status_id !== 1}
  >
    📤 Enviar
  </Button>
</div>
```

REGRAS DE STATUS:
- status_id = 1 → "Em Atendimento" (humano)
- status_id = 2 → "Precisa Atenção" (IA)
- status_id = 3 → "Resolvido"
- status_id = 4 → "Aguardando Cliente"

IMPORTANTE:
- Usar supabase.rpc() para chamar as funções
- Sempre recarregar dados após ações (loadConversations + loadConversation)
- Toast para feedback visual
- Desabilitar input quando NÃO estiver "Em Atendimento"
```

---

## 🎯 CHECKLIST DE CORREÇÃO

Após aplicar o prompt no Lovable:

- [ ] Botão "Assumir" chama `takeover_conversation`
- [ ] Status muda para "Em Atendimento" (status_id = 1)
- [ ] Campo de mensagem LIBERA
- [ ] Botão "Devolver para IA" aparece
- [ ] Botão "Devolver" chama `return_to_ai`
- [ ] Status muda para "Precisa Atenção" (status_id = 2)
- [ ] Campo de mensagem BLOQUEIA novamente
- [ ] Mensagens enviadas salvam na conversation_memory
- [ ] Mensagens aparecem no chat após enviar

---

## 📝 NOTAS TÉCNICAS

**RPCs Criadas (Migration 026):**
- `send_human_message(p_conversation_uuid, p_message, p_client_id)` → Salva mensagem + atualiza last_message_at
- `takeover_conversation(p_conversation_uuid)` → UPDATE status_id = 1
- `return_to_ai(p_conversation_uuid)` → UPDATE status_id = 2

**Todas retornam JSON:**
```json
{
  "success": true,
  "conversation_uuid": "...",
  "timestamp": "..."
}
```

**Em caso de erro:**
```json
{
  "success": false,
  "error": "mensagem de erro"
}
```

---

## 🚀 COMO USAR NO LOVABLE

1. Abra o projeto no Lovable
2. Vá em "Edit" no Prompt 3 (Chat Interface)
3. Cole o PROMPT acima
4. Clique em "Update"
5. Aguarde o Lovable gerar o código
6. Teste: Login → Dashboard → Chat → Assumir → Enviar → Devolver

---

## 🐛 SE AINDA DER ERRO

Me envie:
1. Print do console (F12 → Console)
2. Código do componente gerado (src/pages/Chat.tsx ou similar)
3. URL do projeto Lovable (se possível)

---

## ✅ STATUS ATUAL

- [x] Migration 026 executada
- [x] RPCs criadas no Supabase
- [x] Prompt de correção criado
- [ ] Aplicar prompt no Lovable
- [ ] Testar funcionalidade


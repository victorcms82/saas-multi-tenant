CREATE OR REPLACE FUNCTION save_conversation_message(
    p_client_id VARCHAR(100),
    p_conversation_id INTEGER,
    p_message_role VARCHAR(20),
    p_message_content TEXT,
    p_contact_id INTEGER DEFAULT NULL,
    p_agent_id VARCHAR(100) DEFAULT 'default',
    p_channel VARCHAR(50) DEFAULT 'whatsapp',
    p_has_attachments BOOLEAN DEFAULT FALSE,
    p_attachments JSONB DEFAULT '[]'::jsonb,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_message_id UUID;
BEGIN
    PERFORM set_config('app.current_client_id', p_client_id, true);
    
    IF p_message_role NOT IN ('user', 'assistant', 'system') THEN
        RAISE EXCEPTION 'Invalid message_role. Must be: user, assistant, or system';
    END IF;
    
    INSERT INTO conversation_memory (
        client_id,
        conversation_id,
        message_role,
        message_content,
        contact_id,
        agent_id,
        channel,
        has_attachments,
        attachments,
        metadata
    ) VALUES (
        p_client_id,
        p_conversation_id,
        p_message_role,
        p_message_content,
        p_contact_id,
        p_agent_id,
        p_channel,
        p_has_attachments,
        p_attachments,
        p_metadata
    )
    RETURNING id INTO v_message_id;
    
    RETURN v_message_id;
END;
$$;

GRANT EXECUTE ON FUNCTION get_conversation_history TO anon, authenticated;
GRANT EXECUTE ON FUNCTION save_conversation_message TO anon, authenticated;

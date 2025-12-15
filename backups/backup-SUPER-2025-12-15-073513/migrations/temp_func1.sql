CREATE OR REPLACE FUNCTION get_conversation_history(
    p_client_id VARCHAR(100),
    p_conversation_id INTEGER,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    message_role VARCHAR(20),
    message_content TEXT,
    message_timestamp TIMESTAMP WITH TIME ZONE,
    has_attachments BOOLEAN,
    contact_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM set_config('app.current_client_id', p_client_id, true);
    
    RETURN QUERY
    SELECT 
        cm.message_role,
        cm.message_content,
        cm.message_timestamp,
        cm.has_attachments,
        cm.contact_id
    FROM conversation_memory cm
    WHERE 
        cm.client_id = p_client_id
        AND cm.conversation_id = p_conversation_id
    ORDER BY cm.message_timestamp DESC
    LIMIT p_limit;
END;
$$;

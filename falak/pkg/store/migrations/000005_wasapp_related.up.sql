CREATE TABLE wasapp_chat (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    chat_id TEXT NOT NULL UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_wasapp_chat_updated_at
    BEFORE UPDATE ON wasapp_chat
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TABLE wasapp_message (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    wasapp_chat_id UUID NOT NULL REFERENCES wasapp_chat(id) ON DELETE CASCADE,

    message_id TEXT NOT NULL UNIQUE,
    sender_name TEXT NOT NULL,
    sender_number TEXT NOT NULL,
    is_sender_me BOOLEAN NOT NULL,
    body TEXT NOT NULL,
    timestamp BIGINT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_wasapp_message_updated_at
    BEFORE UPDATE ON wasapp_message
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
CREATE TABLE caldav_account (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    email VARCHAR(320) NOT NULL UNIQUE,
    username VARCHAR(320) NOT NULL UNIQUE,
    password TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_caldav_account_updated_at
    BEFORE UPDATE ON caldav_account
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TABLE customer (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR (100) NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_customer_updated_at
BEFORE UPDATE ON customer
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

CREATE TABLE auth_google (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID UNIQUE REFERENCES customer(id) ON DELETE CASCADE NOT NULL,
    sub TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_auth_google_updated_at
BEFORE UPDATE ON auth_google
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

CREATE TABLE magic_link (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES customer(id) ON DELETE CASCADE NOT NULL,
    token_hash CHAR(44) UNIQUE NOT NULL, -- 44 is used here as fixed length since hash will be sha-256 and when converted to base64, it returns 44 characters with padding :D
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_magic_link_updated_at
BEFORE UPDATE ON magic_link
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
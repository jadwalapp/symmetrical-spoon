CREATE TABLE device (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES customer(id) ON DELETE CASCADE NOT NULL,
    apns_token TEXT NOT NULL UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_device_updated_at
BEFORE UPDATE ON device
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

CREATE INDEX idx_device_customer_id 
ON device (customer_id);
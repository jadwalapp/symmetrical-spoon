DROP TRIGGER IF EXISTS update_magic_link_updated_at ON magic_link;
DROP TABLE IF EXISTS magic_link;

DROP TRIGGER IF EXISTS update_auth_google_updated_at ON auth_google;
DROP TABLE IF EXISTS auth_google;

DROP TRIGGER IF EXISTS update_auth_password_updated_at ON auth_password;
DROP TABLE IF EXISTS auth_password;

DROP TRIGGER IF EXISTS update_customer_updated_at ON customer;
DROP TABLE IF EXISTS customer;

DROP FUNCTION IF EXISTS update_modified_column();

DROP EXTENSION IF EXISTS "uuid-ossp";
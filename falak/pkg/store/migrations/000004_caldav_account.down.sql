DROP EXTENSION IF EXISTS pgcrypto;

DROP TRIGGER IF EXISTS update_caldav_account_updated_at ON caldav_account;
DROP TABLE IF EXISTS caldav_account;
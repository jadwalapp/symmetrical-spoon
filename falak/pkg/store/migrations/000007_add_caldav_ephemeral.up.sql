
CREATE TYPE magic_token_type AS ENUM (
  'auth',
  'caldav'
);

ALTER TABLE magic_link RENAME TO magic_token;
ALTER TABLE magic_token ADD COLUMN token_type magic_token_type;
UPDATE magic_token SET token_type = 'auth';
ALTER TABLE magic_token ALTER COLUMN token_type SET NOT NULL;

-- name: CreateCalDAVAccount :one
INSERT INTO caldav_account (customer_id, email, username, password)
VALUES ($1, $2, $3, pgp_sym_encrypt(@password::text, @encryption_key::text))
RETURNING *;

-- name: GetCalDAVAccountByCustomerId :one
SELECT *, pgp_sym_decrypt(ca.password::bytea, @encryption_key::text) AS decrypted_password
FROM caldav_account ca
WHERE ca.customer_id = $1;
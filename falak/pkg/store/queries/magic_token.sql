-- name: CreateMagicToken :one
INSERT INTO magic_token (customer_id, token_hash, token_type, expires_at)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetUnusedMagicTokenByTokenHash :one
SELECT * FROM magic_token WHERE token_hash = $1 AND token_type = $2 AND used_at IS NULL;

-- name: UpdateMagicTokenUsedAtByTokenHash :exec
UPDATE magic_token
SET used_at = $2
WHERE token_hash = $1;
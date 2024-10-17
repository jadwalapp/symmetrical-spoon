-- name: CreateMagicLink :one
INSERT INTO magic_link (customer_id, token_hash, expires_at)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetUnusedMagicLinkByTokenHash :one
SELECT * FROM magic_link WHERE token_hash = $1 AND used_at IS NULL;

-- name: UpdateMagicLinkUsedAtByTokenHash :exec
UPDATE magic_link
SET used_at = $2
WHERE token_hash = $1;
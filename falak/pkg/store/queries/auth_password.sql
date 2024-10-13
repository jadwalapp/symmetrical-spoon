-- name: CreateAuthPassword :one
INSERT INTO auth_password (customer_id, password)
VALUES ($1, $2)
RETURNING *;

-- name: GetAuthPasswordByUserID :one
SELECT * FROM auth_password WHERE customer_id = $1;

-- name: UpdateAuthPasswordByUSerID :exec
UPDATE auth_password SET password = $2 WHERE customer_id = $1;

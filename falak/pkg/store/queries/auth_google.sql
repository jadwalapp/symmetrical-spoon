-- name: CreateAuthGoogle :one
INSERT INTO auth_google (customer_id, sub)
VALUES ($1, $2)
RETURNING *;

-- name: GetAuthGoogleByCustomerId :one
SELECT * FROM auth_google WHERE customer_id = $1;

-- name: GetAuthGoogleBySub :one
SELECT * FROM auth_google WHERE sub = $1;
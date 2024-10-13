-- name: CreateCustomer :one
INSERT INTO customer (name, email)
VALUES ($1, LOWER($2))
RETURNING *;

-- name: GetCustomerById :one
SELECT * FROM customer WHERE id = $1;

-- name: GetCustomerByEmail :one
SELECT * FROM customer WHERE LOWER(email) = LOWER($1);

-- name: DeleteCustomerById :exec
DELETE FROM customer WHERE id = $1;
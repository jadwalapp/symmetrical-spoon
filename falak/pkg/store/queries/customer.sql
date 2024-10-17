-- name: CreateCustomerIfNotExists :one
WITH new_customer AS (
    INSERT INTO customer (name, email)
    SELECT $1, LOWER(sqlc.arg(email))
    WHERE NOT EXISTS (
        SELECT 1 FROM customer WHERE LOWER(email) = LOWER(sqlc.arg(email))
    )
    RETURNING *
)
SELECT * FROM new_customer
UNION ALL
SELECT * FROM customer WHERE LOWER(email) = LOWER(sqlc.arg(email))
LIMIT 1;

-- name: GetCustomerById :one
SELECT * FROM customer WHERE id = $1;

-- name: GetCustomerByEmail :one
SELECT * FROM customer WHERE LOWER(email) = LOWER(sqlc.arg(email));

-- name: DeleteCustomerById :exec
DELETE FROM customer WHERE id = $1;
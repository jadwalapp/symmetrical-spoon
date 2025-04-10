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


-- name: IsCustomerFirstLogin :one
SELECT 
  (
    -- not ((has magic link entry where used_at is not null) -> has account)
    NOT EXISTS (
      SELECT 1 
      FROM magic_token mt
      WHERE mt.customer_id = $1
        AND mt.used_at IS NOT NULL
    )
    AND 
    -- not ((has google entry) -> has account)
    NOT EXISTS (
      SELECT 1 
      FROM auth_google ag
      WHERE ag.customer_id = $1
    )
  ) AS is_customer_first_login;

-- name: ListCustomerWithoutCaldavAccount :many
SELECT c.*
FROM customer c
LEFT OUTER JOIN caldav_account ca ON c.id = ca.customer_id
WHERE ca.customer_id IS NULL;
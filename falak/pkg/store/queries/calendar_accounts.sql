-- name: GetCalendarAccountsByCustomerId :many
SELECT *
FROM calendar_accounts ca
WHERE ca.customer_id = $1;

-- name: CreateCalendarAccount :one
INSERT INTO calendar_accounts
(customer_id, provider)
VALUES ($1, $2)
RETURNING *;

-- name: DoesCustomerOwnCalendarAccount :one
SELECT (
    EXISTS(
        SELECT 1 FROM calendar_accounts ca
        WHERE ca.customer_id = $1 AND ca.id = $2
    )
) AS does_customer_own_calendar_account;
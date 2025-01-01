-- name: CreateCalendarUnderCalendarAccountById :one
INSERT INTO vcalendar
(uid, account_id, prodid, display_name, description, color)
VALUES (CONCAT(uuid_generate_v4(), '@cal.jadwal.app'), $1, $2, $3, $4, $5)
RETURNING *;

-- name: GetCalendarsByCustomerId :many
SELECT *
FROM calendar_accounts ca
JOIN vcalendar v ON ca.id = v.account_id
WHERE ca.customer_id = $1;
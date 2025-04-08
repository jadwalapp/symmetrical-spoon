-- name: CreateDeviceIfNotExists :exec
INSERT INTO device (customer_id, apns_token)
VALUES ($1, $2)
ON CONFLICT (apns_token) DO NOTHING;

-- name: ListDeviceByCustomerId :many
SELECT *
FROM device
WHERE customer_id = $1;

-- name: DeleteDevices :exec
DELETE FROM device
WHERE id IN ($1::string[]);
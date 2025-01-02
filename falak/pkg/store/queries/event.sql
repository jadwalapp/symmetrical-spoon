-- name: CreateEventUnderCalendarByUid :one
INSERT INTO vevent
(uid, calendar_uid, dtstamp, dtstart, dtend, summary, description, location, status, classification, transp)
VALUES (CONCAT(uuid_generate_v4(), '@event.jadwal.app'), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING *;

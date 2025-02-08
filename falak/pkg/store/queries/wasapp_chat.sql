-- name: AddMessageToChatReturningMessages :many
WITH new_chat AS (
  INSERT INTO wasapp_chat (customer_id, chat_id)
  VALUES ($1, $2)
  ON CONFLICT (chat_id) DO NOTHING
  RETURNING *
),
inserted_message AS (
  INSERT INTO wasapp_message (
    wasapp_chat_id,
    message_id,
    sender_name,
    sender_number,
    is_sender_me,
    body,
    timestamp
  )
  SELECT 
    COALESCE((SELECT id FROM new_chat), (SELECT id FROM wasapp_chat WHERE chat_id = $2)),
    $3,
    $4,
    $5,
    $6,
    $7,
    $8
  ON CONFLICT (message_id) DO NOTHING
  RETURNING *
)
SELECT 
  m.*,
  c.chat_id,
  c.customer_id
FROM wasapp_message m
JOIN wasapp_chat c ON c.id = m.wasapp_chat_id
WHERE c.chat_id = $2;

-- name: DeleteChat :exec
DELETE FROM wasapp_chat WHERE chat_id = $1;
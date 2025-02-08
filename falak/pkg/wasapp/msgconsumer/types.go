package wasappmsgconsumer

import (
	"context"

	"github.com/google/uuid"
)

type WasappMessage struct {
	CustomerID    uuid.UUID      `json:"customer_id"`
	ID            string         `json:"id"`
	ChatID        string         `json:"chat_id"`
	SenderName    string         `json:"sender_name"`
	SenderNumber  string         `json:"sender_number"`
	IsSenderMe    bool           `json:"is_sender_me"`
	Body          string         `json:"body"`
	QuotedMessage *WasappMessage `json:"quoted_message"`
	Timestamp     int64          `json:"timestamp"`
}

type Consumer interface {
	Start(context.Context) error
	Stop(context.Context) error
}

package wasappcalendar

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// CalendarEventData represents a WhatsApp calendar event
// This is used in both producer and consumer to ensure consistency
type CalendarEventData struct {
	CustomerID  uuid.UUID `json:"customer_id"`
	ChatID      string    `json:"chat_id"`
	Summary     string    `json:"summary"`
	Description string    `json:"description"`
	StartTime   time.Time `json:"start_time"`
	EndTime     time.Time `json:"end_time"`
}

// Consumer defines the interface for consuming calendar events
type Consumer interface {
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
}

type Producer interface {
	PublishEvent(ctx context.Context, event CalendarEventData) error
}

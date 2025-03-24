package calendarsvc

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// AddEventRequest contains data needed to add an event to a calendar
type AddEventRequest struct {
	CustomerID  uuid.UUID
	Summary     string
	Description string
	StartTime   time.Time
	EndTime     time.Time
	UID         string // Optional unique identifier
}

// InitCalendarRequest contains data needed to initialize a calendar
type InitCalendarRequest struct {
	CustomerID  uuid.UUID
	Username    string
	Password    string
	PathSuffix  string // Path suffix for the calendar (e.g. "my-calendar/")
	DisplayName string // Display name for the calendar
	Color       string // Color for the calendar in hex format (e.g. "#2ECC71")
}

// Svc defines the calendar service interface
type Svc interface {
	// AddEvent adds an event to a customer's calendar
	AddEvent(ctx context.Context, r *AddEventRequest) error

	// InitCalendar initializes a calendar for a customer
	InitCalendar(ctx context.Context, r *InitCalendarRequest) error
}

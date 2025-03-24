package caldavclient

import (
	"context"
	"time"

	"github.com/emersion/go-ical"
)

// Client interface defines operations for a CalDAV client
type Client interface {
	// Initialize a calendar with given properties, creating it if it doesn't exist
	InitCalendar(ctx context.Context, props CalendarProperties) error

	// AddEvent adds a calendar event
	AddEvent(ctx context.Context, event EventData) error

	// GetCalendarPath returns the current calendar path
	GetCalendarPath() string

	// FindEvents searches for events in the calendar
	// Returns a slice of events that match the criteria
	FindEvents(ctx context.Context, query EventQuery) ([]CalendarEvent, error)

	// UpdateEvent updates an existing event identified by UID
	// Returns error if event not found
	UpdateEvent(ctx context.Context, uid string, updatedEvent EventData) error
}

// Config stores the configuration for connecting to a CalDAV server
type Config struct {
	BaseURL  string
	Username string
	Password string
}

// CalendarProperties defines properties for a calendar
type CalendarProperties struct {
	// Path suffix for the calendar (e.g. "my-calendar/")
	PathSuffix string

	// Display name for the calendar
	DisplayName string

	// Color for the calendar in hex format (e.g. "#2ECC71")
	Color string
}

// EventData represents data needed to create a calendar event
type EventData struct {
	// Summary/title of the event
	Summary string

	// Detailed description of the event
	Description string

	// When the event starts
	StartTime time.Time

	// When the event ends
	EndTime time.Time

	// Optional unique identifier (will be auto-generated if empty)
	// You can use this to store chat_id like: "chat-123@jadwal.app"
	UID string
}

// EventQuery represents search criteria for finding events
type EventQuery struct {
	// Filter by UID pattern (supports partial match)
	UIDPattern string

	// Filter by time range
	TimeRangeStart time.Time
	TimeRangeEnd   time.Time
}

// CalendarEvent represents a calendar event with all its properties
type CalendarEvent struct {
	// Event UID
	UID string

	// Event summary/title
	Summary string

	// Event description
	Description string

	// Event start time
	StartTime time.Time

	// Event end time
	EndTime time.Time

	// Original iCalendar component
	Component *ical.Component

	// CalDAV object path (useful for updates)
	Path string
}

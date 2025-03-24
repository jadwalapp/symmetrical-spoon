package caldavclient

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	digestauth "github.com/Snawoot/go-http-digest-auth-client"
	"github.com/emersion/go-ical"
	"github.com/emersion/go-webdav/caldav"
)

// caldavClient implements the Client interface for CalDAV calendars
type caldavClient struct {
	caldavClient *caldav.Client
	calendarPath string
	baseURL      string
	httpClient   *http.Client
}

// NewCalDAVClient creates a new CalDAV client
func NewCalDAVClient(config Config) (Client, error) {
	httpClient := &http.Client{
		Transport: digestauth.NewDigestTransport(config.Username, config.Password, http.DefaultTransport),
	}

	client, err := caldav.NewClient(httpClient, config.BaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to create CalDAV client: %w", err)
	}

	return &caldavClient{
		caldavClient: client,
		baseURL:      config.BaseURL,
		httpClient:   httpClient,
	}, nil
}

// Kept for backward compatibility
func NewWhatsAppClient(config Config) (Client, error) {
	return NewCalDAVClient(config)
}

// InitCalendar initializes a calendar with the given properties, creating it if it doesn't exist
func (c *caldavClient) InitCalendar(ctx context.Context, props CalendarProperties) error {
	// Default values if not provided
	pathSuffix := props.PathSuffix
	if pathSuffix == "" {
		pathSuffix = "calendar/"
	}

	displayName := props.DisplayName
	if displayName == "" {
		displayName = "Calendar"
	}

	color := props.Color
	if color == "" {
		color = "#2ECC71" // Default green color
	}

	// Test connection and get principal
	principal, err := c.caldavClient.FindCurrentUserPrincipal(ctx)
	if err != nil {
		return fmt.Errorf("auth failed: %w", err)
	}

	// Find calendar home
	calHomeSet, err := c.caldavClient.FindCalendarHomeSet(ctx, principal)
	if err != nil {
		return fmt.Errorf("finding calendar home set failed: %w", err)
	}

	// Find all calendars
	cals, err := c.caldavClient.FindCalendars(ctx, calHomeSet)
	if err != nil {
		return fmt.Errorf("finding calendars failed: %w", err)
	}

	// Look for existing calendar with the same path
	for _, cal := range cals {
		if strings.HasSuffix(cal.Path, "/"+pathSuffix) {
			c.calendarPath = cal.Path
			return nil
		}
	}

	// If we get here, calendar doesn't exist, so create it
	path := calHomeSet + pathSuffix

	// Create MKCALENDAR request
	req, err := http.NewRequestWithContext(ctx, "MKCALENDAR", path, nil)
	if err != nil {
		return fmt.Errorf("failed to create MKCALENDAR request: %w", err)
	}

	// Set proper URL
	reqURL, _ := url.Parse(c.baseURL)
	pathURL, _ := url.Parse(path)
	req.URL = reqURL.ResolveReference(pathURL)

	// Send request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to create calendar: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return fmt.Errorf("failed to create calendar, status: %s", resp.Status)
	}

	// Set calendar display name and color
	propPatchBody := fmt.Sprintf(`<?xml version="1.0" encoding="utf-8" ?>
		<D:propertyupdate xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
			<D:set>
				<D:prop>
					<D:displayname>%s</D:displayname>
					<C:calendar-color>%s</C:calendar-color>
				</D:prop>
			</D:set>
		</D:propertyupdate>`, displayName, color)

	propPatchReq, _ := http.NewRequestWithContext(ctx, "PROPPATCH", req.URL.String(), strings.NewReader(propPatchBody))
	propPatchReq.Header.Add("Content-Type", "application/xml")
	resp, _ = c.httpClient.Do(propPatchReq)
	resp.Body.Close()

	c.calendarPath = path
	return nil
}

// AddEvent adds an event to the calendar
func (c *caldavClient) AddEvent(ctx context.Context, event EventData) error {
	if c.calendarPath == "" {
		return fmt.Errorf("calendar not initialized, call InitCalendar() first")
	}

	icalEvent := ical.NewEvent()
	icalEvent.Props.SetText(ical.PropSummary, event.Summary)
	icalEvent.Props.SetText(ical.PropDescription, event.Description)
	icalEvent.Props.SetDateTime(ical.PropDateTimeStart, event.StartTime.UTC())
	icalEvent.Props.SetDateTime(ical.PropDateTimeEnd, event.EndTime.UTC())
	icalEvent.Props.SetDateTime(ical.PropDateTimeStamp, time.Now().UTC())

	uid := event.UID
	if uid == "" {
		uid = fmt.Sprintf("event-%s@jadwal.app", time.Now().UTC().Format("20060102T150405Z"))
	}
	icalEvent.Props.SetText(ical.PropUID, uid)

	cal := ical.NewCalendar()
	cal.Props.SetText(ical.PropProductID, "-//Jadwal App//Calendar//EN")
	cal.Props.SetText(ical.PropVersion, "2.0")
	cal.Children = append(cal.Children, icalEvent.Component)

	eventPath := c.calendarPath + time.Now().UTC().Format("20060102T150405Z") + ".ics"
	_, err := c.caldavClient.PutCalendarObject(ctx, eventPath, cal)
	if err != nil {
		return fmt.Errorf("failed to create event: %w", err)
	}

	return nil
}

// GetCalendarPath returns the current calendar path
func (c *caldavClient) GetCalendarPath() string {
	return c.calendarPath
}

// Helper function to maintain backward compatibility
func (c *caldavClient) Init(ctx context.Context) error {
	// For backward compatibility, create a WhatsApp calendar
	props := CalendarProperties{
		PathSuffix:  "whatsapp-by-jadwal/",
		DisplayName: "📱 WhatsApp Events",
		Color:       "#2ECC71",
	}
	return c.InitCalendar(ctx, props)
}

// FindEvents searches for events in the calendar
func (c *caldavClient) FindEvents(ctx context.Context, query EventQuery) ([]CalendarEvent, error) {
	if c.calendarPath == "" {
		return nil, fmt.Errorf("calendar not initialized, call InitCalendar() first")
	}

	// Create caldav query
	calQuery := &caldav.CalendarQuery{
		CompFilter: caldav.CompFilter{
			Name: "VCALENDAR",
			Comps: []caldav.CompFilter{{
				Name: "VEVENT",
			}},
		},
	}

	// Add time range if specified
	if !query.TimeRangeStart.IsZero() || !query.TimeRangeEnd.IsZero() {
		compFilter := &calQuery.CompFilter.Comps[0]
		if !query.TimeRangeStart.IsZero() {
			compFilter.Start = query.TimeRangeStart.UTC()
		}
		if !query.TimeRangeEnd.IsZero() {
			compFilter.End = query.TimeRangeEnd.UTC()
		}
	}

	// Retrieve all calendar objects
	calendarObjects, err := c.caldavClient.QueryCalendar(ctx, c.calendarPath, calQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to query calendar: %w", err)
	}

	// Parse and filter the calendar objects based on UID pattern
	var events []CalendarEvent
	for _, obj := range calendarObjects {
		// obj.Data is already an *ical.Calendar object
		calendar := obj.Data

		// Find VEVENT components
		for _, comp := range calendar.Children {
			if comp.Name != "VEVENT" {
				continue
			}

			// Extract UID property
			uidProp := comp.Props.Get(ical.PropUID)
			if uidProp == nil {
				continue // Skip events without UID
			}
			uid := uidProp.Value

			// Filter by UID pattern if provided
			if query.UIDPattern != "" && !strings.Contains(uid, query.UIDPattern) {
				continue
			}

			// Extract other properties
			summary := ""
			if prop := comp.Props.Get(ical.PropSummary); prop != nil {
				summary = prop.Value
			}

			description := ""
			if prop := comp.Props.Get(ical.PropDescription); prop != nil {
				description = prop.Value
			}

			var startTime, endTime time.Time
			if dtstart := comp.Props.Get(ical.PropDateTimeStart); dtstart != nil {
				startTime, _ = dtstart.DateTime(time.UTC)
			}
			if dtend := comp.Props.Get(ical.PropDateTimeEnd); dtend != nil {
				endTime, _ = dtend.DateTime(time.UTC)
			}

			// Create event object
			events = append(events, CalendarEvent{
				UID:         uid,
				Summary:     summary,
				Description: description,
				StartTime:   startTime,
				EndTime:     endTime,
				Component:   comp,
				Path:        obj.Path, // Store the path for later use in updates
			})
		}
	}

	return events, nil
}

// UpdateEvent updates an existing event identified by UID
func (c *caldavClient) UpdateEvent(ctx context.Context, uid string, updatedEvent EventData) error {
	if c.calendarPath == "" {
		return fmt.Errorf("calendar not initialized, call InitCalendar() first")
	}

	// First, find the event by UID
	events, err := c.FindEvents(ctx, EventQuery{
		UIDPattern: uid,
	})
	if err != nil {
		return fmt.Errorf("failed to find event: %w", err)
	}

	if len(events) == 0 {
		return fmt.Errorf("event with UID %s not found", uid)
	}

	// Create a new event with the updated properties but keep the same UID
	event := ical.NewEvent()
	event.Props.SetText(ical.PropSummary, updatedEvent.Summary)
	event.Props.SetText(ical.PropDescription, updatedEvent.Description)
	event.Props.SetDateTime(ical.PropDateTimeStart, updatedEvent.StartTime.UTC())
	event.Props.SetDateTime(ical.PropDateTimeEnd, updatedEvent.EndTime.UTC())
	event.Props.SetDateTime(ical.PropDateTimeStamp, time.Now().UTC())

	// Make sure we keep the original UID
	event.Props.SetText(ical.PropUID, uid)

	cal := ical.NewCalendar()
	cal.Props.SetText(ical.PropProductID, "-//Jadwal App//Calendar//EN")
	cal.Props.SetText(ical.PropVersion, "2.0")
	cal.Children = append(cal.Children, event.Component)

	// Get the path of the original event from the found event
	// We need to update it at the same URL
	eventPath := ""
	for _, e := range events {
		if e.UID == uid {
			eventPath = e.Path
			break
		}
	}

	if eventPath == "" {
		// If we can't find the exact path, create a new one
		eventPath = c.calendarPath + time.Now().UTC().Format("20060102T150405Z") + ".ics"
	}

	// Update or create the event
	_, err = c.caldavClient.PutCalendarObject(ctx, eventPath, cal)
	if err != nil {
		return fmt.Errorf("failed to update event: %w", err)
	}

	return nil
}

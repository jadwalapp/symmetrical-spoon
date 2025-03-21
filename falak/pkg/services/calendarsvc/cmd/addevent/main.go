package main

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	digestauth "github.com/Snawoot/go-http-digest-auth-client"
	"github.com/emersion/go-ical"
	"github.com/emersion/go-webdav/caldav"
)

type WhatsAppCalendar struct {
	client       *caldav.Client
	calendarPath string
	baseURL      string
	httpClient   *http.Client
}

func NewWhatsAppCalendar(baseURL, username, password string) (*WhatsAppCalendar, error) {
	httpClient := &http.Client{
		Transport: digestauth.NewDigestTransport(username, password, http.DefaultTransport),
	}

	client, err := caldav.NewClient(httpClient, baseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to create client: %w", err)
	}

	return &WhatsAppCalendar{
		client:     client,
		baseURL:    baseURL,
		httpClient: httpClient,
	}, nil
}

func (w *WhatsAppCalendar) Init(ctx context.Context) error {
	// Test connection and get principal
	principal, err := w.client.FindCurrentUserPrincipal(ctx)
	if err != nil {
		return fmt.Errorf("auth failed: %w", err)
	}

	// Find calendar home
	calHomeSet, err := w.client.FindCalendarHomeSet(ctx, principal)
	if err != nil {
		return fmt.Errorf("finding calendar home set failed: %w", err)
	}

	// Find all calendars
	cals, err := w.client.FindCalendars(ctx, calHomeSet)
	if err != nil {
		return fmt.Errorf("finding calendars failed: %w", err)
	}

	// Look for existing WhatsApp calendar
	for _, cal := range cals {
		if strings.HasSuffix(cal.Path, "/whatsapp-by-jadwal/") {
			w.calendarPath = cal.Path
			return nil
		}
	}

	// If we get here, no WhatsApp calendar exists, so create it
	path := calHomeSet + "whatsapp-by-jadwal/"

	// Create MKCALENDAR request
	req, err := http.NewRequestWithContext(ctx, "MKCALENDAR", path, nil)
	if err != nil {
		return fmt.Errorf("failed to create MKCALENDAR request: %w", err)
	}

	// Set proper URL
	reqURL, _ := url.Parse(w.baseURL)
	pathURL, _ := url.Parse(path)
	req.URL = reqURL.ResolveReference(pathURL)

	// Send request
	resp, err := w.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to create calendar: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return fmt.Errorf("failed to create calendar, status: %s", resp.Status)
	}

	// Set calendar display name and color
	propPatchReq, _ := http.NewRequestWithContext(ctx, "PROPPATCH", req.URL.String(), strings.NewReader(`<?xml version="1.0" encoding="utf-8" ?>
		<D:propertyupdate xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
			<D:set>
				<D:prop>
					<D:displayname>📱 WhatsApp Events</D:displayname>
					<C:calendar-color>#2ECC71</C:calendar-color>
				</D:prop>
			</D:set>
		</D:propertyupdate>`))
	propPatchReq.Header.Add("Content-Type", "application/xml")
	resp, _ = w.httpClient.Do(propPatchReq)
	resp.Body.Close()

	w.calendarPath = path
	return nil
}

func (w *WhatsAppCalendar) AddEvent(ctx context.Context, summary, description string, startTime, endTime time.Time) error {
	if w.calendarPath == "" {
		return fmt.Errorf("calendar not initialized, call Init() first")
	}

	event := ical.NewEvent()
	event.Props.SetText(ical.PropSummary, summary)
	event.Props.SetText(ical.PropDescription, description)
	event.Props.SetDateTime(ical.PropDateTimeStart, startTime.UTC())
	event.Props.SetDateTime(ical.PropDateTimeEnd, endTime.UTC())
	event.Props.SetDateTime(ical.PropDateTimeStamp, time.Now().UTC())
	event.Props.SetText(ical.PropUID, fmt.Sprintf("whatsapp-%s@jadwal.app",
		time.Now().UTC().Format("20060102T150405Z")))

	cal := ical.NewCalendar()
	cal.Props.SetText(ical.PropProductID, "-//Jadwal App//WhatsApp Calendar//EN")
	cal.Props.SetText(ical.PropVersion, "2.0")
	cal.Children = append(cal.Children, event.Component)

	eventPath := w.calendarPath + time.Now().UTC().Format("20060102T150405Z") + ".ics"
	_, err := w.client.PutCalendarObject(ctx, eventPath, cal)
	if err != nil {
		return fmt.Errorf("failed to create event: %w", err)
	}

	return nil
}

func main() {
	username := os.Getenv("USER_NAME")
	password := os.Getenv("PASSWORD")

	if username == "" || password == "" {
		fmt.Println("ERROR: USER_NAME and/or PASSWORD environment variables are not set")
		return
	}

	calendar, err := NewWhatsAppCalendar("https://baikal.jadwal.app/dav.php", username, password)
	if err != nil {
		fmt.Printf("Failed to create calendar client: %v\n", err)
		return
	}

	ctx := context.Background()
	err = calendar.Init(ctx)
	if err != nil {
		fmt.Printf("Failed to initialize calendar: %v\n", err)
		return
	}

	// Example usage
	err = calendar.AddEvent(ctx,
		"Test Event",
		"This is a test event created via WhatsApp Calendar",
		time.Now(),
		time.Now().Add(1*time.Hour),
	)
	if err != nil {
		fmt.Printf("Failed to add event: %v\n", err)
		return
	}

	fmt.Println("Event added successfully!")
}

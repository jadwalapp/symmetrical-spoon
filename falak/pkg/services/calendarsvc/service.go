package calendarsvc

import (
	"context"
	"fmt"
	"sync"

	"github.com/google/uuid"
	caldavclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/caldav/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
)

type svc struct {
	mu            sync.RWMutex
	caldavClients map[uuid.UUID]caldavclient.Client
	store         store.Queries
	calDavBaseUrl string
}

func (s *svc) InitCalendar(ctx context.Context, r *InitCalendarRequest) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	calClient, err := s.createCalendarClient(s.calDavBaseUrl, r.Username, r.Password)
	if err != nil {
		return err
	}

	// Create calendar with provided properties
	calProps := caldavclient.CalendarProperties{
		PathSuffix:  r.PathSuffix,
		DisplayName: r.DisplayName,
		Color:       r.Color,
	}

	if err := calClient.InitCalendar(ctx, calProps); err != nil {
		return err
	}

	s.caldavClients[r.CustomerID] = calClient
	return nil
}

func (s *svc) AddEvent(ctx context.Context, r *AddEventRequest) error {
	s.mu.RLock()
	calendar, exists := s.caldavClients[r.CustomerID]
	s.mu.RUnlock()

	if !exists {
		return fmt.Errorf("calendar not initialized for customer %s", r.CustomerID)
	}

	eventData := caldavclient.EventData{
		Summary:     r.Summary,
		Description: r.Description,
		StartTime:   r.StartTime,
		EndTime:     r.EndTime,
		UID:         r.UID,
	}

	return calendar.AddEvent(ctx, eventData)
}

func (s *svc) createCalendarClient(baseUrl, username, password string) (caldavclient.Client, error) {
	config := caldavclient.Config{
		BaseURL:  fmt.Sprintf("%s/dav.php", baseUrl),
		Username: username,
		Password: password,
	}

	return caldavclient.NewCalDAVClient(config)
}

func NewSvc(calDavBaseUrl string, store store.Queries) Svc {
	return &svc{
		caldavClients: make(map[uuid.UUID]caldavclient.Client),
		store:         store,
		calDavBaseUrl: calDavBaseUrl,
	}
}

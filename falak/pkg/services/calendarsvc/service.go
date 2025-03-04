package calendarsvc

import (
	"context"
	"net/http"

	"github.com/emersion/go-webdav/caldav"
	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/rs/zerolog/log"
)

type svc struct {
	caldavClients map[uuid.UUID]*caldav.Client
	store         store.Queries
}

func (s *svc) AddEvent(ctx context.Context, r *AddEventRequest) error {
	panic("unimplemented")
}

func (s *svc) getOrCreateClientForCustomer(ctx context.Context, customerID uuid.UUID) (*caldav.Client, error) {
	if caldavCli, exists := s.caldavClients[customerID]; exists {
		return caldavCli, nil
	}

	caldavCli, err := caldav.NewClient(&http.Client{}, "https://baikal.jadwal.app/dav.php")
	if err != nil {
		log.Ctx(ctx).Err(err).Str("customer_id", customerID.String()).Msg("failed to create caldav client")
		return nil, err
	}

	return caldavCli, nil
}

func NewSvc(store store.Queries) Svc {
	return &svc{
		caldavClients: make(map[uuid.UUID]*caldav.Client),
		store:         store,
	}
}

package calendarsvc

import "context"

type AddEventRequest struct {
}

type Svc interface {
	AddEvent(ctx context.Context, r *AddEventRequest) error
}

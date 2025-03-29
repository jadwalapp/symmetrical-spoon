package notificationsvc

import (
	"context"

	"github.com/google/uuid"
)

type SendNotificationToCustomerDevicesRequest struct {
	CustomerId uuid.UUID
	Title      string
	Body       string
}

type Svc interface {
	SendNotificationToCustomerDevices(ctx context.Context, r *SendNotificationToCustomerDevicesRequest) error
}

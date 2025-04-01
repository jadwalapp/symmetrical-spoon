package notificationsvc

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type SendNotificationToCustomerDevicesRequest struct {
	CustomerId     uuid.UUID
	AlertTitle     string
	AlertBody      string
	EventUID       *string
	EventTitle     *string
	EventStartDate *time.Time
	EventEndDate   *time.Time
	CalendarName   *string
}

type Svc interface {
	SendNotificationToCustomerDevices(ctx context.Context, r *SendNotificationToCustomerDevicesRequest) error
}

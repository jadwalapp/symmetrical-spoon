package calendarsvc

import "context"

type CalendarSvc interface {
	CreateCalendarAccount(ctx context.Context, customerID string)
}

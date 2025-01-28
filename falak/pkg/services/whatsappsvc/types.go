package whatsappsvc

import "context"

type whatsappsvc interface {
	CreatewhatsappAccount(ctx context.Context, customerID string)
}

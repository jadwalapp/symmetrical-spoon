package apns

import (
	"github.com/sideshow/apns2"
	apns2payload "github.com/sideshow/apns2/payload"
)

type APNS interface {
	Send(token string, payload *apns2payload.Payload, pushType apns2.EPushType) (*apns2.Response, error)
}

package apns

import (
	"github.com/sideshow/apns2"
	apns2payload "github.com/sideshow/apns2/payload"
)

type APNS interface {
	Send(token string, payload *apns2payload.Payload) (*apns2.Response, error)
}

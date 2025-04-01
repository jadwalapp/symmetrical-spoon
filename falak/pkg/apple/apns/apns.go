package apns

import (
	"github.com/sideshow/apns2"
	apns2payload "github.com/sideshow/apns2/payload"
)

type apns struct {
	apns2Cli *apns2.Client
}

func (a *apns) Send(token string, payload *apns2payload.Payload, pushType apns2.EPushType) (*apns2.Response, error) {
	n := &apns2.Notification{}
	n.DeviceToken = token
	n.Payload = payload
	n.Topic = "app.jadwal.mishkat"
	n.PushType = pushType

	resp, err := a.apns2Cli.Push(n)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func NewApns(apns2Cli apns2.Client) APNS {
	return &apns{
		apns2Cli: &apns2Cli,
	}
}

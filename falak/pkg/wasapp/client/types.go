package wasappclient

import "context"

type InitializeRequest struct {
	CustomerId  string `json:"customerId"`
	PhoneNumber string `json:"phoneNumber"`
}
type InitializeResponse struct {
	PairingCode string `json:"pairingCode"`
}

type GetStatusRequest struct {
	CustomerId string `json:"customerId"`
}
type GetStatusClientDetails struct {
	Status          string `json:"status"`
	PhoneNumber     string `json:"phoneNumber"`
	Name            string `json:"name"`
	PairingCode     string `json:"pairingCode"`
	IsReady         string `json:"isReady"`
	IsAuthenticated string `json:"isAuthenticated"`
}
type GetStatusResponse struct {
	ClientDetails GetStatusClientDetails `json:"client"`
	Timestamp     string                 `json:"timestamp"`
}

type DisconnectRequest struct {
	CustomerId string `json:"customerId"`
}
type DisconnectResponse struct{}

type Client interface {
	Initialize(ctx context.Context, r *InitializeRequest) (*InitializeResponse, error)
	GetStatus(ctx context.Context, r *GetStatusRequest) (*GetStatusResponse, error)
	Disconnect(ctx context.Context, r *DisconnectRequest) (*DisconnectResponse, error)
}

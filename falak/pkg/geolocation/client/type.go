package client

import "context"

type GeoLocationClinet interface {
	GetGeoLocationInfo(context.Context, *GetGeoLocationInfoRequest) (*GetGeoLocationInfoResponse, error)
}

type GetGeoLocationInfoRequest struct {
	Ip string
}

type GetGeoLocationInfoResponse struct {
	City    string `json:"city"`
	Country string `json:"country"`
}

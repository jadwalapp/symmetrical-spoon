package client

import "context"

type Client interface {
	GetGeoLocationInfo(context.Context, *GetGeoLocationInfoRequest) (*GetGeoLocationInfoResponse, error)
}

type GetGeoLocationInfoRequest struct {
	Ip string
}

type GetGeoLocationInfoResponse struct {
	City    string `json:"cityName"`
	Country string `json:"countryName"`
}

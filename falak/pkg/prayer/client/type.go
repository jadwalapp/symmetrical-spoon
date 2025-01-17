package client

import (
	"context"
)

type PrayersWithTime struct {
	Fajar   string `json:"Fajr"`
	Sunrise string `json:"Sunrise"`
	Duhar   string `json:"Dhuhr"`
	Asar    string `json:"Asr"`
	Magrib  string `json:"Maghrib"`
	Isha    string `json:"Isha"`
}

type GetPrayertimeInfoResponseData struct {
	Timings PrayersWithTime `json:"timings"`
}

type GetPrayertimeInfoResponse struct {
	Data GetPrayertimeInfoResponseData `json:"data"`
}

type GetPrayertimeInfoRequest struct {
	Date    string `json:"date"`
	City    string `json:"city"`
	Country string `json:"country"`
}

type Client interface {
	GetPrayertimeInfo(context.Context, *GetPrayertimeInfoRequest) (*GetPrayertimeInfoResponse, error)
}

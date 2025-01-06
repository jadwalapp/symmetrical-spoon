package client

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
)

type client struct {
	cli httpclient.HTTPClient
}

func (a *client) GetPrayertimeInfo(ctx context.Context, r *GetPrayertimeInfoRequest) (*GetPrayertimeInfoResponse, error) {
	encodedCity := url.QueryEscape(r.City)
	encodedCountry := url.QueryEscape(r.Country)
	url := fmt.Sprintf("https://api.aladhan.com/v1/timingsByCity?city=%s&country=%s&date=%s", encodedCity, encodedCountry, r.Date)

	resp, err := a.cli.Get(url, nil, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API request failed with status: %s", resp.Status)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var response GetPrayertimeInfoResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, fmt.Errorf("error unmarshalling JSON: %v", err)
	}

	return &response, nil
}

func NewClient(cli httpclient.HTTPClient) Client {
	return &client{
		cli: cli,
	}
}

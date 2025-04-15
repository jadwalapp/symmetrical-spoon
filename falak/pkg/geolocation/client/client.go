package client

import (
	"context"
	"encoding/json"
	"fmt"
	"io"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
)

type client struct {
	cli     httpclient.HTTPClient
	baseUrl string
}

func (c *client) GetGeoLocationInfo(ctx context.Context, r *GetGeoLocationInfoRequest) (*GetGeoLocationInfoResponse, error) {
	resp, err := c.cli.Get(fmt.Sprintf("%s/api/json/%s", c.baseUrl, r.Ip), nil, nil)
	if err != nil {
		return nil, fmt.Errorf("error fetching location: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("error reading response body: %v", err)
	}

	var location GetGeoLocationInfoResponse
	if err := json.Unmarshal(body, &location); err != nil {
		return nil, fmt.Errorf("error unmarshalling geolocation data: %v", err)
	}

	return &location, nil
}

func NewClient(cli httpclient.HTTPClient, baseUrl string) Client {
	return &client{
		cli:     cli,
		baseUrl: baseUrl,
	}
}

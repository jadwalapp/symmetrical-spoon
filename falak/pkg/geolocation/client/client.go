package client

import (
	"context"
	"encoding/json"
	"fmt" // Import your custom client package
	"io"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
)


type client struct {
	cli httpclient.HTTPClient
}

// GetGeoLocation fetches the location data using your custom HTTP client
func (c *client) GetGeoLocationInfo(ctx context.Context, r *GetGeoLocationInfoRequest) (*GetGeoLocationInfoResponse, error) {
	// Send the request using the custom client
	resp, err := c.cli.Get(fmt.Sprintf("http://ip-api.com/json/%s", "ip"), nil, nil)
	if err != nil {
		return nil, fmt.Errorf("error fetching location: %v", err)
	}
	defer resp.Body.Close()

	// Read the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("error reading response body: %v", err)
	}

	// Unmarshal the JSON response
	var location GetGeoLocationInfoResponse
	if err := json.Unmarshal(body, &location); err != nil {
		return nil, fmt.Errorf("error unmarshalling geolocation data: %v", err)
	}

	return &location, nil
}


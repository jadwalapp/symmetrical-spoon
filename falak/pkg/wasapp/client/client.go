package wasappclient

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
	"github.com/rs/zerolog/log"
)

type client struct {
	cli     httpclient.HTTPClient
	baseUrl string
}

func (c *client) Initialize(ctx context.Context, r *InitializeRequest) (*InitializeResponse, error) {
	url := fmt.Sprintf("%s/wasapp/initialize", c.baseUrl)
	resp, err := c.cli.Post(url, r, nil)
	if err != nil {
		log.Err(err).Msg("failed to initialize in wasapp")
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		log.Error().Int("status_code", resp.StatusCode).Msg("unexpected status code received after calling wasapp initialize")
		return nil, fmt.Errorf("failed to initialize in wasapp due to unexpected status code: %d", resp.StatusCode)
	}

	bodyDecoder := json.NewDecoder(resp.Body)
	var initializeResponse InitializeResponse
	if err := bodyDecoder.Decode(&initializeResponse); err != nil {
		log.Err(err).Msg("failed to decode wasapp intialize response")
		return nil, err
	}

	return &initializeResponse, nil
}

func (c *client) GetStatus(ctx context.Context, r *GetStatusRequest) (*GetStatusResponse, error) {
	url := fmt.Sprintf("%s/wasapp/status/%s", c.baseUrl, r.CustomerId)
	resp, err := c.cli.Post(url, r, nil)
	if err != nil {
		log.Err(err).Msg("failed to initialize in wasapp")
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		log.Error().Int("status_code", resp.StatusCode).Msg("unexpected status code received after calling wasapp status")
		return nil, fmt.Errorf("failed to get status from wasapp due to unexpected status code: %d", resp.StatusCode)
	}

	bodyDecoder := json.NewDecoder(resp.Body)
	var getStatusResponse GetStatusResponse
	if err := bodyDecoder.Decode(&getStatusResponse); err != nil {
		log.Err(err).Msg("failed to decode wasapp status response")
		return nil, err
	}

	return &getStatusResponse, nil
}

func (c *client) Disconnect(ctx context.Context, r *DisconnectRequest) (*DisconnectResponse, error) {
	url := fmt.Sprintf("%s/wasapp/disconnect", c.baseUrl)
	resp, err := c.cli.Post(url, r, nil)
	if err != nil {
		log.Err(err).Msg("failed to disconnect from wasapp")
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		log.Error().Int("status_code", resp.StatusCode).Msg("unexpected status code received after calling wasapp disconnect")
		return nil, fmt.Errorf("failed to disconnect from wasapp due to unexpected status code: %d", resp.StatusCode)
	}

	return &DisconnectResponse{}, nil
}

func NewClient(cli httpclient.HTTPClient, baseUrl string) Client {
	return &client{
		cli:     cli,
		baseUrl: baseUrl,
	}
}

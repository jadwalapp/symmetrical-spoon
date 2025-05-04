package client

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

func (c *client) GetTokenInfo(ctx context.Context, r *TokenInfoRequest) (*TokenInfoResponse, error) {
	url := fmt.Sprintf("%s/oauth2/v3/tokeninfo?id_token=%s", c.baseUrl, r.IdToken)

	resp, err := c.cli.Get(url, nil, nil)
	if err != nil {
		log.Err(err).Msg("failed to get token info - network or HTTP issue")
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		log.Error().Int("status_code", resp.StatusCode).Msg("unexpected status code received when fetching token info")
		return nil, fmt.Errorf("failed to get token info due to unexpected status code: %d", resp.StatusCode)
	}

	bodyDecoder := json.NewDecoder(resp.Body)
	var tokenInfoResp TokenInfoResponse
	if err := bodyDecoder.Decode(&tokenInfoResp); err != nil {
		log.Err(err).Msg("failed to decode token info response")
		return nil, err
	}

	return &tokenInfoResp, nil
}

func NewClient(cli httpclient.HTTPClient, baseUrl string) Client {
	return &client{
		cli:     cli,
		baseUrl: baseUrl,
	}
}

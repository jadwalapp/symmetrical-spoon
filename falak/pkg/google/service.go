package googlesvc

import (
	"context"
	"errors"

	googleClient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google/client"
	"github.com/rs/zerolog/log"
)

var (
	ErrInvalidToken = errors.New("invalid token")
)

type service struct {
	googleOAuthClientId string
	googleClient        googleClient.Client
}

func (s *service) GetUserInfoByToken(ctx context.Context, idToken string) (*googleClient.TokenInfoResponse, error) {
	tokenInfoResp, err := s.googleClient.GetTokenInfo(ctx, &googleClient.TokenInfoRequest{
		IdToken: idToken,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed to get token info")
		return nil, err
	}
	if tokenInfoResp.Aud != s.googleOAuthClientId {
		log.Ctx(ctx).Error().Msg("invalid audience, which means invalid token")
		return nil, ErrInvalidToken
	}

	return tokenInfoResp, nil
}

func NewService(googleOAuthClientId string, googleClient googleClient.Client) GoogleSvc {
	return &service{
		googleOAuthClientId: googleOAuthClientId,
		googleClient:        googleClient,
	}
}

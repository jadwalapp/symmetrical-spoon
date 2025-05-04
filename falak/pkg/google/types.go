package googlesvc

import (
	"context"

	googleClient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google/client"
)

type GoogleSvc interface {
	GetUserInfoByToken(ctx context.Context, token string) (*googleClient.TokenInfoResponse, error)
}

package auth

import (
	"errors"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
)

func (s *service) generateTokenWithHash() (uuid.UUID, string, error) {
	token, err := uuid.NewRandom()
	if err != nil {
		return uuid.UUID{}, "", errors.Join(err, errors.New("failed to generate a random uuid"))
	}

	hashedToken := util.HashStringToBase64SHA256(token.String())

	return token, hashedToken, nil
}

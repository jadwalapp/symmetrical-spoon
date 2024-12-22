package tokens

import (
	"crypto/rsa"
	"errors"
	"time"

	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
)

var (
	ErrInvalidIssuer = errors.New("invalid issuer")
)

const (
	tokenValidity = time.Hour * 24 * 7 // 7 days
	issuer        = "jadwal"
)

type tokens struct {
	PublicKey  *rsa.PublicKey
	PrivateKey *rsa.PrivateKey
}

func (t tokens) NewToken(customerId uuid.UUID, aud Audience) (string, error) {
	expiresAt := time.Now().UTC().Add(tokenValidity)
	claims := TokenClaims{
		Payload{
			CustomerId: customerId,
		},
		jwt.StandardClaims{
			Audience:  string(aud),
			ExpiresAt: expiresAt.Unix(),
			Issuer:    issuer,
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)

	signedToken, err := token.SignedString(t.PrivateKey)
	if err != nil {
		return "", err
	}

	return signedToken, nil
}

func (t tokens) ParseToken(token string) (*TokenClaims, error) {
	claims := TokenClaims{}
	_, err := jwt.ParseWithClaims(token, &claims, func(token *jwt.Token) (interface{}, error) {
		err := token.Claims.Valid()
		if err != nil {
			return nil, err
		}

		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, jwt.ErrSignatureInvalid
		}

		return t.PublicKey, nil
	})
	if err != nil {
		return nil, err
	}

	if claims.Issuer != issuer {
		return nil, ErrInvalidIssuer
	}

	return &claims, nil
}

func NewTokens(publicKey *rsa.PublicKey, privateKey *rsa.PrivateKey) Tokens {
	return &tokens{
		PublicKey:  publicKey,
		PrivateKey: privateKey,
	}
}

package tokens

import (
	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
)

type Payload struct {
	CustomerId uuid.UUID `json:"customer_id"`
}

type TokenClaims struct {
	Payload Payload `json:"payload"`
	jwt.StandardClaims
}

type Tokens interface {
	NewToken(customerId uuid.UUID, aud Audience) (string, error)
	ParseToken(token string) (*TokenClaims, error)
}

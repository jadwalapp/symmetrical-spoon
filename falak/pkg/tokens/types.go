package tokens

import (
	"github.com/golang-jwt/jwt"
)

type Payload struct {
	CustomerId string `json:"customer_id"`
	Email      string `json:"email"`
}

type TokenClaims struct {
	Payload Payload `json:"payload"`
	jwt.StandardClaims
}

type Tokens interface {
	NewToken(customerId, email string, aud Audience) (*string, error)
	ParseToken(token string) (*TokenClaims, error)
}
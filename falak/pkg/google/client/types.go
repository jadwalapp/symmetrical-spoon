package client

import "context"

type TokenInfoRequest struct {
	AccessToken string `json:"access_token"`
}

type TokenInfoResponse struct {
	Azp           string `json:"azp"`
	Aud           string `json:"aud"`
	Sub           string `json:"sub"`
	Scope         string `json:"scope"`
	Exp           string `json:"exp"`
	ExpiresIn     string `json:"expires_in"`
	Email         string `json:"email"`
	EmailVerified string `json:"email_verified"`
	AccessType    string `json:"access_type"`
}

type UserInfoRequest struct {
	AccessToken string `json:"access_token"`
}

type UserInfoResponse struct {
	Sub           string `json:"sub"`
	Name          string `json:"name"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
	Picture       string `json:"picture"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Locale        string `json:"locale"`
}

type Client interface {
	GetTokenInfo(context.Context, *TokenInfoRequest) (*TokenInfoResponse, error)
	GetUserInfo(context.Context, *UserInfoRequest) (*UserInfoResponse, error)
}

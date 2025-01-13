package client

import "context"

type CreateUserRequest struct {
	Username string
	Email    string
	Password string
}

type CreateUserResponse struct {
}

type Client interface {
	CreateUser(context.Context, *CreateUserRequest) (*CreateUserResponse, error)
}

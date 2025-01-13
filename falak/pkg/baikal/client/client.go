package client

import (
	"context"
	"fmt"
	"io"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
)

type client struct {
	cli     httpclient.HTTPClient
	baseUrl string
}

func (c *client) CreateUser(ctx context.Context, r *CreateUserRequest) (*CreateUserResponse, error) {
	url := fmt.Sprintf("%s/admin/?/users/new/1/", c.baseUrl)
	headers := map[string]string{
		// TODO: make this set in the struct after calling a login function perhaps :D
		"Cookie": "PHPSESSID=a7a156e35ea701b98313949ccee926cc",
	}

	getResp, err := c.cli.Get(url, headers, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get form of create user: %v", err)
	}

	bodyBytes, err := io.ReadAll(getResp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	bodyString := string(bodyBytes)
	csrfToken := extractCSRFToken(bodyString)

	form := map[string]string{
		"Baikal_Model_User::submitted": "1",
		"refreshed":                    "0",
		"CSRF_TOKEN":                   csrfToken,
		"data[username]":               r.Username,
		"witness[username]":            "1",
		"data[displayname]":            r.Username,
		"witness[displayname]":         "1",
		"data[email]":                  r.Email,
		"witness[email]":               "1",
		"data[password]":               r.Password,
		"witness[password]":            "1",
		"data[passwordconfirm]":        r.Password,
		"witness[passwordconfirm]":     "1",
	}

	resp, err := c.cli.PostFormData(url, form, headers)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %v", err)
	}

	fmt.Printf("resp of post: %v", resp)

	return &CreateUserResponse{}, nil
}

func NewClient(cli httpclient.HTTPClient, baseUrl string) Client {
	return &client{
		cli:     cli,
		baseUrl: baseUrl,
	}
}

package main

import (
	"context"
	"fmt"
	"net/http"

	"github.com/google/uuid"
	baikalclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/baikal/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
	"github.com/rs/zerolog/log"
)

func main() {
	baikalHost := ""
	baikalPhpSessionID := ""

	// ======== BAIKAL CLIENT ========
	cli := httpclient.NewClient(&http.Client{})
	baikalCli := baikalclient.NewClient(cli, baikalHost, baikalPhpSessionID)
	// ======== BAIKAL CLIENT ========

	randomPassword := uuid.New()
	fmt.Println(randomPassword.String())

	_, err := baikalCli.CreateUser(context.Background(), &baikalclient.CreateUserRequest{
		Username: "test2@username.com",
		Email:    "test2@username.com",
		Password: randomPassword.String(),
	})
	if err != nil {
		log.Fatal().Err(err).Msgf("❌ failed to run CreateUser")
	}
}

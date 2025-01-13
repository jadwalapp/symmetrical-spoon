package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/baikal/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
)

func main() {
	cli := httpclient.NewClient(&http.Client{})
	baikalCli := client.NewClient(cli, "http://localhost:3322")

	resp, err := baikalCli.CreateUser(context.Background(), &client.CreateUserRequest{
		Username: "test user 2",
		Email:    "testuser2@baikal.jadwal.app",
		Password: "12345678",
	})
	if err != nil {
		log.Fatalf("failed to create user: %v", err)
	}

	fmt.Printf("resp: %v", resp)
}

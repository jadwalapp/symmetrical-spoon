package main

import (
	"context"
	"database/sql"
	"net/http"
	"strings"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/google/uuid"
	baikalclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/baikal/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog/log"

	_ "github.com/jackc/pgx/v5/stdlib"
)

const dbDriverName = "pgx"

func main() {
	config, err := util.LoadFalakConfig(".")
	if err != nil {
		log.Fatal().Msgf("cannot load config: %v", err)
	}

	// ======== DATABASE ========
	dbSource := util.CreateDbSource(
		config.DBUser,
		config.DBPassword,
		config.DBHost,
		config.DBPort,
		config.DBName,
		config.DBSSLMode,
	)
	dbConn, err := sql.Open(dbDriverName, dbSource)
	if err != nil {
		log.Fatal().Msgf("cannot connect to postgres database: %v", err)
	}

	dbDriver, err := postgres.WithInstance(dbConn, &postgres.Config{})
	if err != nil {
		log.Fatal().Msgf("cannot create postgres db driver: %v", err)
	}

	iofsMig, err := iofs.New(store.MigrationsFS, "migrations")
	if err != nil {
		log.Fatal().Msgf("cannot create iofs: %v", err)
	}

	migStore, err := migrate.NewWithInstance(
		"iofs",
		iofsMig,
		dbDriverName,
		dbDriver,
	)
	if err != nil {
		log.Fatal().Msgf("cannot create store migration instance: %v", err)
	}

	err = migStore.Up()
	if err != nil && err != migrate.ErrNoChange {
		log.Fatal().Msgf("cannot run store migrations up: %v", err)
	}

	dbStore := store.New(dbConn)
	// ======== DATABASE ========

	// ======== BAIKAL CLIENT ========
	cli := httpclient.NewClient(&http.Client{})
	baikalCli := baikalclient.NewClient(cli, config.BaikalHost, config.BaikalPhpSessionID)
	// ======== BAIKAL CLIENT ========

	// query you need to make the list
	customers, err := dbStore.ListCustomerWithoutCaldavAccount(context.Background())
	if err != nil {
		log.Fatal().Msgf("failed to run ListCustomerWithoutCaldavAccount: %v", err)
	}

	failedRequestsCustomersId := []string{}
	for _, customer := range customers {
		_, err := baikalCli.CreateUser(context.Background(), &baikalclient.CreateUserRequest{})
		if err != nil {
			log.Error().Msgf("❌ failed to run CreateCalDAVAccount: %v", err)
			failedRequestsCustomersId = append(failedRequestsCustomersId, customer.ID.String())
			continue
		}

		randomPassword := uuid.New().String()

		_, err = dbStore.CreateCalDAVAccount(context.Background(), store.CreateCalDAVAccountParams{
			CustomerID:    customer.ID,
			Email:         customer.Email,
			Username:      customer.Email,
			Password:      randomPassword,
			EncryptionKey: config.CalDAVPasswordEncryptionKey,
		})
		if err != nil {
			log.Error().Msgf("❌ failed to run CreateCalDAVAccount: %v", err)
			failedRequestsCustomersId = append(failedRequestsCustomersId, customer.ID.String())
			continue
		}

		log.Info().Str("user_id", customer.ID.String()).Msg("✅ Successfully created a CalDAV account")
	}

	if len(failedRequestsCustomersId) > 0 {
		log.Warn().Msgf("Failed requests for customer IDs: %s",
			strings.Join(failedRequestsCustomersId, ", "))
	} else {
		log.Info().Msg("🚀 All CalDAV accounts created successfully.")
	}
}

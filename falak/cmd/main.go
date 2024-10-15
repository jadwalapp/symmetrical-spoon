package main

import (
	"database/sql"
	"fmt"
	"net"
	"os"

	"github.com/bufbuild/protovalidate-go"
	"github.com/golang-migrate/migrate"
	"github.com/golang-migrate/migrate/database/postgres"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/auth"
	authpb "github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/auth/proto"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/emailer"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/interceptors"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/tokens"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	_ "github.com/golang-migrate/migrate/source/file"
	_ "github.com/jackc/pgx/v5/stdlib"
)

const dbDriverName = "pgx"

func main() {
	log.Logger = zerolog.New(os.Stderr).With().Timestamp().Logger()

	config, err := util.LoadGrpcConfig(".")
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

	migStore, err := migrate.NewWithDatabaseInstance(
		"file://pkg/store/migrations",
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

	// ======== TOKENS ========
	publicKey, err := tokens.ParseRSAPublicKey(config.JWTPublicKey)
	if err != nil {
		log.Fatal().Msgf("cannot parse public key: %v", err)
	}

	privateKey, err := tokens.ParseRSAPrivateKey(config.JWTPrivateKey)
	if err != nil {
		log.Fatal().Msgf("cannot parse private key: %v", err)
	}

	tokens := tokens.NewTokens(publicKey, privateKey)
	// ======== TOKENS ========

	// ======== API METADATA ========
	apiMetadata := apimetadata.NewApiMetadata()
	// ======== API METADATA ========

	// ======== EMAILER ========
	var emailerImpl emailer.Emailer
	switch config.EmailerName {
	case string(emailer.EmailerName_SMTP):
		emailerImpl = emailer.NewSmtpEmailer(config.SMTPHost, config.SMTPPort, config.SMTPUSername, config.SMTPPasword)
	case string(emailer.EmailerName_Stdout):
		emailerImpl = emailer.NewStdoutEmailer()
	}
	// ======== EMAILER ========

	// ======== TEMPLATES ========
	templates := template.NewTemplates(config.Domain)
	// ======== TEMPLATES ========

	// ======== SERVER ========
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%s", config.Port))
	if err != nil {
		log.Fatal().Msgf("failed to listen: %v", err)
	}
	log.Info().Msgf("listening on %s", lis.Addr())

	opts := []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(
			interceptors.LoggingInterceptor,
			interceptors.EnsureValidTokenInterceptor(tokens, apiMetadata),
			interceptors.LangInterceptor(apiMetadata),
		),
	}

	grpcServer := grpc.NewServer(opts...)
	reflection.Register(grpcServer)

	pv, err := protovalidate.New()
	if err != nil {
		log.Fatal().Msgf("cannot create proto validator: %v", err)
	}

	authServer := auth.NewService(*pv, *dbStore, tokens, emailerImpl, templates, apiMetadata)
	authpb.RegisterAuthServer(grpcServer, authServer)

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatal().Err(err).Msg("failed to server grpc server")
	}
	// ======== SERVER ========
}

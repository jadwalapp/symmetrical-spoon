package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"os"

	"connectrpc.com/connect"
	"connectrpc.com/grpcreflect"
	"github.com/bufbuild/protovalidate-go"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/auth"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/calendar"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/api/profile"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/apimetadata"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/emailer"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/email/template"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/auth/v1/authv1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/calendar/v1/calendarv1connect"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/profile/v1/profilev1connect"
	googlesvc "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google"
	googleclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/google/client"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/httpclient"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/interceptors"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/lokilogger"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/tokens"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/resendlabs/resend-go"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	_ "github.com/jackc/pgx/v5/stdlib"
)

const dbDriverName = "pgx"

func main() {
	config, err := util.LoadFalakConfig(".")
	if err != nil {
		log.Fatal().Msgf("cannot load config: %v", err)
	}

	// ======== LOKI CLIENT ========
	lokiHookConfig := lokilogger.LokiConfig{
		PushIntervalSeconds: int64(config.LokiPushIntervalSeconds),
		MaxBatchSize:        config.LokiMaxBatchSize,
		LokiEndpoint:        config.LokiEndpoint,
		ServiceName:         "falak",
	}
	lokiClient := lokilogger.NewLokiClient(&lokiHookConfig)
	// ======== LOKI CLIENT ========

	// ======== LOGGER ========
	multiLevelWriters := zerolog.MultiLevelWriter(os.Stdout, lokiClient)
	log.Logger = zerolog.New(multiLevelWriters).With().Timestamp().Logger()
	// ======== LOGGER ========

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

	// ======== RESEND ========
	resendCli := resend.NewClient(config.ResendApiKey)
	// ======== RESEND ========

	// ======== EMAILER ========
	var emailerImpl emailer.Emailer
	switch config.EmailerName {
	case string(emailer.EmailerName_SMTP):
		emailerImpl = emailer.NewSmtpEmailer(config.SMTPHost, config.SMTPPort, config.SMTPUSername, config.SMTPPasword)
	case string(emailer.EmailerName_Stdout):
		emailerImpl = emailer.NewStdoutEmailer()
	case string(emailer.EmailerName_Resend):
		emailerImpl = emailer.NewResendEmailer(*resendCli)
	}
	// ======== EMAILER ========

	// ======== TEMPLATES ========
	templates := template.NewTemplates(config.Domain)
	// ======== TEMPLATES ========

	// ======== GOOGLE CLIENT ========
	googleHttpCli := httpclient.NewClient(&http.Client{})
	googleCli := googleclient.NewClient(googleHttpCli, config.GoogleClientBaseUrl)
	// ======== GOOGLE CLIENT ========

	// ======== GOOGLE SVC ========
	googleSvc := googlesvc.NewService(config.GoogleOAuthClientId, googleCli)
	// ======== GOOGLE SVC ========

	// ======== PROTOVALIDATE ========
	pv, err := protovalidate.New()
	if err != nil {
		log.Fatal().Msgf("cannot create proto validator: %v", err)
	}
	// ======== PROTOVALIDATE ========

	// ======== INTERCEPTORS ========
	interceptorsForServer := connect.WithInterceptors(
		interceptors.LoggingInterceptor(lokiClient),
		interceptors.EnsureValidTokenInterceptor(tokens, apiMetadata),
		interceptors.LangInterceptor(apiMetadata),
	)
	// ======== INTERCEPTORS ========

	// ======== SERVER ========
	mux := http.NewServeMux()

	reflector := grpcreflect.NewStaticReflector(
		authv1connect.AuthServiceName,
		profilev1connect.ProfileServiceName,
		calendarv1connect.CalendarServiceName,
	)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	authServer := auth.NewService(*pv, *dbStore, tokens, emailerImpl, templates, apiMetadata, googleSvc)
	mux.Handle(authv1connect.NewAuthServiceHandler(authServer, interceptorsForServer))

	profileServer := profile.NewService(*pv, *dbStore, apiMetadata)
	mux.Handle(profilev1connect.NewProfileServiceHandler(profileServer, interceptorsForServer))

	calendarServer := calendar.NewService(*pv, *dbStore, apiMetadata)
	mux.Handle(calendarv1connect.NewCalendarServiceHandler(calendarServer, interceptorsForServer))

	addr := fmt.Sprintf("0.0.0.0:%s", config.Port)
	log.Info().Msgf("listening on %s", addr)

	err = http.ListenAndServe(
		addr,
		h2c.NewHandler(mux, &http2.Server{}),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to server grpc server")
	}
	// ======== SERVER ========
}
